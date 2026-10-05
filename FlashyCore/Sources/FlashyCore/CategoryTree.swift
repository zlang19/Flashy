import Foundation

/// The folder hierarchy of cards, for browsing. The root node has an empty path;
/// its direct cards are the uncategorized ones.
public struct CategoryNode: Identifiable, Equatable, Sendable {
    public var path: [String]
    public var children: [CategoryNode]
    /// Cards directly in this folder.
    public var cardIDs: [String]

    public var id: String { path.joined(separator: "/") }
    public var name: String { path.last.map(Naming.prettify) ?? "All Cards" }

    /// Cards in this folder and every folder beneath it.
    public var allCardIDs: [String] {
        cardIDs + children.flatMap(\.allCardIDs)
    }

    public static func build(_ cards: [(id: String, categoryPath: [String])]) -> CategoryNode {
        build(path: [], cards: cards)
    }

    private static func build(path: [String], cards: [(id: String, categoryPath: [String])]) -> CategoryNode {
        let depth = path.count
        let direct = cards.filter { $0.categoryPath.count == depth }.map(\.id).sorted()
        let deeper = Dictionary(grouping: cards.filter { $0.categoryPath.count > depth }) { $0.categoryPath[depth] }
        let children = deeper.keys.sorted().map { build(path: path + [$0], cards: deeper[$0]!) }
        return CategoryNode(path: path, children: children, cardIDs: direct)
    }

    public func node(at path: [String]) -> CategoryNode? {
        guard let next = path.first else { return self }
        return children.first { $0.path.last == next }?.node(at: Array(path.dropFirst()))
    }
}
