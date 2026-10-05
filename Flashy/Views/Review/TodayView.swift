import SwiftData
import SwiftUI
import FlashyCore

struct TodayView: View {
    @Environment(AppModel.self) private var model
    @Query(filter: #Predicate<CardRecord> { $0.isActive }) private var cards: [CardRecord]
    @State private var session: SessionLaunch?

    private struct SessionLaunch: Identifiable {
        let id = UUID()
        let cards: [CardRecord]
    }

    private var due: [CardRecord] { cards.filter { $0.schedule.isDue(on: model.today) } }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                header
                counter
                if !due.isEmpty {
                    Button("START REVIEW") {
                        session = SessionLaunch(cards: model.dailySet())
                    }
                    .buttonStyle(NeonButtonStyle(fill: Theme.sunGradient, glow: Theme.sun))
                    .padding(.horizontal, 24)
                } else {
                    emptyState
                }
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 16)
        }
        .refreshable { await model.sync() }
        .screenBackground()
        .fullScreenCover(item: $session) { launch in
            ReviewSessionView(cards: launch.cards)
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("FLASHY")
                .font(Theme.mono(34, .heavy))
                .tracking(8)
                .foregroundStyle(Theme.sunGradient)
                .glow(Theme.magenta, radius: 10)
            SyncStatusLine()
        }
    }

    private var counter: some View {
        let newCount = due.filter(\.schedule.isNew).count
        return VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Theme.sun.opacity(0.55), .clear], center: .center, startRadius: 10, endRadius: 140))
                    .frame(width: 280, height: 280)
                Text("\(due.count)")
                    .font(Theme.mono(96, .bold))
                    .foregroundStyle(Theme.text)
                    .glow(Theme.magenta, radius: 16)
                    .contentTransition(.numericText())
            }
            .frame(height: 220)
            Text(due.isEmpty ? "ALL CLEAR" : "CARDS TODAY")
                .font(Theme.mono(14, .semibold))
                .tracking(4)
                .foregroundStyle(Theme.textDim)
            if !due.isEmpty {
                HStack(spacing: 12) {
                    pill("REVIEW", due.count - newCount, Theme.blue)
                    pill("NEW", newCount, Theme.sun)
                }
            }
        }
    }

    private func pill(_ label: String, _ count: Int, _ color: Color) -> some View {
        HStack(spacing: 6) {
            Text(label).foregroundStyle(Theme.textDim)
            Text("\(count)").foregroundStyle(color)
        }
        .font(Theme.mono(13, .bold))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Theme.surface, in: Capsule())
        .overlay(Capsule().stroke(color.opacity(0.5), lineWidth: 1))
    }

    @ViewBuilder
    private var emptyState: some View {
        if cards.isEmpty {
            Text("No cards yet. Add cards under `flashcards/` in the repo, then pull down to sync.")
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textDim)
                .padding(.horizontal, 24)
        } else if let next = cards.compactMap(\.schedule.dueDay).min() {
            let days = model.today.days(until: next)
            Text(days == 1 ? "Next card due tomorrow." : "Next card due in \(days) days.")
                .font(Theme.mono(14))
                .foregroundStyle(Theme.textDim)
        }
    }
}

struct SyncStatusLine: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Group {
            if model.isSyncing {
                Text("SYNCING…")
            } else if model.syncError != nil {
                Text("OFFLINE · LAST SYNC \(lastSynced)")
                    .foregroundStyle(Theme.sun)
            } else {
                Text("SYNCED \(lastSynced)")
            }
        }
        .font(Theme.mono(11))
        .tracking(1)
        .foregroundStyle(Theme.textDim)
    }

    private var lastSynced: String {
        guard let date = model.syncState.lastSynced else { return "NEVER" }
        return date.formatted(.relative(presentation: .named)).uppercased()
    }
}
