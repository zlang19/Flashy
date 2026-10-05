import Foundation

/// A file in the repo at a particular git blob SHA.
public struct RemoteFile: Hashable, Codable, Sendable {
    public var path: String
    public var sha: String

    public init(path: String, sha: String) {
        self.path = path
        self.sha = sha
    }
}

/// A card as found in the repo tree, before its markdown is parsed.
public struct CardSource: Equatable, Sendable {
    /// The card folder relative to `flashcards/`, e.g. `bio/cells/mitosis`. This is
    /// the card's identity.
    public var id: String
    /// Folder names between `flashcards/` and the card folder. Empty means uncategorized.
    public var categoryPath: [String]
    /// Every file inside the card folder, including `flashcard.md`.
    public var files: [RemoteFile]
    /// Changes whenever any file in the card changes. A change resets the schedule.
    public var contentHash: String

    public var folderName: String { String(id.split(separator: "/").last ?? "") }
    public var directory: String { RepoLayout.root + "/" + id }
    public var markdownPath: String { directory + "/" + RepoLayout.cardFileName }
}

public enum RepoLayout {
    public static let root = "flashcards"
    public static let cardFileName = "flashcard.md"

    /// Finds the cards in a repo tree. A folder directly containing `flashcard.md`
    /// is a card and owns everything beneath it. Other folders are categories.
    /// Files outside any card, such as `flashcards/README.md`, are ignored.
    public static func cards(in files: [RemoteFile]) -> [CardSource] {
        let prefix = root + "/"
        let candidates = files.filter { $0.path.hasPrefix(prefix) }

        var cardDirs = Set<String>()
        for file in candidates {
            var components = file.path.dropFirst(prefix.count).split(separator: "/")
            guard components.last.map(String.init) == cardFileName, components.count >= 2 else { continue }
            components.removeLast()
            cardDirs.insert(components.joined(separator: "/"))
        }
        // A card inside another card belongs to the outer one.
        cardDirs = cardDirs.filter { dir in
            !ancestors(of: dir).contains(where: cardDirs.contains)
        }

        var filesByCard: [String: [RemoteFile]] = [:]
        for file in candidates {
            let relative = String(file.path.dropFirst(prefix.count))
            if let owner = ancestors(of: relative).first(where: cardDirs.contains) {
                filesByCard[owner, default: []].append(file)
            }
        }

        return cardDirs.sorted().map { id in
            let files = filesByCard[id, default: []].sorted { $0.path < $1.path }
            return CardSource(
                id: id,
                categoryPath: id.split(separator: "/").dropLast().map(String.init),
                files: files,
                contentHash: fingerprint(files)
            )
        }
    }

    /// Proper ancestor folders of `path`, nearest last: `a/b/c` → `a`, `a/b`.
    private static func ancestors(of path: String) -> [String] {
        let parts = path.split(separator: "/")
        guard parts.count > 1 else { return [] }
        return (1..<parts.count).map { parts.prefix($0).joined(separator: "/") }
    }

    private static func fingerprint(_ files: [RemoteFile]) -> String {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in files.map({ "\($0.path):\($0.sha)\n" }).joined().utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01b3
        }
        return String(hash, radix: 16)
    }
}

/// Display names derived from folder names.
public enum Naming {
    /// `organic_chemistry` → `Organic Chemistry`
    public static func prettify(_ folderName: String) -> String {
        folderName
            .split(whereSeparator: { $0 == "_" || $0 == "-" || $0 == " " })
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }

    public static func breadcrumb(_ categoryPath: [String]) -> String {
        categoryPath.isEmpty ? "Uncategorized" : categoryPath.map(prettify).joined(separator: " › ")
    }
}
