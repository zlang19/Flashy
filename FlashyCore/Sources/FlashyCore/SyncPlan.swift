import Foundation

/// The file operations needed to bring the local card cache in line with the repo.
public struct SyncPlan: Equatable, Sendable {
    public var toDownload: [RemoteFile]
    public var toDelete: [String]

    /// - Parameters:
    ///   - remote: every card file in the repo at the target commit.
    ///   - local: the cache manifest, path → blob SHA.
    public init(remote: [RemoteFile], local: [String: String]) {
        toDownload = remote
            .filter { local[$0.path] != $0.sha }
            .sorted { $0.path < $1.path }
        let remotePaths = Set(remote.map(\.path))
        toDelete = local.keys.filter { !remotePaths.contains($0) }.sorted()
    }

    public var isEmpty: Bool { toDownload.isEmpty && toDelete.isEmpty }
}

public struct SyncIssue: Hashable, Codable, Sendable {
    public var path: String
    public var reason: String
    /// A skipped card isn't reviewable; a warning (e.g. a broken image) still is.
    public var skipped: Bool

    public init(path: String, reason: String, skipped: Bool) {
        self.path = path
        self.reason = reason
        self.skipped = skipped
    }
}
