// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "GasGridManager",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "GasGridManager", targets: ["GasGridManager"])
    ],
    targets: [
        .executableTarget(
            name: "GasGridManager",
            path: "Sources/GasGridManager"
        ),
        .testTarget(
            name: "GasGridManagerTests",
            dependencies: ["GasGridManager"],
            path: "Tests/GasGridManagerTests"
        ),
    ]
)
