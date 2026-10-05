import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol HTTPTransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

public struct URLSessionTransport: HTTPTransport {
    let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            session.dataTask(with: request) { data, response, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let http = response as? HTTPURLResponse {
                    continuation.resume(returning: (data ?? Data(), http))
                } else {
                    continuation.resume(throwing: GitHubError.malformedResponse)
                }
            }.resume()
        }
    }
}

public enum GitHubError: Error, Equatable, CustomStringConvertible {
    case http(status: Int, url: String)
    case rateLimited(resetsAt: Date?)
    case malformedResponse

    public var description: String {
        switch self {
        case let .http(status, url): return "GitHub returned \(status) for \(url)"
        case .rateLimited: return "GitHub rate limit reached; try again later"
        case .malformedResponse: return "Unexpected response from GitHub"
        }
    }
}

public struct GitHubRepo: Sendable {
    public var owner: String
    public var name: String
    public var branch: String

    public init(owner: String, name: String, branch: String) {
        self.owner = owner
        self.name = name
        self.branch = branch
    }

    public static let flashy = GitHubRepo(owner: "zlang19", name: "Flashy", branch: "main")
}

/// Unauthenticated, read-only access to a public repo. Conditional requests that
/// come back 304 don't count against GitHub's 60 requests/hour limit.
public struct GitHubClient: Sendable {
    public enum Head: Equatable, Sendable {
        case unchanged
        case changed(sha: String, etag: String?)
    }

    public let repo: GitHubRepo
    let transport: HTTPTransport

    public init(repo: GitHubRepo = .flashy, transport: HTTPTransport = URLSessionTransport()) {
        self.repo = repo
        self.transport = transport
    }

    /// The SHA of the branch head, or `.unchanged` if it still matches `etag`.
    public func head(etag: String?) async throws -> Head {
        var request = apiRequest("commits/\(repo.branch)")
        request.setValue("application/vnd.github.sha", forHTTPHeaderField: "Accept")
        if let etag { request.setValue(etag, forHTTPHeaderField: "If-None-Match") }
        let (data, response) = try await transport.send(request)
        if response.statusCode == 304 { return .unchanged }
        try check(response, for: request)
        guard let sha = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !sha.isEmpty else { throw GitHubError.malformedResponse }
        return .changed(sha: sha, etag: response.value(forHTTPHeaderField: "ETag"))
    }

    /// Every file (blob) in the repo at `commit`.
    public func files(at commit: String) async throws -> (files: [RemoteFile], truncated: Bool) {
        let request = apiRequest("git/trees/\(commit)?recursive=1")
        let (data, response) = try await transport.send(request)
        try check(response, for: request)
        struct Tree: Decodable {
            struct Entry: Decodable { let path: String; let type: String; let sha: String }
            let tree: [Entry]
            let truncated: Bool?
        }
        let tree = try JSONDecoder().decode(Tree.self, from: data)
        let files = tree.tree.filter { $0.type == "blob" }.map { RemoteFile(path: $0.path, sha: $0.sha) }
        return (files, tree.truncated ?? false)
    }

    public func contents(of path: String, at commit: String) async throws -> Data {
        let encoded = path.split(separator: "/")
            .map { $0.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed.subtracting(["/"])) ?? String($0) }
            .joined(separator: "/")
        let url = URL(string: "https://raw.githubusercontent.com/\(repo.owner)/\(repo.name)/\(commit)/\(encoded)")!
        let request = URLRequest(url: url)
        let (data, response) = try await transport.send(request)
        try check(response, for: request)
        return data
    }

    private func apiRequest(_ path: String) -> URLRequest {
        var request = URLRequest(url: URL(string: "https://api.github.com/repos/\(repo.owner)/\(repo.name)/\(path)")!)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Flashy-iOS", forHTTPHeaderField: "User-Agent")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        return request
    }

    private func check(_ response: HTTPURLResponse, for request: URLRequest) throws {
        guard !(200..<300).contains(response.statusCode) else { return }
        if [403, 429].contains(response.statusCode), response.value(forHTTPHeaderField: "X-RateLimit-Remaining") == "0" {
            let reset = response.value(forHTTPHeaderField: "X-RateLimit-Reset")
                .flatMap(TimeInterval.init)
                .map(Date.init(timeIntervalSince1970:))
            throw GitHubError.rateLimited(resetsAt: reset)
        }
        throw GitHubError.http(status: response.statusCode, url: request.url?.absoluteString ?? "")
    }
}
