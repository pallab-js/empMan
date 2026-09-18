import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    @AppStorage("showActiveOnly") private var showActiveOnly = true
    @AppStorage("compactSidebar") private var compactSidebar = false
    @AppStorage("enableAnimations") private var enableAnimations = true
    @State private var showReset = false
    @State private var exportSuccess = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.paddingPage) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings").font(.largeTitle.bold())
                    Text("Configure your GasGrid Manager preferences").foregroundStyle(.secondary)
                }

                section("Appearance") {
                    ToggleRow(title: "Compact Sidebar", subtitle: "Use a narrower sidebar layout", icon: "sidebar.left", isOn: $compactSidebar)
                    ToggleRow(title: "Enable Animations", subtitle: "Show hover and transition animations", icon: "sparkles", isOn: $enableAnimations)
                }

                section("Data") {
                    ToggleRow(title: "Show Active Only", subtitle: "Display only active employees by default", icon: "person.2", isOn: $showActiveOnly)
                    ButtonRow(title: "Export Data", subtitle: "Export all data to JSON files", icon: "square.and.arrow.up") { exportData() }
                    ButtonRow(title: "Reload Sample Data", subtitle: "Reset and reload sample data", icon: "arrow.counterclockwise", destructive: true) { showReset = true }
                }

                section("Shortcuts") {
                    InfoRow(title: "Reload Sample Data", value: "\u{2318}\u{21E7}R")
                    InfoRow(title: "New Item", value: "Use the + button on each page")
                    InfoRow(title: "Search", value: "Click the search field on each page")
                }

                section("About") {
                    InfoRow(title: "App Name", value: "GasGrid Manager")
                    InfoRow(title: "Version", value: "1.0.0")
                    InfoRow(title: "Platform", value: "macOS 14.0+")
                    InfoRow(title: "Framework", value: "SwiftUI + Codable")
                    InfoRow(title: "Storage", value: "Local JSON files")
                    InfoRow(title: "Employees", value: "\(store.employees.count)")
                    InfoRow(title: "Tasks", value: "\(store.tasks.count)")
                    InfoRow(title: "Departments", value: "\(store.departments.count)")
                    InfoRow(title: "Teams", value: "\(store.teams.count)")
                    InfoRow(title: "Projects", value: "\(store.projects.count)")
                }
            }.padding(Layout.paddingPage)
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .alert("Reset Data?", isPresented: $showReset) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                store.resetToSampleData()
            }
        } message: {
            Text("This will delete all current data and reload sample data. This cannot be undone.")
        }
        .alert("Export Complete", isPresented: $exportSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Data exported to ~/Library/Application Support/GasGridManager/")
        }
    }

    private func exportData() {
        store.saveAll()
        exportSuccess = true
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            VStack(spacing: 0) { content() }.background(.background).clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadiusL)).shadow(color: .black.opacity(0.03), radius: 2, y: 1)
        }
    }
}

struct ToggleRow: View {
    let title: String, subtitle: String, icon: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: Layout.paddingM) {
            Image(systemName: icon).font(.system(size: 16)).foregroundStyle(.blue).frame(width: 32)
            VStack(alignment: .leading, spacing: 2) { Text(title).font(.subheadline); Text(subtitle).font(.caption).foregroundStyle(.tertiary) }
            Spacer()
            Toggle("", isOn: $isOn).toggleStyle(.switch).labelsHidden()
        }.padding(Layout.paddingL)
    }
}

struct ButtonRow: View {
    let title: String, subtitle: String, icon: String
    var destructive = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Layout.paddingM) {
                Image(systemName: icon).font(.system(size: 16)).foregroundStyle(destructive ? .red : .blue).frame(width: 32)
                VStack(alignment: .leading, spacing: 2) { Text(title).font(.subheadline).foregroundStyle(destructive ? .red : .primary); Text(subtitle).font(.caption).foregroundStyle(.tertiary) }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
            }.padding(Layout.paddingL)
        }.buttonStyle(.plain)
    }
}

struct InfoRow: View {
    let title: String, value: String

    var body: some View {
        HStack { Text(title).font(.subheadline).foregroundStyle(.secondary); Spacer(); Text(value).font(.subheadline) }.padding(Layout.paddingL)
    }
}
