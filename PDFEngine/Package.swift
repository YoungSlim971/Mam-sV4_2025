// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PDFEngine",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "PDFEngine",
            targets: ["PDFEngine"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(path: "../Utilities"),
        .package(path: "../DataLayer")
    ],
    targets: [
        .target(
            name: "PDFEngine",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                "Utilities",
                "DataLayer"
            ]
        ),
        .testTarget(
            name: "PDFEngineTests",
            dependencies: ["PDFEngine"]
        ),
    ]
)