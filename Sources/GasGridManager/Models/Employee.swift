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

    var icon: String {
        switch self {
        case .manager: return "person.line.dashed.person"
        case .supervisor: return "person.badge.shield"
        case .technician: return "wrench.and.screwdriver"
        case .engineer: return "gearshape.2"
        case .safetyOfficer: return "shield.checkered"
        case .administrator: return "person.badge.key"
        case .fieldOperator: return "figure.walk"
        case .dispatcher: return "radio"
        case .qualityInspector: return "checkmark.seal"
        }
    }

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
    var phone: String?
    var role: EmployeeRole
    var departmentId: UUID?
    var teamId: UUID?
    var isActive: Bool
    var joinDate: Date
    var createdAt: Date
    var updatedAt: Date

    var fullName: String { "\(firstName) \(lastName)" }

    var initials: String {
        let f = String(firstName.prefix(1))
        let l = String(lastName.prefix(1))
        return "\(f)\(l)".uppercased()
    }

    init(firstName: String, lastName: String, email: String, phone: String? = nil, role: EmployeeRole = .technician, departmentId: UUID? = nil, teamId: UUID? = nil) {
        self.id = UUID()
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.role = role
        self.departmentId = departmentId
        self.teamId = teamId
        self.isActive = true
        self.joinDate = Date()
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
