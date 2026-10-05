import SwiftUI
import FlashyCore

/// Today's daily set: reveal each card, then rate it. Cards rated bad come back
/// at the end; only the first rating is recorded.
struct ReviewSessionView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var session: ReviewSession<String>
    @State private var revealed = false
    /// Changes on every rating so the next card slides in as a fresh view.
    @State private var turn = 0
    private let cardsByID: [String: CardRecord]

    init(cards: [CardRecord]) {
        _session = State(initialValue: ReviewSession(cards: cards.map(\.id)))
        cardsByID = Dictionary(cards.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            if session.isFinished {
                SessionSummaryView(summary: session.summary, total: session.totalCards) { dismiss() }
            } else if let id = session.current, let card = cardsByID[id] {
                VStack(spacing: 20) {
                    topBar
                    FlipCardView(card: card, revealed: revealed)
                        .id(turn)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        .onTapGesture { reveal() }
                    controls
                }
                .padding(16)
            }
        }
    }

    private var topBar: some View {
        let done = session.totalCards - session.unratedCount
        return HStack(spacing: 16) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundStyle(Theme.textDim)
            }
            ProgressView(value: Double(done), total: Double(max(session.totalCards, 1)))
                .tint(Theme.magenta)
            Text("\(done)/\(session.totalCards)")
                .font(Theme.mono(13, .semibold))
                .foregroundStyle(Theme.textDim)
        }
    }

    @ViewBuilder
    private var controls: some View {
        if revealed {
            RatingBar(onRate: rate)
        } else {
            Button("REVEAL", action: reveal)
                .buttonStyle(NeonButtonStyle(fill: Theme.sunGradient, glow: Theme.sun))
        }
    }

    private func reveal() {
        guard !revealed else { return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { revealed = true }
    }

    private func rate(_ rating: Rating) {
        guard let id = session.current, let card = cardsByID[id] else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            if let result = session.rate(rating), result.isFirst {
                model.record(rating, for: card)
            }
            revealed = false
            turn += 1
        }
    }
}

struct RatingBar: View {
    let onRate: (Rating) -> Void

    var body: some View {
        HStack(spacing: 12) {
            ForEach([Rating.bad, .okay, .good], id: \.self) { rating in
                Button(rating.rawValue.uppercased()) { onRate(rating) }
                    .buttonStyle(NeonButtonStyle(color: Theme.color(for: rating)))
            }
        }
    }
}

struct SessionSummaryView: View {
    let summary: [Rating: Int]
    let total: Int
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Text("SESSION\nCOMPLETE")
                .font(Theme.mono(32, .heavy))
                .tracking(4)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.sunGradient)
                .glow(Theme.magenta)
            Text(total == 1 ? "1 card reviewed" : "\(total) cards reviewed")
                .font(Theme.mono(15))
                .foregroundStyle(Theme.textDim)
            VStack(spacing: 12) {
                ForEach([Rating.good, .okay, .bad], id: \.self) { rating in
                    bar(rating)
                }
            }
            .panel()
            Spacer()
            Button("DONE", action: onDone)
                .buttonStyle(NeonButtonStyle(fill: Theme.sunGradient, glow: Theme.sun))
        }
        .padding(24)
    }

    private func bar(_ rating: Rating) -> some View {
        let count = summary[rating, default: 0]
        let fraction = total == 0 ? 0 : Double(count) / Double(total)
        return HStack(spacing: 12) {
            Text(rating.rawValue.uppercased())
                .font(Theme.mono(13, .bold))
                .foregroundStyle(Theme.color(for: rating))
                .frame(width: 52, alignment: .leading)
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.color(for: rating))
                    .frame(width: max(geometry.size.width * fraction, 4))
                    .glow(Theme.color(for: rating), radius: 6)
            }
            .frame(height: 10)
            Text("\(count)")
                .font(Theme.mono(13, .bold))
                .foregroundStyle(Theme.text)
                .frame(width: 32, alignment: .trailing)
        }
    }
}
