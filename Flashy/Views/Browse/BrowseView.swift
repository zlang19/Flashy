import SwiftData
import SwiftUI
import FlashyCore

/// Free review: browse the folder tree or search, then practice. Nothing here
/// touches the schedule.
struct BrowseView: View {
    @Environment(AppModel.self) private var model
    @Query(filter: #Predicate<CardRecord> { $0.isActive }, sort: \CardRecord.title) private var cards: [CardRecord]
    @State private var query = ""

    var body: some View {
        NavigationStack {
            Group {
                if query.isEmpty {
                    FolderView(node: tree, cardsByID: cardsByID)
                } else {
                    searchResults
                }
            }
            .searchable(text: $query, prompt: "Search cards")
        }
    }

    private var tree: CategoryNode {
        CategoryNode.build(cards.map { (id: $0.id, categoryPath: $0.categoryPath) })
    }

    private var cardsByID: [String: CardRecord] {
        Dictionary(cards.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    private var searchResults: some View {
        let matches = cards.filter { card in
            [card.title, card.front, card.back, card.breadcrumb, card.tags.joined(separator: " ")]
                .contains { $0.localizedCaseInsensitiveContains(query) }
        }
        return List {
            if matches.isEmpty {
                Text("No cards match “\(query)”.")
                    .foregroundStyle(Theme.textDim)
                    .listRowBackground(Theme.surface)
            }
            ForEach(matches) { card in
                NavigationLink {
                    CardDetailView(card: card)
                } label: {
                    CardRow(card: card, today: model.today)
                }
                .listRowBackground(Theme.surface)
            }
        }
        .themedList()
        .navigationTitle("Search")
    }
}

struct FolderView: View {
    @Environment(AppModel.self) private var model
    let node: CategoryNode
    let cardsByID: [String: CardRecord]

    var body: some View {
        let allCards = node.allCardIDs.compactMap { cardsByID[$0] }
        List {
            if !allCards.isEmpty {
                Section {
                    NavigationLink {
                        PracticeView(cards: allCards.shuffled())
                    } label: {
                        Label("Practice all \(allCards.count)", systemImage: "play.fill")
                            .font(Theme.mono(15, .bold))
                            .foregroundStyle(Theme.sun)
                    }
                    .listRowBackground(Theme.surface)
                }
            }
            if !node.children.isEmpty {
                Section {
                    ForEach(node.children) { child in
                        NavigationLink {
                            FolderView(node: child, cardsByID: cardsByID)
                        } label: {
                            HStack {
                                Image(systemName: "folder.fill").foregroundStyle(Theme.violet)
                                Text(child.name).foregroundStyle(Theme.text)
                                Spacer()
                                Text("\(child.allCardIDs.count)")
                                    .font(Theme.mono(13))
                                    .foregroundStyle(Theme.textDim)
                            }
                        }
                        .listRowBackground(Theme.surface)
                    }
                } header: {
                    SectionTitle("Folders")
                }
            }
            if !node.cardIDs.isEmpty {
                Section {
                    ForEach(node.cardIDs.compactMap { cardsByID[$0] }) { card in
                        NavigationLink {
                            CardDetailView(card: card)
                        } label: {
                            CardRow(card: card, today: model.today)
                        }
                        .listRowBackground(Theme.surface)
                    }
                } header: {
                    SectionTitle(node.path.isEmpty ? "Uncategorized" : "Cards")
                }
            }
            if allCards.isEmpty {
                Text("No cards yet.")
                    .foregroundStyle(Theme.textDim)
                    .listRowBackground(Theme.surface)
            }
        }
        .themedList()
        .navigationTitle(node.name)
    }
}

/// One card, flipped by tapping. Practice only.
struct CardDetailView: View {
    let card: CardRecord
    @State private var revealed = false

    var body: some View {
        VStack(spacing: 16) {
            FlipCardView(card: card, revealed: revealed)
                .onTapGesture {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { revealed.toggle() }
                }
            if !card.tags.isEmpty {
                Text(card.tags.map { "#\($0)" }.joined(separator: "  "))
                    .font(Theme.mono(12))
                    .foregroundStyle(Theme.violet)
            }
            Text("TAP CARD TO FLIP")
                .font(Theme.mono(11))
                .tracking(2)
                .foregroundStyle(Theme.textDim)
        }
        .padding(16)
        .screenBackground()
        .navigationTitle(card.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Runs through a set of cards with Reveal and Next. No ratings.
struct PracticeView: View {
    @State private var cards: [CardRecord]
    @State private var index = 0
    @State private var revealed = false

    init(cards: [CardRecord]) {
        _cards = State(initialValue: cards)
    }

    var body: some View {
        VStack(spacing: 20) {
            if index < cards.count {
                Text("\(index + 1) / \(cards.count)")
                    .font(Theme.mono(13, .semibold))
                    .foregroundStyle(Theme.textDim)
                FlipCardView(card: cards[index], revealed: revealed)
                    .id(index)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .onTapGesture { flip() }
                if revealed {
                    Button("NEXT") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            revealed = false
                            index += 1
                        }
                    }
                    .buttonStyle(NeonButtonStyle(color: Theme.blue))
                } else {
                    Button("REVEAL", action: flip)
                        .buttonStyle(NeonButtonStyle(fill: Theme.sunGradient, glow: Theme.sun))
                }
            } else {
                Spacer()
                Text("PRACTICE\nCOMPLETE")
                    .font(Theme.mono(28, .heavy))
                    .tracking(4)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.sunGradient)
                    .glow(Theme.magenta)
                Spacer()
                Button("AGAIN") {
                    withAnimation {
                        cards.shuffle()
                        index = 0
                    }
                }
                .buttonStyle(NeonButtonStyle(fill: Theme.sunGradient, glow: Theme.sun))
            }
        }
        .padding(16)
        .screenBackground()
        .navigationTitle("Practice")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func flip() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { revealed.toggle() }
    }
}
