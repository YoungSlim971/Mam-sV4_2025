// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DataLayer",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "DataLayer",
            targets: ["DataLayer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/CoreOffice/CoreXLSX", from: "0.14.2"),
        .package(url: "https://github.com/maxdesiatov/XMLCoder.git", from: "0.14.0"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.19"),
        .package(path: "../Utilities")
    ],
    targets: [
        .target(
            name: "DataLayer",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "CoreXLSX", package: "CoreXLSX"),
                .product(name: "XMLCoder", package: "XMLCoder"),
                .product(name: "ZIPFoundation", package: "ZIPFoundation"),
                "Utilities"
            ]
        ),
        .testTarget(
            name: "DataLayerTests",
            dependencies: ["DataLayer"]
        ),
    ]
)