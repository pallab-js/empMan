import SwiftUI

struct TaskListView: View {
    @EnvironmentObject var store: AppStore
    @State private var searchText = ""
    @State private var statusFilter: TaskStatus?
    @State private var priorityFilter: TaskPriority?
    @State private var showNewTask = false
    @State private var editTask: Task?

    private var filtered: [Task] {
        store.tasks.filter { t in
            let matchesSearch = searchText.isEmpty
                || t.title.localizedCaseInsensitiveContains(searchText)
                || t.description?.localizedCaseInsensitiveContains(searchText) == true
                || store.employee(for: t.assigneeId)?.fullName.localizedCaseInsensitiveContains(searchText) == true
            return matchesSearch &&
                (statusFilter == nil || t.status == statusFilter) &&
                (priorityFilter == nil || t.priority == priorityFilter)
        }.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tasks").font(.largeTitle.bold())
                    Text("\(store.tasks.count) total tasks").foregroundStyle(.secondary)
                }
                Spacer()
                Button { showNewTask = true } label: { Label("New Task", systemImage: "plus").font(.headline) }
                    .buttonStyle(.borderedProminent)
            }.padding(Layout.paddingPage)

            HStack(spacing: Layout.paddingM) {
                SearchBar(text: $searchText, placeholder: "Search tasks...")

                Picker("Status", selection: $statusFilter) {
                    Text("All Statuses").tag(nil as TaskStatus?)
                    Divider()
                    ForEach(TaskStatus.allCases) { Text($0.rawValue).tag($0 as TaskStatus?) }
                }.frame(width: Layout.searchMinWidth)

                Picker("Priority", selection: $priorityFilter) {
                    Text("All Priorities").tag(nil as TaskPriority?)
                    Divider()
                    ForEach(TaskPriority.allCases) { Text($0.rawValue).tag($0 as TaskPriority?) }
                }.frame(width: Layout.searchMinWidth)

                Spacer()
                if statusFilter != nil || priorityFilter != nil || !searchText.isEmpty {
                    Button("Clear") { statusFilter = nil; priorityFilter = nil; searchText = "" }
                        .font(.caption).foregroundStyle(.blue)
                }
                Text("\(filtered.count) shown").font(.caption).foregroundStyle(.tertiary)
            }.padding(.horizontal, Layout.paddingPage).padding(.vertical, Layout.paddingM).background(.background)

            if filtered.isEmpty {
                EmptyState(
                    icon: "checklist",
                    title: "No tasks found",
                    buttonTitle: "Create a Task",
                    action: { showNewTask = true }
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: Layout.paddingS) {
                        ForEach(filtered) { task in
                            TaskRow(task: task) { editTask = task }
                        }
                    }.padding(Layout.paddingPage)
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .sheet(isPresented: $showNewTask) { NewTaskSheet() }
        .sheet(item: $editTask) { task in EditTaskSheet(task: task) }
    }
}

struct TaskRow: View {
    @EnvironmentObject var store: AppStore
    let task: Task
    var onTap: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                if task.isOverdue {
                    RoundedRectangle(cornerRadius: Layout.cornerRadiusM)
                        .fill(.red)
                        .frame(width: 4)
                        .padding(.trailing, Layout.paddingM)
                }
                HStack(spacing: Layout.paddingM) {
                    Image(systemName: task.status.icon).foregroundStyle(Color(hex: task.status.colorHex)).frame(width: Layout.iconSizeMedium)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(task.title).font(.subheadline.bold()).lineLimit(1)
                            Spacer()
                            Text(task.priority.rawValue).font(.caption).padding(.horizontal, 8).padding(.vertical, 2)
                                .background(Color(hex: task.priority.colorHex).opacity(0.12))
                                .foregroundStyle(Color(hex: task.priority.colorHex)).clipShape(Capsule())
                        }
                        if let desc = task.description { Text(desc).font(.caption).foregroundStyle(.tertiary).lineLimit(1) }
                        HStack(spacing: 16) {
                            Label(task.category.rawValue, systemImage: task.category.icon).font(.caption).foregroundStyle(.secondary)
                            if let due = task.dueDate {
                                Label(due.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                                    .font(.caption).foregroundStyle(task.isOverdue ? .red : .secondary)
                            }
                            Spacer()
                            if let emp = store.employee(for: task.assigneeId) {
                                HStack(spacing: 4) {
                                    Circle().fill(Color(hex: emp.role.colorHex)).frame(width: Layout.avatarSizeSmall, height: Layout.avatarSizeSmall)
                                        .overlay(Text(String(emp.firstName.prefix(1))).font(.system(size: 8)).foregroundStyle(.white))
                                    Text(emp.fullName).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .padding(Layout.paddingL)
            }
            .background(task.isOverdue ? Color.red.opacity(0.04) : Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadiusM))
            .shadow(color: .black.opacity(isHovered ? 0.1 : 0.04), radius: isHovered ? 6 : 2, y: isHovered ? 3 : 1)
            .scaleEffect(isHovered ? 1.005 : 1.0)
            .animation(AppPreferences.animationsEnabled ? .easeInOut(duration: Layout.hoverAnimationDuration) : nil, value: isHovered)
        }.buttonStyle(.plain).onHover { isHovered = $0 }
    }
}

