import SwiftUI

struct EmployeeListView: View {
    @EnvironmentObject var store: AppStore
    @AppStorage("showActiveOnly") private var showActiveOnly = true
    @State private var searchText = ""
    @State private var deptFilter: UUID?
    @State private var roleFilter: EmployeeRole?
    @State private var showNew = false
    @State private var editEmp: Employee?

    private var filtered: [Employee] {
        store.employees.filter { e in
            (searchText.isEmpty || e.fullName.localizedCaseInsensitiveContains(searchText) || e.email.localizedCaseInsensitiveContains(searchText)) &&
            (deptFilter == nil || e.departmentId == deptFilter) &&
            (roleFilter == nil || e.role == roleFilter) &&
            (!showActiveOnly || e.isActive)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Employees").font(.largeTitle.bold())
                    Text("\(store.employees.count) total employees").foregroundStyle(.secondary)
                }
                Spacer()
                Button { showNew = true } label: { Label("Add Employee", systemImage: "plus").font(.headline) }
                    .buttonStyle(.borderedProminent)
            }.padding(Layout.paddingPage)

            HStack(spacing: Layout.paddingM) {
                SearchBar(text: $searchText, placeholder: "Search employees...")

                Picker("Department", selection: $deptFilter) {
                    Text("All Departments").tag(nil as UUID?)
                    Divider()
                    ForEach(store.departments) { Text($0.name).tag($0.id as UUID?) }
                }.frame(width: Layout.searchFilterWidth)

                Picker("Role", selection: $roleFilter) {
                    Text("All Roles").tag(nil as EmployeeRole?)
                    Divider()
                    ForEach(EmployeeRole.allCases) { Text($0.rawValue).tag($0 as EmployeeRole?) }
                }.frame(width: Layout.searchMinWidth)

                Toggle("Active Only", isOn: $showActiveOnly).toggleStyle(.checkbox)
                Spacer()
                if deptFilter != nil || roleFilter != nil || !searchText.isEmpty || !showActiveOnly {
                    Button("Clear") { deptFilter = nil; roleFilter = nil; searchText = ""; showActiveOnly = true }
                        .font(.caption).foregroundStyle(.blue)
                }
                Text("\(filtered.count) shown").font(.caption).foregroundStyle(.tertiary)
            }.padding(.horizontal, Layout.paddingPage).padding(.vertical, Layout.paddingM).background(.background)

            if filtered.isEmpty {
                EmptyState(
                    icon: "person.2",
                    title: "No employees found",
                    buttonTitle: "Add Employee",
                    action: { showNew = true }
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: Layout.cardMinWidth, maximum: Layout.cardMaxWidth), spacing: Layout.paddingXL)], spacing: Layout.paddingXL) {
                        ForEach(filtered) { emp in
                            EmployeeCard(employee: emp) { editEmp = emp }
                        }
                    }.padding(Layout.paddingPage)
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .sheet(isPresented: $showNew) { NewEmployeeSheet() }
        .sheet(item: $editEmp) { emp in EditEmployeeSheet(employee: emp) }
    }
}

struct EmployeeCard: View {
    @EnvironmentObject var store: AppStore
    let employee: Employee
    var onTap: () -> Void
    @State private var isHovered = false

    private var employeeTasks: [Task] { store.tasks(forEmployee: employee.id) }
    private var activeTaskCount: Int { employeeTasks.filter { $0.status != .done }.count }
    private var completedTaskCount: Int { employeeTasks.filter { $0.status == .done }.count }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Layout.paddingL) {
                HStack(spacing: Layout.paddingM) {
                    Circle().fill(Color(hex: employee.role.colorHex)).frame(width: Layout.avatarSizeXXL, height: Layout.avatarSizeXXL)
                        .overlay(Text(employee.initials).font(.headline).foregroundStyle(.white))
                    VStack(alignment: .leading) {
                        Text(employee.fullName).font(.subheadline.bold())
                        Text(employee.role.rawValue).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Circle().fill(employee.isActive ? .green : .gray).frame(width: 8, height: 8)
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) { Image(systemName: "envelope").font(.caption2).foregroundStyle(.tertiary); Text(employee.email).font(.caption).foregroundStyle(.secondary).lineLimit(1) }
                    if let dept = store.department(for: employee.departmentId) {
                        HStack(spacing: 4) { Image(systemName: "building.2").font(.caption2).foregroundStyle(.tertiary); Text(dept.name).font(.caption).foregroundStyle(.secondary) }
                    }
                }
                Divider()
                HStack(spacing: 20) {
                    VStack(alignment: .leading) { Text("\(activeTaskCount)").font(.headline); Text("Active").font(.caption).foregroundStyle(.tertiary) }
                    VStack(alignment: .leading) { Text("\(completedTaskCount)").font(.headline); Text("Completed").font(.caption).foregroundStyle(.tertiary) }
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                }
            }
            .padding(Layout.paddingL)
            .cardStyle(isHovered: isHovered)
        }.buttonStyle(.plain).onHover { isHovered = $0 }
    }
}

