import Foundation
import SwiftUI
import os.log

private let logger = Logger(subsystem: "GasGridManager", category: "AppStore")

// MARK: - App Store (Central Data Manager)
@MainActor
final class AppStore: ObservableObject {
    static let shared = AppStore()

    @Published var employees: [Employee] = []
    @Published var tasks: [Task] = []
    @Published var departments: [Department] = []
    @Published var teams: [Team] = []
    @Published var projects: [Project] = []

    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private lazy var storageURL: URL = {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("GasGridManager", isDirectory: true)
        do {
            try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        } catch {
            logger.error("Failed to create storage directory: \(error.localizedDescription)")
        }
        return dir
    }()

    // MARK: - Lookup Caches (rebuilt on data changes)
    private var employeeIndex: [UUID: Employee] = [:]
    private var departmentIndex: [UUID: Department] = [:]
    private var teamIndex: [UUID: Team] = [:]
    private var projectIndex: [UUID: Project] = [:]
    private var tasksByAssignee: [UUID: [Task]] = [:]
    private var tasksByProject: [UUID: [Task]] = [:]
    private var membersByTeam: [UUID: [Employee]] = [:]
    private var employeesByDepartment: [UUID: [Employee]] = [:]

    private init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        loadAll()
    }

    // MARK: - Persistence

    private func save<T: Encodable>(_ items: [T], to filename: String) {
        let url = storageURL.appendingPathComponent(filename)
        do {
            let data = try encoder.encode(items)
            try data.write(to: url, options: .atomic)
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o600],
                ofItemAtPath: url.path
            )
        } catch {
            logger.error("Failed to save \(filename): \(error.localizedDescription)")
        }
    }

    private func load<T: Decodable>(_ type: T.Type, from filename: String) -> [T] {
        let url = storageURL.appendingPathComponent(filename)
        do {
            let data = try Data(contentsOf: url)
            let items = try decoder.decode([T].self, from: data)
            return items
        } catch {
            logger.warning("Failed to load \(filename): \(error.localizedDescription)")
            return []
        }
    }

    func loadAll() {
        departments = load(Department.self, from: "departments.json")
        teams = load(Team.self, from: "teams.json")
        employees = load(Employee.self, from: "employees.json")
        tasks = load(Task.self, from: "tasks.json")
        projects = load(Project.self, from: "projects.json")
        rebuildIndices()
    }

    func saveAll() {
        save(departments, to: "departments.json")
        save(teams, to: "teams.json")
        save(employees, to: "employees.json")
        save(tasks, to: "tasks.json")
        save(projects, to: "projects.json")
    }

    // MARK: - Reset

    func resetToSampleData() {
        employees.removeAll()
        tasks.removeAll()
        departments.removeAll()
        teams.removeAll()
        projects.removeAll()
        saveAll()
        loadSampleData()
    }

    // MARK: - Index Management

    private func rebuildIndices() {
        employeeIndex = Dictionary(uniqueKeysWithValues: employees.map { ($0.id, $0) })
        departmentIndex = Dictionary(uniqueKeysWithValues: departments.map { ($0.id, $0) })
        teamIndex = Dictionary(uniqueKeysWithValues: teams.map { ($0.id, $0) })
        projectIndex = Dictionary(uniqueKeysWithValues: projects.map { ($0.id, $0) })

        tasksByAssignee = [:]
        for task in tasks {
            if let assigneeId = task.assigneeId {
                tasksByAssignee[assigneeId, default: []].append(task)
            }
        }
        tasksByProject = Dictionary(grouping: tasks.filter { $0.projectId != nil }) { $0.projectId! }
        membersByTeam = Dictionary(grouping: employees.filter { $0.teamId != nil && $0.isActive }) { $0.teamId! }
        employeesByDepartment = Dictionary(grouping: employees.filter { $0.departmentId != nil && $0.isActive }) { $0.departmentId! }
    }

    // MARK: - Lookup Helpers (O(1))

    func department(for id: UUID?) -> Department? {
        guard let id else { return nil }
        return departmentIndex[id]
    }

    func team(for id: UUID?) -> Team? {
        guard let id else { return nil }
        return teamIndex[id]
    }

    func employee(for id: UUID?) -> Employee? {
        guard let id else { return nil }
        return employeeIndex[id]
    }

    func project(for id: UUID?) -> Project? {
        guard let id else { return nil }
        return projectIndex[id]
    }

    func tasks(forEmployee employeeId: UUID) -> [Task] {
        tasksByAssignee[employeeId] ?? []
    }

    func tasks(forProject projectId: UUID) -> [Task] {
        tasksByProject[projectId] ?? []
    }

    func members(of teamId: UUID) -> [Employee] {
        membersByTeam[teamId] ?? []
    }

    func employees(in departmentId: UUID) -> [Employee] {
        employeesByDepartment[departmentId] ?? []
    }

    // MARK: - Mutation

    func addEmployee(_ employee: Employee) {
        employees.append(employee)
        rebuildIndices()
        save(employees, to: "employees.json")
    }

    func updateEmployee(_ employee: Employee) {
        if let idx = employees.firstIndex(where: { $0.id == employee.id }) {
            employees[idx] = employee
            rebuildIndices()
            save(employees, to: "employees.json")
        }
    }

    func deleteEmployee(_ employee: Employee) {
        employees.removeAll { $0.id == employee.id }
        for i in tasks.indices where tasks[i].assigneeId == employee.id {
            tasks[i].assigneeId = nil
        }
        rebuildIndices()
        save(employees, to: "employees.json")
        save(tasks, to: "tasks.json")
    }

    func addTask(_ task: Task) {
        tasks.append(task)
        rebuildIndices()
        save(tasks, to: "tasks.json")
    }

    func updateTask(_ task: Task) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx] = task
            rebuildIndices()
            save(tasks, to: "tasks.json")
        }
    }

    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        rebuildIndices()
        save(tasks, to: "tasks.json")
    }

    func addDepartment(_ department: Department) {
        departments.append(department)
        rebuildIndices()
        save(departments, to: "departments.json")
    }

    func updateDepartment(_ department: Department) {
        if let idx = departments.firstIndex(where: { $0.id == department.id }) {
            departments[idx] = department
            rebuildIndices()
            save(departments, to: "departments.json")
        }
    }

    func deleteDepartment(_ department: Department) {
        departments.removeAll { $0.id == department.id }
        for i in teams.indices where teams[i].departmentId == department.id {
            teams[i].departmentId = nil
        }
        for i in employees.indices where employees[i].departmentId == department.id {
            employees[i].departmentId = nil
        }
        rebuildIndices()
        save(departments, to: "departments.json")
        save(teams, to: "teams.json")
        save(employees, to: "employees.json")
    }

    func addTeam(_ team: Team) {
        teams.append(team)
        rebuildIndices()
        save(teams, to: "teams.json")
    }

    func updateTeam(_ team: Team) {
        if let idx = teams.firstIndex(where: { $0.id == team.id }) {
            teams[idx] = team
            rebuildIndices()
            save(teams, to: "teams.json")
        }
    }

    func deleteTeam(_ team: Team) {
        teams.removeAll { $0.id == team.id }
        for i in employees.indices where employees[i].teamId == team.id {
            employees[i].teamId = nil
        }
        rebuildIndices()
        save(teams, to: "teams.json")
        save(employees, to: "employees.json")
    }

    func addProject(_ project: Project) {
        projects.append(project)
        rebuildIndices()
        save(projects, to: "projects.json")
    }

    func updateProject(_ project: Project) {
        if let idx = projects.firstIndex(where: { $0.id == project.id }) {
            projects[idx] = project
            rebuildIndices()
            save(projects, to: "projects.json")
        }
    }

    func deleteProject(_ project: Project) {
        projects.removeAll { $0.id == project.id }
        for i in tasks.indices where tasks[i].projectId == project.id {
            tasks[i].projectId = nil
        }
        rebuildIndices()
        save(projects, to: "projects.json")
        save(tasks, to: "tasks.json")
    }

    // MARK: - Sample Data

    func loadSampleData() {
        guard employees.isEmpty else { return }

        let deptData: [(name: String, desc: String, color: String)] = [
            ("Operations", "Pipeline management and gas distribution operations", "059669"),
            ("Maintenance", "Equipment repair and preventive maintenance", "0284C7"),
            ("Safety", "Inspections, compliance, and incident reporting", "DC2626"),
            ("Engineering", "Design, planning, and technical support", "7C3AED"),
            ("Customer Service", "Billing, complaints, and service requests", "D97706"),
            ("Administration", "HR, finance, and general management", "64748B")
        ]
        departments = deptData.map { Department(name: $0.name, description: $0.desc, colorHex: $0.color) }

        let teamData: [(name: String, deptIdx: Int)] = [
            ("Pipeline Alpha", 0),
            ("Pipeline Beta", 0),
            ("Mechanical Crew", 1),
            ("Safety Team", 2),
            ("Design Group", 3)
        ]
        teams = teamData.map { Team(name: $0.name, departmentId: departments[safe: $0.deptIdx]?.id) }

        let empData: [(first: String, last: String, email: String, role: EmployeeRole, deptIdx: Int, teamIdx: Int?)] = [
            ("John", "Smith", "john.smith@gasgrid.com", .manager, 0, nil),
            ("Sarah", "Chen", "sarah.chen@gasgrid.com", .supervisor, 0, 0),
            ("Mike", "Johnson", "mike.johnson@gasgrid.com", .technician, 1, 2),
            ("Jane", "Doe", "jane.doe@gasgrid.com", .engineer, 3, 4),
            ("David", "Williams", "david.williams@gasgrid.com", .safetyOfficer, 2, 3),
            ("Emily", "Brown", "emily.brown@gasgrid.com", .fieldOperator, 0, 1),
            ("Chris", "Davis", "chris.davis@gasgrid.com", .dispatcher, 4, nil),
            ("Lisa", "Wilson", "lisa.wilson@gasgrid.com", .qualityInspector, 1, 2),
            ("Robert", "Taylor", "robert.taylor@gasgrid.com", .administrator, 5, nil),
            ("Amanda", "Anderson", "amanda.anderson@gasgrid.com", .technician, 1, 2),
            ("James", "Martinez", "james.martinez@gasgrid.com", .fieldOperator, 0, 0),
            ("Maria", "Garcia", "maria.garcia@gasgrid.com", .supervisor, 0, 1)
        ]
        employees = empData.map {
            var e = Employee(firstName: $0.first, lastName: $0.last, email: $0.email, role: $0.role)
            e.departmentId = departments[safe: $0.deptIdx]?.id
            e.teamId = $0.teamIdx.flatMap { teams[safe: $0]?.id }
            return e
        }

        let taskData: [(title: String, priority: TaskPriority, status: TaskStatus, category: TaskCategory, empIdx: Int, projIdx: Int?)] = [
            ("Pipeline Inspection - Zone A", .high, .inProgress, .pipelineInspection, 0, 0),
            ("Equipment Maintenance - Compressor Station", .critical, .todo, .equipmentMaintenance, 2, 3),
            ("Safety Compliance Audit Q4", .high, .review, .safetyCompliance, 4, 1),
            ("Customer Service - Billing Inquiry", .low, .done, .customerService, 6, 2),
            ("Emergency Response Drill", .medium, .todo, .emergencyResponse, 3, 1),
            ("Documentation Update - SOP Manual", .medium, .inProgress, .documentation, 8, nil),
            ("Safety Training Session", .high, .todo, .training, 4, 1),
            ("Project: Pipeline Extension Phase 1", .critical, .inProgress, .projectWork, 1, 0),
            ("Equipment Calibration", .medium, .review, .equipmentMaintenance, 7, 3),
            ("Customer Complaint Resolution", .high, .inProgress, .customerService, 6, 2),
            ("Night Shift Handover Checklist", .low, .done, .documentation, 5, nil),
            ("Pipeline Pressure Testing", .critical, .todo, .pipelineInspection, 2, 0)
        ]
        let cal = Calendar.current
        tasks = taskData.enumerated().map { i, d in
            var t = Task(title: d.title, priority: d.priority, category: d.category, dueDate: cal.date(byAdding: .day, value: i - 5, to: Date()), assigneeId: employees[safe: d.empIdx]?.id, projectId: d.projIdx.flatMap { projects[safe: $0]?.id })
            t.status = d.status
            if d.status == .done { t.completedAt = cal.date(byAdding: .day, value: -1, to: Date()) }
            return t
        }

        let projData: [(name: String, desc: String)] = [
            ("Pipeline Extension 2025", "Extend gas pipeline network to new industrial zone"),
            ("Safety Upgrade Initiative", "Upgrade safety systems across all facilities"),
            ("Customer Portal Development", "Develop online customer self-service portal"),
            ("Maintenance Automation", "Implement automated maintenance scheduling")
        ]
        projects = projData.map { Project(name: $0.name, description: $0.desc) }

        rebuildIndices()
        saveAll()
    }
}

// MARK: - Safe Array Subscript
extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
