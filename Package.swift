// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MoneyMonitor",
    platforms: [.macOS(.v14), .iOS(.v17)],
    targets: [
        .executableTarget(
            name: "MoneyMonitor-macOS",
            path: "macOS",
            sources: ["App", "Views", "Helpers"],
            resources: [.process("Resources")]
        )
    ]
)
