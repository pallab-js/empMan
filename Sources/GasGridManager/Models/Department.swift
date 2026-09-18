import Foundation

// MARK: - Department
struct Department: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String?
    var colorHex: String
    var createdAt: Date
    var updatedAt: Date

    init(name: String, description: String? = nil, colorHex: String = "1E40AF") {
        self.id = UUID()
        self.name = name
        self.description = description
        self.colorHex = colorHex
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Team
struct Team: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var departmentId: UUID?
    var createdAt: Date

    init(name: String, departmentId: UUID? = nil) {
        self.id = UUID()
        self.name = name
        self.departmentId = departmentId
        self.createdAt = Date()
    }
}

// MARK: - Project Status
enum ProjectStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case active = "Active"
    case onHold = "On Hold"
    case completed = "Completed"
    case archived = "Archived"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .active: return "play.circle.fill"
        case .onHold: return "pause.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .archived: return "archivebox"
        }
    }

    var colorHex: String {
        switch self {
        case .active: return "059669"
        case .onHold: return "D97706"
        case .completed: return "0284C7"
        case .archived: return "64748B"
        }
    }
}

// MARK: - Project
struct Project: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String?
    var startDate: Date
    var endDate: Date?
    var status: ProjectStatus
    var createdAt: Date
    var updatedAt: Date

    init(name: String, description: String? = nil, startDate: Date = Date(), endDate: Date? = nil) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.status = .active
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
