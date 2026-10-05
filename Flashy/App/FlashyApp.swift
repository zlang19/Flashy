import SwiftData
import SwiftUI
import UIKit

@main
struct FlashyApp: App {
    private let container: ModelContainer
    @State private var model: AppModel

    init() {
        let container: ModelContainer
        do {
            container = try ModelContainer(for: CardRecord.self, ReviewRecord.self, DayRecord.self)
        } catch {
            fatalError("Couldn't open the card database: \(error)")
        }
        self.container = container
        _model = State(initialValue: AppModel(container: container))
        Theme.applyNavigationBarAppearance()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .preferredColorScheme(.dark)
        }
        .modelContainer(container)
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.horizon.fill") }
            BrowseView()
                .tabItem { Label("Browse", systemImage: "rectangle.stack.fill") }
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.xaxis") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Theme.magenta)
        .onChange(of: scenePhase, initial: true) { _, phase in
            switch phase {
            case .active: model.becameActive()
            case .background: model.enteredBackground()
            default: break
            }
        }
        .task { await Notifications.requestAuthorization() }
    }
}
