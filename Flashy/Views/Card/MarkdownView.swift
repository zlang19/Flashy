import SwiftUI
import UIKit
import FlashyCore

/// Renders one side of a card. Block structure comes from `CardMarkdown`; inline
/// styling (bold, italic, `code`, links) from Foundation's markdown parser.
struct MarkdownView: View {
    let markdown: String
    /// Repo-relative card folder, for resolving image paths.
    let directory: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(CardMarkdown.blocks(from: markdown).enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
        .foregroundStyle(Theme.text)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func blockView(_ block: MarkdownBlock) -> some View {
        switch block {
        case let .heading(level, text):
            Text(inline(text))
                .font(level == 1 ? .title2.bold() : level == 2 ? .title3.bold() : .headline)
        case let .paragraph(text):
            Text(inline(text))
                .font(.body)
        case let .listItem(marker, indent, text):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(markerText(marker))
                    .font(Theme.mono(15, .bold))
                    .foregroundStyle(Theme.magenta)
                Text(inline(text))
            }
            .padding(.leading, CGFloat(indent) * 18)
        case let .quote(text):
            Text(inline(text))
                .italic()
                .foregroundStyle(Theme.textDim)
                .padding(.leading, 12)
                .overlay(alignment: .leading) {
                    Rectangle().fill(Theme.magenta).frame(width: 3)
                }
        case let .code(code):
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(Theme.mono(14))
                    .padding(12)
            }
            .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
        case let .image(alt, source):
            CardImage(alt: alt, source: source, directory: directory)
        case .rule:
            Rectangle()
                .fill(Theme.edgeGradient)
                .frame(height: 1)
        }
    }

    private func markerText(_ marker: ListMarker) -> String {
        switch marker {
        case .bullet: return "▸"
        case let .number(n): return "\(n)."
        }
    }

    private func inline(_ text: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        return (try? AttributedString(markdown: text, options: options)) ?? AttributedString(text)
    }
}

struct CardImage: View {
    let alt: String
    let source: String
    let directory: String

    var body: some View {
        if let resolved = CardMarkdown.resolve(source, cardDirectory: directory) {
            if resolved.hasPrefix("http"), let url = URL(string: resolved) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        styled(image)
                    } else if phase.error != nil {
                        placeholder
                    } else {
                        ProgressView().frame(maxWidth: .infinity, minHeight: 120)
                    }
                }
            } else if let image = UIImage(contentsOfFile: CardCache.shared.url(for: resolved).path) {
                styled(Image(uiImage: image))
            } else {
                placeholder
            }
        } else {
            placeholder
        }
    }

    private func styled(_ image: Image) -> some View {
        image
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .accessibilityLabel(alt)
    }

    private var placeholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.badge.exclamationmark")
                .font(.title)
            Text(alt.isEmpty ? source : alt)
                .font(Theme.mono(12))
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(Theme.textDim)
        .frame(maxWidth: .infinity, minHeight: 120)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.textDim.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
        )
    }
}
