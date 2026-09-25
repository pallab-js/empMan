import XCTest
@testable import GasGridManager

@MainActor
final class AppStoreTests: XCTestCase {
    private var dir: URL!

    override func setUpWithError() throws {
        dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppStoreTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: dir)
    }

    // MARK: - Sample data

    func testSampleDataLinksTasksToProjects() {
        let store = AppStore(storageDirectory: dir)
        store.loadSampleData()

        XCTAssertFalse(store.projects.isEmpty, "sample data should include projects")
        let linked = store.tasks.filter { $0.projectId != nil }
        XCTAssertFalse(linked.isEmpty, "sample tasks should reference sample projects")
        for task in linked {
            XCTAssertNotNil(store.project(for: task.projectId), "dangling projectId must resolve")
        }
    }

    func testSampleDataSeedsOnlyIntoAFullyEmptyStore() {
        let store = AppStore(storageDirectory: dir)
        store.addDepartment(Department(name: "Real Dept"))

        store.loadSampleData()

        XCTAssertEqual(store.departments.count, 1, "existing departments must not be replaced/duplicated")
        XCTAssertTrue(store.employees.isEmpty, "sample employees must not mix with real data")
    }

    func testResetToSampleDataReplacesEverything() {
        let store = AppStore(storageDirectory: dir)
        store.addEmployee(Employee(firstName: "Ada", lastName: "Lovelace", email: "ada@real.com"))

        store.resetToSampleData()

        XCTAssertFalse(store.employees.isEmpty)
        XCTAssertFalse(store.departments.isEmpty)
        XCTAssertFalse(store.projects.isEmpty)
        XCTAssertFalse(store.employees.contains { $0.email == "ada@real.com" })
    }

    // MARK: - Robustness

    func testDuplicateEmployeeIDsDoNotCrashIndexRebuild() throws {
        let id = UUID()
        let employees = [
            Employee(id: id, firstName: "One", lastName: "User", email: "one@example.com"),
            Employee(id: id, firstName: "Two", lastName: "User", email: "two@example.com")
        ]
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(employees).write(to: dir.appendingPathComponent("employees.json"))

        let store = AppStore(storageDirectory: dir)

        XCTAssertEqual(store.employees.count, 2)
        XCTAssertNotNil(store.employee(for: id))
    }

    func testUndecodableFileIsPreservedAsBackup() throws {
        try Data("not json {".utf8).write(to: dir.appendingPathComponent("employees.json"))

        let store = AppStore(storageDirectory: dir)

        XCTAssertTrue(store.employees.isEmpty)
        let backup = dir.appendingPathComponent("employees.json.invalid")
        XCTAssertTrue(FileManager.default.fileExists(atPath: backup.path), "corrupt data must be backed up, not discarded")
    }

    func testStorageDirectoryIsRestrictedToCurrentUser() throws {
        _ = AppStore(storageDirectory: dir)

        let attrs = try FileManager.default.attributesOfItem(atPath: dir.path)
        let permissions = (attrs[.posixPermissions] as? NSNumber)?.intValue ?? -1
        XCTAssertEqual(permissions & 0o777, 0o700, "directory holding PII must not be world-accessible")
    }

    // MARK: - Referential cleanup

    func testDeleteDepartmentClearsTeamAndEmployeeReferences() {
        let store = AppStore(storageDirectory: dir)
        let dept = Department(name: "Operations")
        store.addDepartment(dept)
        store.addTeam(Team(name: "Alpha", departmentId: dept.id))
        store.addEmployee(Employee(firstName: "Eve", lastName: "Vega", email: "eve@example.com", departmentId: dept.id))

        store.deleteDepartment(dept)

        XCTAssertNil(store.department(for: dept.id))
        XCTAssertNil(store.teams.first?.departmentId)
        XCTAssertNil(store.employees.first?.departmentId)
    }

    func testDeleteEmployeeUnassignsTheirTasks() {
        let store = AppStore(storageDirectory: dir)
        let employee = Employee(firstName: "Sam", lastName: "Rivera", email: "sam@example.com")
        store.addEmployee(employee)
        store.addTask(Task(title: "Inspect valve", assigneeId: employee.id))

        store.deleteEmployee(employee)

        XCTAssertNil(store.employee(for: employee.id))
        XCTAssertNil(store.tasks.first?.assigneeId, "tasks must not keep dangling assignee references")
    }

    // MARK: - Export

    func testExportDataRoundTripsAllCollections() throws {
        let store = AppStore(storageDirectory: dir)
        store.loadSampleData()

        let data = try store.exportData()
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let bundle = try decoder.decode(ExportBundle.self, from: data)

        XCTAssertEqual(bundle.employees.count, store.employees.count)
        XCTAssertEqual(bundle.tasks.count, store.tasks.count)
        XCTAssertEqual(bundle.departments.count, store.departments.count)
        XCTAssertEqual(bundle.teams.count, store.teams.count)
        XCTAssertEqual(bundle.projects.count, store.projects.count)
    }
}
