import Foundation

/// Card files mirrored from the repo onto disk, at their repo paths under
/// Application Support/Cards, plus a manifest of each file's blob SHA.
struct CardCache {
    static let shared = CardCache()

    let root: URL
    private var manifestURL: URL { root.appendingPathComponent("manifest.json") }

    init(root: URL = URL.applicationSupportDirectory.appendingPathComponent("Cards", isDirectory: true)) {
        self.root = root
    }

    func url(for repoPath: String) -> URL {
        root.appendingPathComponent(repoPath)
    }

    func read(_ repoPath: String) -> Data? {
        try? Data(contentsOf: url(for: repoPath))
    }

    func write(_ data: Data, to repoPath: String) throws {
        let url = url(for: repoPath)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }

    func remove(_ repoPath: String) {
        try? FileManager.default.removeItem(at: url(for: repoPath))
    }

    /// path → blob SHA for every file on disk.
    func loadManifest() -> [String: String] {
        guard let data = try? Data(contentsOf: manifestURL) else { return [:] }
        return (try? JSONDecoder().decode([String: String].self, from: data)) ?? [:]
    }

    func saveManifest(_ manifest: [String: String]) throws {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try JSONEncoder().encode(manifest).write(to: manifestURL, options: .atomic)
    }
}
