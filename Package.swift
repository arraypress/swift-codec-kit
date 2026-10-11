// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "swift-codec-kit",
    platforms: [
        .macOS(.v14), .iOS(.v17), .tvOS(.v17), .watchOS(.v10)
    ],
    products: [
        .library(name: "CodecKit", targets: ["CodecKit"]),
    ],
    targets: [
        .target(name: "CodecKit"),
        .testTarget(name: "CodecKitTests", dependencies: ["CodecKit"]),
    ]
)

// Swift 7's import rule, today: a file must import every module whose members
// it uses, rather than leaning on another file's imports.
for target in package.targets where target.type != .system && target.type != .binary && target.type != .plugin {
    target.swiftSettings = (target.swiftSettings ?? []) + [.enableUpcomingFeature("MemberImportVisibility")]
}
