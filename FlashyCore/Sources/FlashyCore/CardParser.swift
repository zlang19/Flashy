import Foundation

public struct ParsedCard: Equatable, Sendable {
    public var title: String?
    public var tags: [String]
    public var front: String
    public var back: String
}

public enum CardParseError: Error, Equatable, CustomStringConvertible {
    case unterminatedFrontmatter
    case invalidFrontmatterLine(line: Int, text: String)
    case missingSection(String)
    case emptySection(String)
    case duplicateSection(String)

    public var description: String {
        switch self {
        case .unterminatedFrontmatter:
            return "Frontmatter opened with --- but never closed"
        case let .invalidFrontmatterLine(line, text):
            return "Frontmatter line \(line) isn't `key: value`: \(text)"
        case let .missingSection(name):
            return "Missing `## \(name)` section"
        case let .emptySection(name):
            return "`## \(name)` section is empty"
        case let .duplicateSection(name):
            return "More than one `## \(name)` section"
        }
    }
}

/// Parses `flashcard.md`: optional YAML-ish frontmatter (`title`, `tags`), then
/// `## Front` and `## Back` sections. Anything before `## Front` is ignored.
public enum CardParser {
    public static func parse(_ text: String) throws -> ParsedCard {
        var lines = text.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")
        let frontmatter = try extractFrontmatter(&lines)

        var sections: [String: [String]] = [:]
        var currentSection: String?
        var inFence = false
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") { inFence.toggle() }
            if !inFence, let name = sectionName(trimmed) {
                guard sections[name] == nil else { throw CardParseError.duplicateSection(name) }
                sections[name] = []
                currentSection = name
                continue
            }
            if let section = currentSection { sections[section]!.append(line) }
        }

        func body(_ name: String) throws -> String {
            guard let lines = sections[name] else { throw CardParseError.missingSection(name) }
            let joined = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !joined.isEmpty else { throw CardParseError.emptySection(name) }
            return joined
        }

        let title = frontmatter["title"]?.scalar?.trimmingCharacters(in: .whitespaces)
        return ParsedCard(
            title: (title?.isEmpty ?? true) ? nil : title,
            tags: frontmatter["tags"]?.list ?? frontmatter["tags"]?.scalar.map { [$0] } ?? [],
            front: try body("Front"),
            back: try body("Back")
        )
    }

    private static func sectionName(_ trimmedLine: String) -> String? {
        guard trimmedLine.hasPrefix("## ") else { return nil }
        switch trimmedLine.dropFirst(3).trimmingCharacters(in: .whitespaces).lowercased() {
        case "front": return "Front"
        case "back": return "Back"
        default: return nil
        }
    }

    // MARK: Frontmatter

    enum Value: Equatable {
        case scalar(String)
        case list([String])

        var scalar: String? {
            if case let .scalar(s) = self { return s }
            return nil
        }

        var list: [String]? {
            if case let .list(l) = self { return l }
            return nil
        }
    }

    /// Strips the frontmatter block off `lines` and returns its keys. Supports
    /// `key: value`, `key: [a, b]`, and block lists of `- item` lines.
    static func extractFrontmatter(_ lines: inout [String]) throws -> [String: Value] {
        guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else { return [:] }
        guard let end = lines.dropFirst().firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "---" }) else {
            throw CardParseError.unterminatedFrontmatter
        }
        let block = lines[1..<end]
        lines.removeSubrange(0...end)

        var values: [String: Value] = [:]
        var listKey: String?
        for (offset, raw) in block.enumerated() {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") { continue }
            if line.hasPrefix("- "), let key = listKey {
                values[key] = .list((values[key]?.list ?? []) + [unquote(String(line.dropFirst(2)))])
                continue
            }
            guard let colon = line.firstIndex(of: ":") else {
                throw CardParseError.invalidFrontmatterLine(line: offset + 2, text: line)
            }
            let key = line[..<colon].trimmingCharacters(in: .whitespaces).lowercased()
            let value = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            if value.isEmpty {
                values[key] = .list([])
                listKey = key
            } else if value.hasPrefix("[") && value.hasSuffix("]") {
                let items = value.dropFirst().dropLast()
                    .split(separator: ",")
                    .map { unquote($0.trimmingCharacters(in: .whitespaces)) }
                    .filter { !$0.isEmpty }
                values[key] = .list(items)
                listKey = nil
            } else {
                values[key] = .scalar(unquote(value))
                listKey = nil
            }
        }
        return values
    }

    private static func unquote(_ s: String) -> String {
        let s = s.trimmingCharacters(in: .whitespaces)
        for quote in ["\"", "'"] where s.count >= 2 && s.hasPrefix(quote) && s.hasSuffix(quote) {
            return String(s.dropFirst().dropLast())
        }
        return s
    }
}