struct NewTaskSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var priority: TaskPriority = .medium
    @State private var category: TaskCategory = .projectWork
    @State private var dueDate: Date?
    @State private var assigneeId: UUID?
    @State private var projectId: UUID?

    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetHeader(
                title: "New Task",
                primaryTitle: "Create",
                primaryDisabled: trimmedTitle.isEmpty,
                onDismiss: { dismiss() },
                onPrimary: { create() }
            )
            Form {
                TextField("Title", text: $title)
                StyledTextEditor(text: $description, placeholder: "Task description...")
                Picker("Priority", selection: $priority) { ForEach(TaskPriority.allCases) { Text($0.rawValue).tag($0) } }
                Picker("Category", selection: $category) { ForEach(TaskCategory.allCases) { Text($0.rawValue).tag($0) } }
                OptionalDatePicker(title: "Due Date", date: $dueDate)
                Picker("Assign To", selection: $assigneeId) {
                    Text("Unassigned").tag(nil as UUID?)
                    ForEach(store.employees.filter(\.isActive)) { Text($0.fullName).tag($0.id as UUID?) }
                }
                Picker("Project", selection: $projectId) {
                    Text("No Project").tag(nil as UUID?)
                    ForEach(store.projects) { Text($0.name).tag($0.id as UUID?) }
                }
            }.padding(Layout.paddingXXL)
        }.frame(minWidth: Layout.minSheetWidthWide, minHeight: Layout.minSheetHeightDetail)
    }

    private func create() {
        let task = Task(title: trimmedTitle, description: description.isEmpty ? nil : description, priority: priority, category: category, dueDate: dueDate, assigneeId: assigneeId, projectId: projectId)
        store.addTask(task)
        dismiss()
    }
}

struct EditTaskSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    let task: Task
    @State private var title: String
    @State private var description: String
    @State private var priority: TaskPriority
    @State private var status: TaskStatus
    @State private var category: TaskCategory
    @State private var dueDate: Date?
    @State private var assigneeId: UUID?
    @State private var projectId: UUID?
    @State private var showDelete = false

    init(task: Task) {
        self.task = task
        _title = State(initialValue: task.title)
        _description = State(initialValue: task.description ?? "")
        _priority = State(initialValue: task.priority)
        _status = State(initialValue: task.status)
        _category = State(initialValue: task.category)
        _dueDate = State(initialValue: task.dueDate)
        _assigneeId = State(initialValue: task.assigneeId)
        _projectId = State(initialValue: task.projectId)
    }

    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetHeader(
                title: "Edit Task",
                showDestructive: true,
                destructiveTitle: "Delete",
                onDestructive: { showDelete = true },
                primaryDisabled: trimmedTitle.isEmpty,
                onDismiss: { dismiss() },
                onPrimary: { save() }
            )
            Form {
                TextField("Title", text: $title)
                StyledTextEditor(text: $description, placeholder: "Task description...")
                Picker("Status", selection: $status) { ForEach(TaskStatus.allCases) { Text($0.rawValue).tag($0) } }
                Picker("Priority", selection: $priority) { ForEach(TaskPriority.allCases) { Text($0.rawValue).tag($0) } }
                Picker("Category", selection: $category) { ForEach(TaskCategory.allCases) { Text($0.rawValue).tag($0) } }
                OptionalDatePicker(title: "Due Date", date: $dueDate)
                Picker("Assign To", selection: $assigneeId) {
                    Text("Unassigned").tag(nil as UUID?)
                    ForEach(store.employees.filter(\.isActive)) { Text($0.fullName).tag($0.id as UUID?) }
                }
                Picker("Project", selection: $projectId) {
                    Text("No Project").tag(nil as UUID?)
                    ForEach(store.projects) { Text($0.name).tag($0.id as UUID?) }
                }
            }.padding(Layout.paddingXXL)
        }
        .frame(minWidth: Layout.minSheetWidthWide, minHeight: Layout.minSheetHeightDetail)
        .alert("Delete Task?", isPresented: $showDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { store.deleteTask(task); dismiss() }
        }
    }

    private func save() {
        var updated = task
        updated.title = trimmedTitle
        updated.description = description.isEmpty ? nil : description
        updated.priority = priority
        updated.status = status
        updated.category = category
        updated.dueDate = dueDate
        updated.assigneeId = assigneeId
        updated.projectId = projectId
        updated.updatedAt = Date()
        if status == .done && updated.completedAt == nil {
            updated.completedAt = Date()
        } else if status != .done {
            updated.completedAt = nil
        }
        store.updateTask(updated)
        dismiss()
    }
}
