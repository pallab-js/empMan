import Foundation

// MARK: - Employee Role
enum EmployeeRole: String, Codable, CaseIterable, Identifiable, Sendable {
    case manager = "Manager"
    case supervisor = "Supervisor"
    case technician = "Technician"
    case engineer = "Engineer"
    case safetyOfficer = "Safety Officer"
    case administrator = "Administrator"
    case fieldOperator = "Field Operator"
    case dispatcher = "Dispatcher"
    case qualityInspector = "Quality Inspector"

    var id: String { rawValue }

    var colorHex: String {
        switch self {
        case .manager: return "1E40AF"
        case .supervisor: return "7C3AED"
        case .technician: return "059669"
        case .engineer: return "0284C7"
        case .safetyOfficer: return "DC2626"
        case .administrator: return "D97706"
        case .fieldOperator: return "0891B2"
        case .dispatcher: return "C2410C"
        case .qualityInspector: return "4F46E5"
        }
    }
}

// MARK: - Employee
struct Employee: Identifiable, Codable, Hashable {
    let id: UUID
    var firstName: String
    var lastName: String
    var email: String
    var role: EmployeeRole
    var departmentId: UUID?
    var teamId: UUID?
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date

    var fullName: String { "\(firstName) \(lastName)" }

    var initials: String {
        let f = String(firstName.prefix(1))
        let l = String(lastName.prefix(1))
        return "\(f)\(l)".uppercased()
    }

    init(firstName: String, lastName: String, email: String, role: EmployeeRole = .technician, departmentId: UUID? = nil, teamId: UUID? = nil) {
        self.id = UUID()
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.role = role
        self.departmentId = departmentId
        self.teamId = teamId
        self.isActive = true
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
