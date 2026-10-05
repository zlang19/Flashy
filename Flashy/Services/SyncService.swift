import Foundation
import SwiftData
import FlashyCore

/// What the app remembers between syncs. Persisted as JSON in UserDefaults.
struct SyncState: Codable, Equatable {
    var etag: String?
    var commitSHA: String?
    var lastSynced: Date?
    var issues: [SyncIssue] = []
}

/// Pulls `flashcards/` from GitHub into the disk cache and SwiftData.
@MainActor
final class SyncService {
    private let client = GitHubClient()
    private let cache = CardCache.shared
    private static let maxConcurrentDownloads = 6

    func sync(context: ModelContext, from previous: SyncState, today: StudyDay) async throws -> SyncState {
        var state = previous
        // Only send the ETag once a full sync has finished, so an interrupted first
        // sync isn't mistaken for "nothing changed".
        let head = try await client.head(etag: previous.commitSHA == nil ? nil : previous.etag)
        guard case let .changed(sha, etag) = head, sha != previous.commitSHA else {
            if case let .changed(_, etag) = head { state.etag = etag }
            state.lastSynced = .now
            return state
        }

        let tree = try await client.files(at: sha)
        let sources = RepoLayout.cards(in: tree.files)
        var manifest = cache.loadManifest()
        let plan = SyncPlan(remote: sources.flatMap(\.files), local: manifest)

        for path in plan.toDelete {
            cache.remove(path)
            manifest[path] = nil
        }
        // A failed download leaves the manifest stale for that file, so the next
        // sync fetches it again.
        manifest.merge(try await download(plan.toDownload, at: sha)) { _, new in new }
        try cache.saveManifest(manifest)

        var issues = apply(sources, to: context, today: today)
        if tree.truncated {
            issues.insert(SyncIssue(path: RepoLayout.root, reason: "Repo too large for one GitHub tree listing; some cards may be missing", skipped: false), at: 0)
        }
        try context.save()

        state.commitSHA = sha
        state.etag = etag
        state.lastSynced = .now
        state.issues = issues
        return state
    }

    /// Downloads and caches `files`, returning path → SHA for each one written.
    private func download(_ files: [RemoteFile], at commit: String) async throws -> [String: String] {
        let client = self.client
        let cache = self.cache
        var remaining = files.makeIterator()
        return try await withThrowingTaskGroup(of: RemoteFile.self, returning: [String: String].self) { group in
            func fetch(_ file: RemoteFile) {
                group.addTask {
                    try cache.write(try await client.contents(of: file.path, at: commit), to: file.path)
                    return file
                }
            }
            for _ in 0..<Self.maxConcurrentDownloads {
                guard let file = remaining.next() else { break }
                fetch(file)
            }
            var written: [String: String] = [:]
            while let file = try await group.next() {
                written[file.path] = file.sha
                if let next = remaining.next() { fetch(next) }
            }
            return written
        }
    }

    /// Upserts card records from the cached files and returns any problems found.
    private func apply(_ sources: [CardSource], to context: ModelContext, today: StudyDay) -> [SyncIssue] {
        let existing = (try? context.fetch(FetchDescriptor<CardRecord>())) ?? []
        let byID = Dictionary(existing.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var issues: [SyncIssue] = []

        for source in sources {
            guard let data = cache.read(source.markdownPath), let text = String(data: data, encoding: .utf8) else {
                issues.append(SyncIssue(path: source.markdownPath, reason: "Couldn't read file", skipped: true))
                deactivate(byID[source.id])
                continue
            }
            let parsed: ParsedCard
            do {
                parsed = try CardParser.parse(text)
            } catch {
                issues.append(SyncIssue(path: source.markdownPath, reason: "\(error)", skipped: true))
                deactivate(byID[source.id])
                continue
            }
            issues += imageIssues(parsed, source: source)

            let card: CardRecord
            if let found = byID[source.id] {
                card = found
            } else {
                card = CardRecord(id: source.id, newSince: today)
                context.insert(card)
            }
            if card.contentHash != source.contentHash {
                if !card.contentHash.isEmpty {
                    // Edited upstream: start the card over.
                    card.schedule = .new
                    card.newSinceDayIndex = today.index
                }
                card.contentHash = source.contentHash
            }
            card.title = parsed.title ?? Naming.prettify(source.folderName)
            card.categoryPath = source.categoryPath
            card.tags = parsed.tags
            card.front = parsed.front
            card.back = parsed.back
            card.isActive = true
        }

        let present = Set(sources.map(\.id))
        for card in existing where !present.contains(card.id) {
            card.isActive = false
        }
        return issues
    }

    private func deactivate(_ card: CardRecord?) {
        if let card { card.isActive = false }
    }

    private func imageIssues(_ card: ParsedCard, source: CardSource) -> [SyncIssue] {
        let files = Set(source.files.map(\.path))
        return CardMarkdown.imageSources(in: card.front + "\n\n" + card.back).compactMap { image in
            guard let resolved = CardMarkdown.resolve(image, cardDirectory: source.directory) else {
                return SyncIssue(path: source.markdownPath, reason: "Image path leaves the repo: \(image)", skipped: false)
            }
            if resolved.hasPrefix("http") || files.contains(resolved) { return nil }
            return SyncIssue(path: source.markdownPath, reason: "Image not found in card folder: \(image)", skipped: false)
        }
    }
}
