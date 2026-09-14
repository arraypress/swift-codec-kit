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
