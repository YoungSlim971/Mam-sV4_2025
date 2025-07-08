// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Utilities",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "Utilities",
            targets: ["Utilities"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "Utilities",
            dependencies: [
                .product(name: "Logging", package: "swift-log")
            ]
        ),
        .testTarget(
            name: "UtilitiesTests",
            dependencies: ["Utilities"]
        ),
    ]
)