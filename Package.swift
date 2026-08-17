// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DependencyGuard",
    platforms: [
        .macOS(.v26)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.8.2"),
        .package(url: "https://github.com/swiftlang/swift-subprocess.git", .upToNextMinor(from: "0.5.0")),
        .package(url: "https://github.com/tuist/XcodeProj.git", from: "9.15.0"),
    ],
    targets: [
        .executableTarget(
            name: "DependencyGuard",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Subprocess", package: "swift-subprocess"),
                .product(name: "XcodeProj", package: "XcodeProj"),
            ]
        ),
        .testTarget(
            name: "DependencyGuardTests",
            dependencies: ["DependencyGuard"]
        ),
    ]
)
