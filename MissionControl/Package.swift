// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MissionControl",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(
            name: "MissionControl",
            path: "Sources/MissionControl"
        ),
        .testTarget(
            name: "MissionControlTests",
            dependencies: ["MissionControl"],
            path: "Tests/MissionControlTests"
        ),
        .testTarget(
            name: "MissionControlUITests",
            dependencies: ["MissionControl"],
            path: "Tests/MissionControlUITests",
            swiftSettings: [
                // XCUIApplication is @MainActor-isolated; Swift 5 mode avoids
                // strict send-isolation errors in UI test code.
                .swiftLanguageMode(.v5)
            ]
        ),
    ]
)
