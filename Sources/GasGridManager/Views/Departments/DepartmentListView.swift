import SwiftUI

struct DepartmentListView: View {
    @EnvironmentObject var store: AppStore
    @State private var searchText = ""
    @State private var showNew = false
    @State private var editDept: Department?

    private var filtered: [Department] {
        store.departments.filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Departments").font(.largeTitle.bold())
                    Text("\(store.departments.count) departments").foregroundStyle(.secondary)
                }
                Spacer()
                Button { showNew = true } label: { Label("New Department", systemImage: "plus").font(.headline) }.buttonStyle(.borderedProminent)
            }.padding(Layout.paddingPage)

            HStack(spacing: Layout.paddingM) {
                SearchBar(text: $searchText, placeholder: "Search departments...")
                Spacer()
            }.padding(.horizontal, Layout.paddingPage).padding(.vertical, Layout.paddingM).background(.background)

            if filtered.isEmpty {
                EmptyState(
                    icon: "building.2",
                    title: "No departments found",
                    buttonTitle: "Create Department",
                    action: { showNew = true }
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: Layout.paddingL) {
                        ForEach(filtered) { dept in
                            DepartmentCard(department: dept) { editDept = dept }
                        }
                    }.padding(Layout.paddingPage)
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .sheet(isPresented: $showNew) { NewDepartmentSheet() }
        .sheet(item: $editDept) { dept in EditDepartmentSheet(department: dept) }
    }
}

struct DepartmentCard: View {
    @EnvironmentObject var store: AppStore
    let department: Department
    var onTap: () -> Void
    @State private var isHovered = false

    private var memberCount: Int { store.employees.filter { $0.departmentId == department.id && $0.isActive }.count }
    private var activeTasks: Int {
        let ids = Set(store.employees.filter { $0.departmentId == department.id }.map(\.id))
        return store.tasks.filter { ids.contains($0.assigneeId ?? UUID()) && $0.status != .done }.count
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Layout.paddingXL) {
                HStack(spacing: Layout.paddingL) {
                    RoundedRectangle(cornerRadius: Layout.cornerRadiusM)
                        .fill(Color(hex: department.colorHex).opacity(0.15))
                        .frame(width: Layout.avatarSizeXXL + Layout.paddingL, height: Layout.avatarSizeXXL + Layout.paddingL)
                        .overlay(
                            Image(systemName: "building.2.fill")
                                .font(.title3)
                                .foregroundStyle(Color(hex: department.colorHex))
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(department.name).font(.headline)
                        if let desc = department.description {
                            Text(desc).font(.caption).foregroundStyle(.tertiary).lineLimit(1)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                }

                HStack(spacing: 32) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.2.fill").font(.caption).foregroundStyle(.secondary)
                        Text("\(memberCount) members").font(.subheadline).foregroundStyle(.secondary)
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "checklist").font(.caption).foregroundStyle(.secondary)
                        Text("\(activeTasks) active tasks").font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                let members = store.employees.filter { $0.departmentId == department.id && $0.isActive }
                let displayMembers = members.prefix(Layout.maxDisplayMembers)
                if !displayMembers.isEmpty {
                    HStack(spacing: -6) {
                        ForEach(displayMembers) { emp in
                            Circle()
                                .fill(Color(hex: emp.role.colorHex))
                                .frame(width: Layout.avatarSizeLarge, height: Layout.avatarSizeLarge)
                                .overlay(Text(emp.initials).font(.system(size: 9, weight: .semibold)).foregroundStyle(.white))
                                .overlay(Circle().stroke(.background, lineWidth: 2))
                        }
                        if memberCount > Layout.maxDisplayMembers {
                            Circle()
                                .fill(.quaternary)
                                .frame(width: Layout.avatarSizeLarge, height: Layout.avatarSizeLarge)
                                .overlay(Text("+\(memberCount - Layout.maxDisplayMembers)").font(.system(size: 9, weight: .semibold)).foregroundStyle(.secondary))
                                .overlay(Circle().stroke(.background, lineWidth: 2))
                        }
                    }
                }
            }
            .padding(Layout.paddingXL)
            .cardStyle(isHovered: isHovered)
        }.buttonStyle(.plain).onHover { isHovered = $0 }
    }
}

struct NewDepartmentSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var desc = ""
    @State private var colorHex = "1E40AF"

    private let colorOptions = ["059669", "0284C7", "DC2626", "7C3AED", "D97706", "64748B", "1E40AF", "0891B2", "C2410C"]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetHeader(
                title: "New Department",
                primaryTitle: "Create",
                primaryDisabled: name.isEmpty,
                onDismiss: { dismiss() },
                onPrimary: { create() }
            )
            Form {
                TextField("Department Name", text: $name)
                StyledTextEditor(text: $desc, placeholder: "Department description...", minHeight: 60)
                HStack(spacing: Layout.paddingS) {
                    Text("Color").foregroundStyle(.secondary)
                    Spacer()
                    ForEach(colorOptions, id: \.self) { hex in
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: Layout.paddingXL, height: Layout.paddingXL)
                            .overlay(
                                Circle().stroke(colorHex == hex ? Color.primary : Color.clear, lineWidth: 2)
                            )
                            .onTapGesture { colorHex = hex }
                    }
                }
            }.padding(Layout.paddingXXL)
        }.frame(minWidth: Layout.minSheetWidth, minHeight: Layout.minSheetHeightTall)
    }

    private func create() {
        store.addDepartment(Department(name: name, description: desc.isEmpty ? nil : desc, colorHex: colorHex))
        dismiss()
    }
}

struct EditDepartmentSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    let department: Department
    @State private var name: String
    @State private var desc: String
    @State private var colorHex: String
    @State private var showDelete = false

    private let colorOptions = ["059669", "0284C7", "DC2626", "7C3AED", "D97706", "64748B", "1E40AF", "0891B2", "C2410C"]

    init(department: Department) {
        self.department = department
        _name = State(initialValue: department.name)
        _desc = State(initialValue: department.description ?? "")
        _colorHex = State(initialValue: department.colorHex)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetHeader(
                title: "Edit Department",
                showDestructive: true,
                destructiveTitle: "Delete",
                onDestructive: { showDelete = true },
                onDismiss: { dismiss() },
                onPrimary: { save() }
            )
            Form {
                TextField("Name", text: $name)
                StyledTextEditor(text: $desc, placeholder: "Department description...", minHeight: 60)
                HStack(spacing: Layout.paddingS) {
                    Text("Color").foregroundStyle(.secondary)
                    Spacer()
                    ForEach(colorOptions, id: \.self) { hex in
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: Layout.paddingXL, height: Layout.paddingXL)
                            .overlay(Circle().stroke(colorHex == hex ? Color.primary : Color.clear, lineWidth: 2))
                            .onTapGesture { colorHex = hex }
                    }
                }
            }.padding(Layout.paddingXXL)
        }
        .frame(minWidth: Layout.minSheetWidth, minHeight: Layout.minSheetHeightTall)
        .alert("Delete Department?", isPresented: $showDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { store.deleteDepartment(department); dismiss() }
        }
    }

    private func save() {
        var d = department
        d.name = name
        d.description = desc.isEmpty ? nil : desc
        d.colorHex = colorHex
        d.updatedAt = Date()
        store.updateDepartment(d)
        dismiss()
    }
}
