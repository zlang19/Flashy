import SwiftUI
import FlashyCore

/// A card that flips from front to back when `revealed` changes inside an animation.
struct FlipCardView: View {
    let card: CardRecord
    let revealed: Bool

    var body: some View {
        ZStack {
            CardFace(side: "FRONT", markdown: card.front, card: card)
                .opacity(revealed ? 0 : 1)
                .rotation3DEffect(.degrees(revealed ? 180 : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
            CardFace(side: "BACK", markdown: card.back, card: card)
                .opacity(revealed ? 1 : 0)
                .rotation3DEffect(.degrees(revealed ? 0 : -180), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
        }
    }
}

private struct CardFace: View {
    let side: String
    let markdown: String
    let card: CardRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(card.breadcrumb.uppercased())
                    .font(Theme.mono(11))
                    .foregroundStyle(Theme.textDim)
                    .lineLimit(1)
                Spacer()
                Text(side)
                    .font(Theme.mono(11, .bold))
                    .tracking(2)
                    .foregroundStyle(Theme.sun)
            }
            ScrollView {
                MarkdownView(markdown: markdown, directory: card.directory)
                    .padding(.bottom, 8)
            }
            .scrollIndicators(.hidden)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(Theme.cardGradient)
                .overlay(Scanlines().clipShape(RoundedRectangle(cornerRadius: 24)))
        }
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Theme.edgeGradient, lineWidth: 1.5))
        .glow(Theme.magenta.opacity(0.6), radius: 18)
    }
}

/// A list row describing a card and where it is in its schedule.
struct CardRow: View {
    let card: CardRecord
    let today: StudyDay

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(card.title)
                .foregroundStyle(Theme.text)
            HStack {
                Text(card.breadcrumb)
                Spacer()
                Text(status)
            }
            .font(Theme.mono(11))
            .foregroundStyle(Theme.textDim)
        }
    }

    private var status: String {
        guard let due = card.schedule.dueDay else { return "NEW" }
        let days = today.days(until: due)
        if days <= 0 { return "DUE" }
        return days == 1 ? "IN 1 DAY" : "IN \(days) DAYS"
    }
}