struct NewEmployeeSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    @State private var first = ""
    @State private var last = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var role: EmployeeRole = .technician
    @State private var deptId: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetHeader(
                title: "Add Employee",
                primaryTitle: "Add",
                primaryDisabled: first.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || last.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || !Validators.isValidEmail(email),
                onDismiss: { dismiss() },
                onPrimary: { add() }
            )
            Form {
                HStack { TextField("First Name", text: $first); TextField("Last Name", text: $last) }
                HStack { TextField("Email", text: $email); TextField("Phone", text: $phone) }
                Picker("Role", selection: $role) { ForEach(EmployeeRole.allCases) { Text($0.rawValue).tag($0) } }
                Picker("Department", selection: $deptId) { Text("Unassigned").tag(nil as UUID?); ForEach(store.departments) { Text($0.name).tag($0.id as UUID?) } }
            }.padding(Layout.paddingXXL)
        }.frame(minWidth: Layout.minSheetWidthWide, minHeight: Layout.minSheetHeightMed)
    }

    private func add() {
        let e = Employee(firstName: first.trimmingCharacters(in: .whitespacesAndNewlines),
                         lastName: last.trimmingCharacters(in: .whitespacesAndNewlines),
                         email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                         phone: phone.isEmpty ? nil : phone.trimmingCharacters(in: .whitespacesAndNewlines),
                         role: role, departmentId: deptId)
        store.addEmployee(e)
        dismiss()
    }
}

struct EditEmployeeSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    let employee: Employee
    @State private var first: String
    @State private var last: String
    @State private var email: String
    @State private var phone: String
    @State private var role: EmployeeRole
    @State private var deptId: UUID?
    @State private var isActive: Bool
    @State private var showDelete = false

    init(employee: Employee) {
        self.employee = employee
        _first = State(initialValue: employee.firstName)
        _last = State(initialValue: employee.lastName)
        _email = State(initialValue: employee.email)
        _phone = State(initialValue: employee.phone ?? "")
        _role = State(initialValue: employee.role)
        _deptId = State(initialValue: employee.departmentId)
        _isActive = State(initialValue: employee.isActive)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetHeader(
                title: "Edit Employee",
                showDestructive: true,
                destructiveTitle: "Delete",
                onDestructive: { showDelete = true },
                primaryDisabled: first.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || last.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || !Validators.isValidEmail(email),
                onDismiss: { dismiss() },
                onPrimary: { save() }
            )
            Form {
                HStack { TextField("First Name", text: $first); TextField("Last Name", text: $last) }
                HStack { TextField("Email", text: $email); TextField("Phone", text: $phone) }
                Picker("Role", selection: $role) { ForEach(EmployeeRole.allCases) { Text($0.rawValue).tag($0) } }
                Picker("Department", selection: $deptId) { Text("Unassigned").tag(nil as UUID?); ForEach(store.departments) { Text($0.name).tag($0.id as UUID?) } }
                Toggle("Active", isOn: $isActive)
            }.padding(Layout.paddingXXL)
        }.frame(minWidth: Layout.minSheetWidthWide, minHeight: Layout.minSheetHeightTall)
        .alert("Delete Employee?", isPresented: $showDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { store.deleteEmployee(employee); dismiss() }
        }
    }

    private func save() {
        var e = employee
        e.firstName = first.trimmingCharacters(in: .whitespacesAndNewlines)
        e.lastName = last.trimmingCharacters(in: .whitespacesAndNewlines)
        e.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        e.phone = phone.isEmpty ? nil : phone.trimmingCharacters(in: .whitespacesAndNewlines)
        e.role = role; e.departmentId = deptId; e.isActive = isActive; e.updatedAt = Date()
        store.updateEmployee(e)
        dismiss()
    }
}
