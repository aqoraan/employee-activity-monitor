// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacSystemMonitor",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MacSystemMonitor", targets: ["MacSystemMonitor"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "MacSystemMonitor",
            path: "MacSystemMonitor",
            sources: [
                "SimpleTestApp.swift"
            ]
        )
    ]
) 