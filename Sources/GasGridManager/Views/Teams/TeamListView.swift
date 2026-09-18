import SwiftUI

struct TeamListView: View {
    @EnvironmentObject var store: AppStore
    @State private var searchText = ""
    @State private var showNew = false

    private var filtered: [Team] {
        store.teams.filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Teams").font(.largeTitle.bold())
                    Text("\(store.teams.count) total teams").foregroundStyle(.secondary)
                }
                Spacer()
                Button { showNew = true } label: { Label("New Team", systemImage: "plus").font(.headline) }.buttonStyle(.borderedProminent)
            }.padding(Layout.paddingPage)

            HStack(spacing: Layout.paddingM) {
                SearchBar(text: $searchText, placeholder: "Search teams...")
                Spacer()
            }.padding(.horizontal, Layout.paddingPage).padding(.vertical, Layout.paddingM).background(.background)

            if filtered.isEmpty {
                EmptyState(
                    icon: "person.3",
                    title: "No teams found",
                    buttonTitle: "Create Team",
                    action: { showNew = true }
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: Layout.paddingS) {
                        ForEach(filtered) { team in TeamRow(team: team) }
                    }.padding(Layout.paddingPage)
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .sheet(isPresented: $showNew) { NewTeamSheet() }
    }
}

struct TeamRow: View {
    @EnvironmentObject var store: AppStore
    let team: Team
    @State private var showDetail = false
    @State private var isHovered = false

    private var teamColor: Color {
        if let dept = store.department(for: team.departmentId) {
            return Color(hex: dept.colorHex)
        }
        return .blue
    }

    private var memberIDs: Set<UUID> {
        Set(store.members(of: team.id).map(\.id))
    }

    private var activeTaskCount: Int {
        let ids = memberIDs
        return store.tasks.filter { ids.contains($0.assigneeId ?? UUID()) && $0.status != .done }.count
    }

    var body: some View {
        Button { showDetail = true } label: {
            HStack(spacing: Layout.paddingXL) {
                Image(systemName: "person.3.fill")
                    .font(.title3)
                    .foregroundStyle(teamColor)
                    .frame(width: Layout.avatarSizeXXL, height: Layout.avatarSizeXXL)
                    .background(teamColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadiusM))
                VStack(alignment: .leading) {
                    Text(team.name).font(.subheadline.bold())
                    if let dept = store.department(for: team.departmentId) { Text(dept.name).font(.caption).foregroundStyle(.secondary) }
                }
                Spacer()
                HStack(spacing: 24) {
                    VStack { Text("\(memberIDs.count)").font(.headline); Text("Members").font(.caption).foregroundStyle(.tertiary) }
                    VStack { Text("\(activeTaskCount)").font(.headline); Text("Tasks").font(.caption).foregroundStyle(.tertiary) }
                }
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
            }
            .padding(Layout.paddingL)
            .cardStyle(isHovered: isHovered)
        }.buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .sheet(isPresented: $showDetail) { TeamDetailSheet(team: team) }
    }
}

struct NewTeamSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var deptId: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetHeader(
                title: "New Team",
                primaryTitle: "Create",
                primaryDisabled: name.isEmpty,
                onDismiss: { dismiss() },
                onPrimary: { create() }
            )
            Form {
                TextField("Team Name", text: $name)
                Picker("Department", selection: $deptId) { Text("Unassigned").tag(nil as UUID?); ForEach(store.departments) { Text($0.name).tag($0.id as UUID?) } }
            }.padding(Layout.paddingXXL)
        }.frame(minWidth: Layout.minSheetWidth, minHeight: Layout.minSheetHeight)
    }

    private func create() { store.addTeam(Team(name: name, departmentId: deptId)); dismiss() }
}

struct TeamDetailSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    let team: Team
    @State private var editMode = false
    @State private var name: String
    @State private var deptId: UUID?
    @State private var showDelete = false

    init(team: Team) { self.team = team; _name = State(initialValue: team.name); _deptId = State(initialValue: team.departmentId) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                if editMode {
                    Button("Cancel") { editMode = false; name = team.name; deptId = team.departmentId }
                        .buttonStyle(.bordered)
                }
                Spacer()
                if editMode {
                    Button("Delete", role: .destructive) { showDelete = true }.buttonStyle(.bordered)
                    Button("Save") { save() }.buttonStyle(.borderedProminent)
                } else {
                    Button("Edit") { editMode = true }.buttonStyle(.borderedProminent)
                    Button("Done") { dismiss() }.buttonStyle(.bordered)
                }
            }.padding(Layout.paddingXXL)
            Divider()
            Form {
                TextField("Name", text: $name).disabled(!editMode)
                Picker("Department", selection: $deptId) {
                    Text("Unassigned").tag(nil as UUID?)
                    ForEach(store.departments) { Text($0.name).tag($0.id as UUID?) }
                }
                .disabled(!editMode)
            }.padding(Layout.paddingXXL)
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                let members = store.members(of: team.id)
                Text("Members (\(members.count))").font(.headline).padding(.horizontal, Layout.paddingXXL)
                ForEach(members) { m in
                    HStack(spacing: Layout.paddingM) {
                        Circle().fill(Color(hex: m.role.colorHex)).frame(width: Layout.avatarSizeLarge, height: Layout.avatarSizeLarge).overlay(Text(m.initials).font(.caption).foregroundStyle(.white))
                        VStack(alignment: .leading) { Text(m.fullName).font(.subheadline.bold()); Text(m.role.rawValue).font(.caption).foregroundStyle(.tertiary) }
                        Spacer()
                        if editMode {
                            Button { var e = m; e.teamId = nil; store.updateEmployee(e) } label: { Image(systemName: "xmark.circle").foregroundStyle(.tertiary) }.buttonStyle(.plain)
                        }
                    }.padding(.horizontal, Layout.paddingXXL).padding(.vertical, 6)
                }
            }
        }.frame(minWidth: 450, minHeight: Layout.minSheetHeightDetail)
        .alert("Delete Team?", isPresented: $showDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { store.deleteTeam(team); dismiss() }
        }
    }

    private func save() {
        var t = team; t.name = name; t.departmentId = deptId; store.updateTeam(t)
        editMode = false
    }
}
