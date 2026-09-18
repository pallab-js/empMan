# GasGrid Manager

A native macOS employee management application built with SwiftUI and Swift Package Manager.

## Features

- **Dashboard** — Real-time stats, task distribution charts, weekly trends, top performers, and recent activity
- **Employees** — Full CRUD with role, department, and team assignments; active/inactive filtering
- **Tasks** — Create, assign, and track tasks with priorities, categories, statuses, and due dates
- **Departments** — Manage departments with color-coded cards and member rollups
- **Teams** — Organize employees into teams under departments
- **Projects** — Track project progress with status, date ranges, and linked tasks
- **Settings** — Configurable sidebar, animations, active-only filtering, and data export
- **Persistence** — All data stored locally as JSON in Application Support

## Architecture

```
Sources/GasGridManager/
├── App/            App entry point and navigation
├── Models/         Data models (Employee, Task, Department, Team, Project)
├── Services/       AppStore — central data manager with O(1) lookup indices
├── Components/     Reusable UI components (SearchBar, EmptyState, OptionalDatePicker)
├── Utilities/      Extensions, validators, layout constants
└── Views/
    ├── Dashboard/   Dashboard with Charts framework
    ├── Employees/   Employee list and cards
    ├── Tasks/       Task list with filters
    ├── Departments/ Department cards and management
    ├── Teams/       Team detail and member management
    ├── Projects/    Project tracking and progress
    └── Settings/    App preferences
```

## Requirements

- macOS 14.0+
- Swift 5.9+
- Xcode 15.0+

## Getting Started

```bash
git clone https://github.com/pallab-js/empMan.git
cd empMan
swift build
swift run GasGridManager
```

## License

MIT License — see [LICENSE](LICENSE) for details.
