// swift-tools-version: 6.1

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
]

let package = Package(
    name: "LicensesList",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "LicensesList",
            targets: ["LicensesList"],
        ),
    ],
    targets: [
        .executableTarget(
            name: "SourcePackagesParser",
            path: "Sources/SourcePackagesParser",
            swiftSettings: swiftSettings,
        ),
        .plugin(
            name: "PrepareLicensesList",
            capability: .buildTool(),
            dependencies: [.target(name: "SourcePackagesParser")],
        ),
        .target(
            name: "LicensesList",
            swiftSettings: swiftSettings,
            plugins: ["PrepareLicensesList"],
        ),
    ],
)
