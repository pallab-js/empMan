import Foundation

enum NavigationItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case tasks = "Tasks"
    case employees = "Employees"
    case departments = "Departments"
    case teams = "Teams"
    case projects = "Projects"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard: return "chart.pie"
        case .tasks: return "checklist"
        case .employees: return "person.2"
        case .departments: return "building.2"
        case .teams: return "person.3"
        case .projects: return "folder"
        case .settings: return "gear"
        }
    }

    var selectedIcon: String {
        switch self {
        case .dashboard: return "chart.pie.fill"
        case .tasks: return "checklist.checked"
        case .employees: return "person.2.fill"
        case .departments: return "building.2.fill"
        case .teams: return "person.3.fill"
        case .projects: return "folder.fill"
        case .settings: return "gear.fill"
        }
    }
}
