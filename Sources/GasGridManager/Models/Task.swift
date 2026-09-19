import Foundation

// MARK: - Task Priority
enum TaskPriority: String, Codable, CaseIterable, Identifiable, Sendable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"

    var id: String { rawValue }

    var colorHex: String {
        switch self {
        case .low: return "059669"
        case .medium: return "0284C7"
        case .high: return "D97706"
        case .critical: return "DC2626"
        }
    }
}

// MARK: - Task Status
enum TaskStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case todo = "To Do"
    case inProgress = "In Progress"
    case review = "Review"
    case done = "Done"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .todo: return "circle"
        case .inProgress: return "arrow.triangle.2.circlepath"
        case .review: return "magnifyingglass"
        case .done: return "checkmark.circle.fill"
        }
    }

    var colorHex: String {
        switch self {
        case .todo: return "64748B"
        case .inProgress: return "0284C7"
        case .review: return "D97706"
        case .done: return "059669"
        }
    }
}

// MARK: - Task Category
enum TaskCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case pipelineInspection = "Pipeline Inspection"
    case equipmentMaintenance = "Equipment Maintenance"
    case safetyCompliance = "Safety Compliance"
    case customerService = "Customer Service"
    case emergencyResponse = "Emergency Response"
    case documentation = "Documentation"
    case training = "Training"
    case projectWork = "Project Work"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .pipelineInspection: return "pipe.and.stethoscope"
        case .equipmentMaintenance: return "wrench.and.screwdriver"
        case .safetyCompliance: return "shield.checkered"
        case .customerService: return "person.2.circle"
        case .emergencyResponse: return "exclamationmark.triangle"
        case .documentation: return "doc.text"
        case .training: return "book.closed"
        case .projectWork: return "folder.badge.gearshape"
        }
    }
}

// MARK: - Task
struct Task: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var description: String?
    var priority: TaskPriority
    var status: TaskStatus
    var category: TaskCategory
    var dueDate: Date?
    var completedAt: Date?
    var assigneeId: UUID?
    var projectId: UUID?
    var createdAt: Date
    var updatedAt: Date

    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return dueDate < Date() && status != .done
    }

    init(title: String, description: String? = nil, priority: TaskPriority = .medium, category: TaskCategory = .projectWork, dueDate: Date? = nil, assigneeId: UUID? = nil, projectId: UUID? = nil) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.priority = priority
        self.status = .todo
        self.category = category
        self.dueDate = dueDate
        self.assigneeId = assigneeId
        self.projectId = projectId
        self.createdAt = Date()
        self.updatedAt = Date()
        self.completedAt = nil
    }
}
