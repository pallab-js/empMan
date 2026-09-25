import SwiftUI

@main
struct GasGridApp: App {
    @StateObject private var store = AppStore.shared
    @State private var showResetConfirm = false

    init() {
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: Layout.appMinWidth, minHeight: Layout.appMinHeight)
                .environmentObject(store)
                .onAppear {
                    store.loadSampleData()
                }
                .alert("Reload Sample Data?", isPresented: $showResetConfirm) {
                    Button("Cancel", role: .cancel) {}
                    Button("Reload", role: .destructive) {
                        store.resetToSampleData()
                    }
                } message: {
                    Text("This will delete all current data and reload sample data. This cannot be undone.")
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .defaultSize(width: Layout.appIdealWidth, height: Layout.appIdealHeight)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(after: .pasteboard) {
                Button("Reload Sample Data") {
                    showResetConfirm = true
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var store: AppStore
    @AppStorage("compactSidebar") private var compactSidebar = false
    @State private var selectedItem: NavigationItem? = .dashboard
    @State private var columnVisibility: NavigationSplitViewVisibility = .doubleColumn

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selectedItem: $selectedItem)
                .navigationSplitViewColumnWidth(
                    min: compactSidebar ? Layout.sidebarCompactMinWidth : Layout.sidebarMinWidth,
                    ideal: compactSidebar ? Layout.sidebarCompactIdealWidth : Layout.sidebarIdealWidth
                )
        } detail: {
            DetailContent(selectedItem: selectedItem)
        }
        .navigationSplitViewStyle(.balanced)
    }
}

struct DetailContent: View {
    let selectedItem: NavigationItem?

    var body: some View {
        Group {
            switch selectedItem {
            case .dashboard: DashboardView()
            case .tasks: TaskListView()
            case .employees: EmployeeListView()
            case .departments: DepartmentListView()
            case .teams: TeamListView()
            case .projects: ProjectListView()
            case .settings: SettingsView()
            case .none: DashboardView()
            }
        }
        .transition(.opacity)
        .animation(AppPreferences.animationsEnabled ? .easeInOut(duration: Layout.animationDuration) : nil, value: selectedItem)
    }
}
