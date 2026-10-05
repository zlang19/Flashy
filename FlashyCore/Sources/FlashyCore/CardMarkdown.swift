import Foundation

public enum ListMarker: Equatable, Sendable {
    case bullet
    case number(Int)
}

/// Block-level structure of a card side. Text in each block is still inline
/// markdown (bold, italic, `code`, links) for the UI to render.
public enum MarkdownBlock: Equatable, Sendable {
    case heading(level: Int, text: String)
    case paragraph(String)
    case listItem(marker: ListMarker, indent: Int, text: String)
    case quote(String)
    case code(String)
    case image(alt: String, source: String)
    case rule
}

public enum CardMarkdown {
    public static func blocks(from markdown: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        var paragraph: [String] = []
        var code: [String]?

        func flushParagraph() {
            guard !paragraph.isEmpty else { return }
            blocks += splitImages(paragraph.joined(separator: "\n")) { .paragraph($0) }
            paragraph = []
        }

        for line in markdown.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if var lines = code {
                if trimmed.hasPrefix("```") {
                    blocks.append(.code(lines.joined(separator: "\n")))
                    code = nil
                } else {
                    lines.append(line)
                    code = lines
                }
                continue
            }
            if trimmed.hasPrefix("```") {
                flushParagraph()
                code = []
            } else if trimmed.isEmpty {
                flushParagraph()
            } else if let heading = heading(trimmed) {
                flushParagraph()
                blocks.append(heading)
            } else if trimmed == "---" || trimmed == "***" || trimmed == "___" {
                flushParagraph()
                blocks.append(.rule)
            } else if let (marker, text) = listItem(trimmed) {
                flushParagraph()
                let indent = line.prefix { $0 == " " || $0 == "\t" }
                    .reduce(0) { $0 + ($1 == "\t" ? 4 : 1) } / 2
                blocks += splitImages(text) { .listItem(marker: marker, indent: indent, text: $0) }
            } else if trimmed.hasPrefix(">") {
                flushParagraph()
                let text = trimmed.dropFirst().trimmingCharacters(in: .whitespaces)
                if case let .quote(previous)? = blocks.last {
                    blocks[blocks.count - 1] = .quote(previous + "\n" + text)
                } else {
                    blocks.append(.quote(text))
                }
            } else {
                paragraph.append(trimmed)
            }
        }
        flushParagraph()
        if let lines = code { blocks.append(.code(lines.joined(separator: "\n"))) }
        return blocks
    }

    /// Every image source referenced in `markdown`, in order.
    public static func imageSources(in markdown: String) -> [String] {
        blocks(from: markdown).compactMap {
            if case let .image(_, source) = $0 { return source }
            return nil
        }
    }

    /// Resolves an image source against its card folder. Returns a repo-relative
    /// path, the URL unchanged for http(s) sources, or nil if it escapes the repo.
    public static func resolve(_ source: String, cardDirectory: String) -> String? {
        if source.hasPrefix("http://") || source.hasPrefix("https://") { return source }
        var parts = source.hasPrefix("/") ? [] : cardDirectory.split(separator: "/").map(String.init)
        for component in source.split(separator: "/") {
            switch component {
            case ".": continue
            case "..":
                guard !parts.isEmpty else { return nil }
                parts.removeLast()
            default:
                parts.append(String(component).removingPercentEncoding ?? String(component))
            }
        }
        return parts.isEmpty ? nil : parts.joined(separator: "/")
    }

    // MARK: Helpers

    private static func heading(_ line: String) -> MarkdownBlock? {
        let hashes = line.prefix { $0 == "#" }.count
        guard (1...6).contains(hashes), line.dropFirst(hashes).first == " " else { return nil }
        return .heading(level: hashes, text: line.dropFirst(hashes).trimmingCharacters(in: .whitespaces))
    }

    private static func listItem(_ line: String) -> (ListMarker, String)? {
        for bullet in ["- ", "* ", "+ "] where line.hasPrefix(bullet) {
            return (.bullet, String(line.dropFirst(2)))
        }
        let digits = line.prefix { $0.isNumber }
        guard !digits.isEmpty, let number = Int(digits) else { return nil }
        let rest = line.dropFirst(digits.count)
        guard let delimiter = rest.first, delimiter == "." || delimiter == ")", rest.dropFirst().first == " " else {
            return nil
        }
        return (.number(number), rest.dropFirst(2).trimmingCharacters(in: .whitespaces))
    }

    /// Splits `![alt](src)` occurrences out of `text` into image blocks; the text
    /// around them becomes blocks built by `makeText`.
    private static func splitImages(_ text: String, makeText: (String) -> MarkdownBlock) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        var rest = Substring(text)
        while let bang = rest.range(of: "![") {
            guard let closeAlt = rest[bang.upperBound...].range(of: "]("),
                  let closeSrc = rest[closeAlt.upperBound...].firstIndex(of: ")") else { break }
            let alt = String(rest[bang.upperBound..<closeAlt.lowerBound])
            let before = rest[..<bang.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
            if !before.isEmpty { blocks.append(makeText(before)) }
            blocks.append(.image(alt: alt, source: imageSource(rest[closeAlt.upperBound..<closeSrc])))
            rest = rest[rest.index(after: closeSrc)...]
        }
        let after = rest.trimmingCharacters(in: .whitespacesAndNewlines)
        if !after.isEmpty { blocks.append(makeText(after)) }
        return blocks
    }

    /// `<path> "title"` → `path`
    private static func imageSource(_ raw: Substring) -> String {
        var source = raw.trimmingCharacters(in: .whitespaces)
        if source.hasPrefix("<"), let close = source.firstIndex(of: ">") {
            return String(source[source.index(after: source.startIndex)..<close])
        }
        if let space = source.firstIndex(of: " ") { source = String(source[..<space]) }
        return source
    }
}
