import SwiftData
import SwiftUI
import FlashyCore

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Query(filter: #Predicate<CardRecord> { $0.isActive }) private var cards: [CardRecord]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Daily reminder", isOn: Binding(
                        get: { model.reminderEnabled },
                        set: { model.setReminder(enabled: $0) }
                    ))
                    if model.reminderEnabled {
                        DatePicker("Time", selection: Binding(
                            get: { model.reminderTime },
                            set: { model.setReminder(time: $0) }
                        ), displayedComponents: .hourAndMinute)
                    }
                } header: {
                    SectionTitle("Reminder")
                } footer: {
                    Text("The app badge always shows today's remaining cards. The reminder adds an alert on days with cards due.")
                }
                .listRowBackground(Theme.surface)

                Section {
                    LabeledContent("Last synced", value: lastSynced)
                    if let sha = model.syncState.commitSHA {
                        LabeledContent("Commit") {
                            Text(String(sha.prefix(7))).font(Theme.mono(14))
                        }
                    }
                    if let error = model.syncError {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(Theme.color(for: .bad))
                    }
                    Button {
                        Task { await model.sync() }
                    } label: {
                        HStack {
                            Text(model.isSyncing ? "Syncing…" : "Sync now")
                            Spacer()
                            if model.isSyncing { ProgressView() }
                        }
                    }
                    .disabled(model.isSyncing)
                    NavigationLink {
                        SyncIssuesView(issues: model.syncState.issues)
                    } label: {
                        LabeledContent("Sync issues", value: "\(model.syncState.issues.count)")
                    }
                } header: {
                    SectionTitle("Sync")
                }
                .listRowBackground(Theme.surface)

                Section {
                    LabeledContent("Cards", value: "\(cards.count)")
                    LabeledContent("Repository", value: "\(GitHubRepo.flashy.owner)/\(GitHubRepo.flashy.name)")
                    LabeledContent("Branch", value: GitHubRepo.flashy.branch)
                } header: {
                    SectionTitle("Library")
                }
                .listRowBackground(Theme.surface)
            }
            .themedList()
            .navigationTitle("Settings")
        }
    }

    private var lastSynced: String {
        model.syncState.lastSynced?.formatted(.relative(presentation: .named)) ?? "Never"
    }
}

struct SyncIssuesView: View {
    let issues: [SyncIssue]

    var body: some View {
        List {
            if issues.isEmpty {
                Text("No problems found in the last sync.")
                    .foregroundStyle(Theme.textDim)
                    .listRowBackground(Theme.surface)
            }
            ForEach(issues, id: \.self) { issue in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(issue.skipped ? "SKIPPED" : "WARNING")
                            .font(Theme.mono(10, .bold))
                            .foregroundStyle(issue.skipped ? Theme.color(for: .bad) : Theme.sun)
                        Spacer()
                    }
                    Text(issue.path)
                        .font(Theme.mono(12))
                        .foregroundStyle(Theme.text)
                    Text(issue.reason)
                        .font(.footnote)
                        .foregroundStyle(Theme.textDim)
                }
                .listRowBackground(Theme.surface)
            }
        }
        .themedList()
        .navigationTitle("Sync Issues")
    }
}
