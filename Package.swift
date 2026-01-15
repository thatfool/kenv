// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "kenv",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "kenv",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "kenvTests",
            dependencies: ["kenv"]
        ),
    ]
)
