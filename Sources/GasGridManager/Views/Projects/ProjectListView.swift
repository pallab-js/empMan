import SwiftUI

struct ProjectListView: View {
    @EnvironmentObject var store: AppStore
    @State private var searchText = ""
    @State private var statusFilter: ProjectStatus?
    @State private var showNew = false

    private var filtered: [Project] {
        store.projects.filter { p in
            (searchText.isEmpty || p.name.localizedCaseInsensitiveContains(searchText)) &&
            (statusFilter == nil || p.status == statusFilter)
        }.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Projects").font(.largeTitle.bold())
                    Text("\(store.projects.count) total projects").foregroundStyle(.secondary)
                }
                Spacer()
                Button { showNew = true } label: { Label("New Project", systemImage: "plus").font(.headline) }.buttonStyle(.borderedProminent)
            }.padding(Layout.paddingPage)

            HStack(spacing: Layout.paddingM) {
                SearchBar(text: $searchText, placeholder: "Search projects...")
                Picker("Status", selection: $statusFilter) { Text("All Statuses").tag(nil as ProjectStatus?); Divider(); ForEach(ProjectStatus.allCases) { Text($0.rawValue).tag($0 as ProjectStatus?) } }.frame(width: Layout.searchMinWidth)
                Spacer()
                if statusFilter != nil || !searchText.isEmpty {
                    Button("Clear") { statusFilter = nil; searchText = "" }
                        .font(.caption).foregroundStyle(.blue)
                }
                Text("\(filtered.count) shown").font(.caption).foregroundStyle(.tertiary)
            }.padding(.horizontal, Layout.paddingPage).padding(.vertical, Layout.paddingM).background(.background)

            if filtered.isEmpty {
                EmptyState(
                    icon: "folder",
                    title: "No projects found",
                    buttonTitle: "Create Project",
                    action: { showNew = true }
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: Layout.paddingS) {
                        ForEach(filtered) { project in ProjectRow(project: project) }
                    }.padding(Layout.paddingPage)
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .sheet(isPresented: $showNew) { NewProjectSheet() }
    }
}

struct ProjectRow: View {
    @EnvironmentObject var store: AppStore
    let project: Project
    @State private var showDetail = false
    @State private var isHovered = false

    private var projectTasks: [Task] { store.tasks(forProject: project.id) }
    private var progress: Double {
        let total = projectTasks.count
        guard total > 0 else { return 0 }
        let done = projectTasks.filter { $0.status == .done }.count
        return Double(done) / Double(total)
    }

    private var statusColor: Color { Color(hex: project.status.colorHex) }

    var body: some View {
        Button { showDetail = true } label: {
            VStack(alignment: .leading, spacing: Layout.paddingL) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(project.name).font(.subheadline.bold())
                        if let desc = project.description { Text(desc).font(.caption).foregroundStyle(.tertiary).lineLimit(2) }
                    }
                    Spacer()
                    Text(project.status.rawValue).font(.caption).padding(.horizontal, 8).padding(.vertical, 2).background(Color(hex: project.status.colorHex).opacity(0.12)).foregroundStyle(Color(hex: project.status.colorHex)).clipShape(Capsule())
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack { Text("Progress").font(.caption).foregroundStyle(.tertiary); Spacer(); Text("\(Int(progress * 100))%").font(.caption.bold()) }
                    ProgressView(value: progress).tint(statusColor)
                }
                HStack {
                    Label("\(projectTasks.count) tasks", systemImage: "checklist").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    if let end = project.endDate { Label(end.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar").font(.caption).foregroundStyle(.secondary) }
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                }
            }
            .padding(Layout.paddingL)
            .cardStyle(isHovered: isHovered)
        }.buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .sheet(isPresented: $showDetail) { ProjectDetailSheet(project: project) }
    }
}

struct NewProjectSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var desc = ""
    @State private var startDate = Date()
    @State private var endDate: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetHeader(
                title: "New Project",
                primaryTitle: "Create",
                primaryDisabled: name.isEmpty,
                onDismiss: { dismiss() },
                onPrimary: { create() }
            )
            Form {
                TextField("Project Name", text: $name)
                StyledTextEditor(text: $desc, placeholder: "Project description...", minHeight: 60)
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                OptionalDatePicker(title: "End Date", date: $endDate)
            }.padding(Layout.paddingXXL)
        }.frame(minWidth: Layout.minSheetWidthWide, minHeight: Layout.minSheetHeightTall)
    }

    private func create() { store.addProject(Project(name: name, description: desc.isEmpty ? nil : desc, startDate: startDate, endDate: endDate)); dismiss() }
}

struct ProjectDetailSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    let project: Project
    @State private var name: String
    @State private var desc: String
    @State private var status: ProjectStatus
    @State private var showDelete = false

    init(project: Project) { self.project = project; _name = State(initialValue: project.name); _desc = State(initialValue: project.description ?? ""); _status = State(initialValue: project.status) }

    private var projectTasks: [Task] { store.tasks(forProject: project.id) }
    private var progress: Double { let t = projectTasks.count; guard t > 0 else { return 0 }; return Double(projectTasks.filter { $0.status == .done }.count) / Double(t) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetHeader(
                title: "Edit Project",
                showDestructive: true,
                destructiveTitle: "Delete",
                onDestructive: { showDelete = true },
                onDismiss: { dismiss() },
                onPrimary: { save() }
            )
            ScrollView {
                VStack(alignment: .leading, spacing: Layout.paddingXXL) {
                    Form { TextField("Name", text: $name); StyledTextEditor(text: $desc, placeholder: "Project description...", minHeight: 60); Picker("Status", selection: $status) { ForEach(ProjectStatus.allCases) { Text($0.rawValue).tag($0) } } }
                    VStack(alignment: .leading, spacing: 8) { Text("Progress \(Int(progress * 100))%").font(.headline); ProgressView(value: progress).tint(Color(hex: status.colorHex)) }
                    if !projectTasks.isEmpty {
                        VStack(alignment: .leading, spacing: 8) { Text("Tasks (\(projectTasks.count))").font(.headline)
                            ForEach(projectTasks) { t in HStack(spacing: Layout.paddingM) { Image(systemName: t.status.icon).foregroundStyle(Color(hex: t.status.colorHex)); Text(t.title).font(.subheadline); Spacer(); Text(t.priority.rawValue).font(.caption).foregroundStyle(Color(hex: t.priority.colorHex)) }.padding(Layout.paddingS).background(.quaternary).clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadiusS)) }
                        }
                    }
                }.padding(Layout.paddingXXL)
            }
        }.frame(minWidth: Layout.minSheetWidthWide, minHeight: Layout.minSheetHeightDetail)
        .alert("Delete Project?", isPresented: $showDelete) { Button("Cancel", role: .cancel) {}; Button("Delete", role: .destructive) { store.deleteProject(project); dismiss() } }
    }

    private func save() { var p = project; p.name = name; p.description = desc.isEmpty ? nil : desc; p.status = status; p.updatedAt = Date(); store.updateProject(p); dismiss() }
}
