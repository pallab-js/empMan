import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var store: AppStore
    @AppStorage("enableAnimations") private var enableAnimations = true

    private var stats: DashboardStats {
        DashboardStats(store: store)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.paddingXXL) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Dashboard")
                            .font(.largeTitle.bold())
                        if stats.isSampleData {
                            Text("Sample Data")
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(.orange.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                    Text("Welcome back. Here's what's happening with your operations.")
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: Layout.paddingXL) {
                    StatCard(
                        title: "Active Employees",
                        value: "\(stats.activeEmployees)",
                        icon: "person.2.fill",
                        color: .blue,
                        trendValue: stats.activeEmployees,
                        trendLabel: "total"
                    )
                    StatCard(
                        title: "Active Tasks",
                        value: "\(stats.activeTasks)",
                        icon: "checklist",
                        color: .cyan,
                        trendValue: stats.recentCompleted,
                        trendLabel: "completed this week"
                    )
                    StatCard(
                        title: "Completion Rate",
                        value: "\(Int(stats.completionRate * 100))%",
                        icon: "chart.pie.fill",
                        color: .green,
                        trendValue: stats.recentCompleted,
                        trendLabel: "done this week"
                    )
                    StatCard(
                        title: "Overdue",
                        value: "\(stats.overdueTasks)",
                        icon: "exclamationmark.triangle.fill",
                        color: .red,
                        trendValue: stats.recentOverdue,
                        trendLabel: "new this week",
                        invertTrend: true
                    )
                }

                HStack(alignment: .top, spacing: Layout.paddingXL) {
                    TaskDistributionChart()
                        .frame(maxWidth: .infinity)
                    WeeklyTrendChart()
                        .frame(maxWidth: .infinity)
                }

                HStack(alignment: .top, spacing: Layout.paddingXL) {
                    TopPerformersView()
                        .frame(maxWidth: .infinity)
                    RecentActivityView()
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(Layout.paddingPage)
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

// MARK: - Cached Dashboard Statistics
@MainActor
private struct DashboardStats {
    let activeEmployees: Int
    let activeTasks: Int
    let completedTasks: Int
    let overdueTasks: Int
    let completionRate: Double
    let recentCompleted: Int
    let recentOverdue: Int
    let isSampleData: Bool

    init(store: AppStore) {
        let now = Date()
        let weekAgo = Calendar.current.date(byAdding: .day, value: -Layout.weekDays, to: now)!

        var activeEmp = 0
        var activeT = 0
        var completedT = 0
        var overdueT = 0
        var recentComp = 0
        var recentOver = 0

        for emp in store.employees where emp.isActive { activeEmp += 1 }

        for task in store.tasks {
            if task.status != .done { activeT += 1 }
            if task.status == .done { completedT += 1 }
            if task.isOverdue { overdueT += 1 }
            if let completed = task.completedAt, completed >= weekAgo { recentComp += 1 }
            if task.isOverdue && task.createdAt >= weekAgo { recentOver += 1 }
        }

        self.activeEmployees = activeEmp
        self.activeTasks = activeT
        self.completedTasks = completedT
        self.overdueTasks = overdueT
        self.completionRate = store.tasks.isEmpty ? 0 : Double(completedT) / Double(store.tasks.count)
        self.recentCompleted = recentComp
        self.recentOverdue = recentOver
        self.isSampleData = store.employees.contains { $0.email.hasSuffix("@gasgrid.com") }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trendValue: Int
    let trendLabel: String
    var invertTrend = false
    @State private var isHovered = false

    private var isPositiveTrend: Bool {
        invertTrend ? trendValue == 0 : trendValue > 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.paddingL) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadiusS))
                Spacer()
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundStyle(.tertiary)
                Text(value).font(.system(.largeTitle, design: .rounded).bold())
            }
            HStack(spacing: 4) {
                Image(systemName: isPositiveTrend ? "arrow.up" : "arrow.down")
                    .font(.caption2.bold())
                    .foregroundStyle(isPositiveTrend ? .green : .red)
                Text("\(trendValue) \(trendLabel)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(Layout.paddingXL)
        .cardStyle(isHovered: isHovered)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Task Distribution Pie Chart
struct TaskDistributionChart: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.paddingL) {
            Text("Task Distribution").font(.headline)
            let data: [(status: TaskStatus, count: Int)] = {
                var counts: [TaskStatus: Int] = [:]
                for task in store.tasks {
                    counts[task.status, default: 0] += 1
                }
                return counts.map { (status: $0.key, count: $0.value) }.filter { $0.count > 0 }
            }()

            if data.isEmpty {
                Text("No tasks yet").foregroundStyle(.tertiary).frame(height: 200)
            } else {
                Chart(data, id: \.status) { item in
                    SectorMark(angle: .value("Count", item.count), innerRadius: .ratio(0.6))
                        .foregroundStyle(Color(hex: item.status.colorHex))
                        .annotation(position: .overlay) {
                            if item.count > 0 {
                                Text("\(item.count)").font(.caption2.bold()).foregroundStyle(.white)
                            }
                        }
                }
                .frame(height: 200)
            }

            HStack(spacing: 16) {
                ForEach(TaskStatus.allCases) { s in
                    HStack(spacing: 4) {
                        Circle().fill(Color(hex: s.colorHex)).frame(width: 8, height: 8)
                        Text(s.rawValue).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(Layout.paddingXL)
        .cardStyle()
    }
}

// MARK: - Weekly Trend Line Chart
struct WeeklyTrendChart: View {
    @EnvironmentObject var store: AppStore

    struct DayData: Identifiable {
        let id = UUID()
        let date: Date
        let created: Int
        let completed: Int
    }

    private var trendData: [DayData] {
        let cal = Calendar.current
        let now = Date()
        return (0..<Layout.weekDays).reversed().map { daysAgo in
            let date = cal.date(byAdding: .day, value: -daysAgo, to: now)!
            let start = cal.startOfDay(for: date)
            let end = cal.date(bySettingHour: 23, minute: 59, second: 59, of: date)!
            var created = 0
            var completed = 0
            for task in store.tasks {
                if task.createdAt >= start && task.createdAt <= end { created += 1 }
                if let c = task.completedAt, c >= start && c <= end { completed += 1 }
            }
            return DayData(date: date, created: created, completed: completed)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.paddingL) {
            Text("Weekly Trend").font(.headline)
            Chart(trendData) { item in
                LineMark(x: .value("Day", item.date, unit: .day), y: .value("Created", item.created))
                    .foregroundStyle(.blue)
                    .symbol(Circle().strokeBorder(lineWidth: 2))
                LineMark(x: .value("Day", item.date, unit: .day), y: .value("Completed", item.completed))
                    .foregroundStyle(.green)
                    .symbol(Circle().strokeBorder(lineWidth: 2))
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let d = value.as(Date.self) {
                            Text(d, format: .dateTime.weekday(.abbreviated)).font(.caption)
                        }
                    }
                }
            }
            HStack(spacing: 16) {
                HStack(spacing: 4) { Circle().fill(.blue).frame(width: 8, height: 8); Text("Created").font(.caption).foregroundStyle(.secondary) }
                HStack(spacing: 4) { Circle().fill(.green).frame(width: 8, height: 8); Text("Completed").font(.caption).foregroundStyle(.secondary) }
            }
        }
        .padding(Layout.paddingXL)
        .cardStyle()
    }
}

// MARK: - Top Performers
struct TopPerformersView: View {
    @EnvironmentObject var store: AppStore

    private var topPerformers: [(employee: Employee, completed: Int)] {
        var completedCounts: [UUID: Int] = [:]
        for task in store.tasks where task.status == .done {
            if let assigneeId = task.assigneeId {
                completedCounts[assigneeId, default: 0] += 1
            }
        }
        return store.employees.filter(\.isActive).compactMap { emp in
            guard let count = completedCounts[emp.id], count > 0 else { return nil }
            return (emp, count)
        }.sorted { $0.completed > $1.completed }.prefix(Layout.maxRecentActivity).map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.paddingL) {
            Text("Top Performers").font(.headline)
            if topPerformers.isEmpty {
                Text("No performance data").foregroundStyle(.tertiary).frame(maxWidth: .infinity, minHeight: 150)
            } else {
                VStack(spacing: Layout.paddingS) {
                    ForEach(Array(topPerformers.enumerated()), id: \.element.employee.id) { idx, p in
                        HStack(spacing: Layout.paddingM) {
                            Text("\(idx + 1)").font(.headline).foregroundStyle(.tertiary).frame(width: 24)
                            Circle().fill(Color(hex: p.employee.role.colorHex)).frame(width: Layout.avatarSizeXL, height: Layout.avatarSizeXL)
                                .overlay(Text(p.employee.initials).font(.caption).foregroundStyle(.white))
                            VStack(alignment: .leading) {
                                Text(p.employee.fullName).font(.subheadline.bold())
                                Text(p.employee.role.rawValue).font(.caption).foregroundStyle(.tertiary)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("\(p.completed)").font(.headline)
                                Text("done").font(.caption).foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
        }
        .padding(Layout.paddingXL)
        .cardStyle()
    }
}

// MARK: - Recent Activity
struct RecentActivityView: View {
    @EnvironmentObject var store: AppStore

    private var recent: [Task] {
        store.tasks
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(Layout.maxRecentActivity)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.paddingL) {
            Text("Recent Activity").font(.headline)
            if recent.isEmpty {
                Text("No recent activity").foregroundStyle(.tertiary).frame(maxWidth: .infinity, minHeight: 150)
            } else {
                VStack(spacing: Layout.paddingS) {
                    ForEach(recent) { task in
                        HStack(spacing: Layout.paddingM) {
                            Circle().fill(Color(hex: task.status.colorHex)).frame(width: 8, height: 8)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title).font(.subheadline).lineLimit(1)
                                HStack(spacing: 4) {
                                    if let name = store.employee(for: task.assigneeId)?.fullName {
                                        Text(name).font(.caption).foregroundStyle(.tertiary)
                                    }
                                    Text("\u{00B7}").font(.caption).foregroundStyle(.tertiary)
                                    Text(task.createdAt.formatted(.relative(presentation: .named)))
                                        .font(.caption).foregroundStyle(.tertiary)
                                }
                            }
                            Spacer()
                            Image(systemName: task.status.icon).font(.caption).foregroundStyle(Color(hex: task.status.colorHex))
                        }
                    }
                }
            }
        }
        .padding(Layout.paddingXL)
        .cardStyle()
    }
}
