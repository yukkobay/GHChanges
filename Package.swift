// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GHChanges",
    platforms: [.macOS(.v10_15)],
    products: [
        .executable(name: "gh-changes", targets: ["GHChanges"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser",
            from: "0.3.2"
        ),
    ],
    targets: [
        .target(name: "GHChanges", dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ]),
        .testTarget(name: "GHChangesTests", dependencies: ["GHChanges"]),
    ]
)
