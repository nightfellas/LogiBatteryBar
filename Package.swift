// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LogiBatteryBar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "LogiBatteryBar",
            targets: ["LogiBatteryBar"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "LogiBatteryBar",
            dependencies: [],
            path: "Sources/LogiBatteryBar",
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI")
            ]
        ),
        .testTarget(
            name: "LogiBatteryBarTests",
            dependencies: ["LogiBatteryBar"],
            path: "Tests/LogiBatteryBarTests"
        )
    ]
)
