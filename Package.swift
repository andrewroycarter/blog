// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "blog",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "blog", targets: ["cli"]),
        .library(name: "bloglib", targets: ["blog"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-testing.git", from: "0.5.0"),
        .package(url: "https://github.com/apple/swift-markdown.git", from: "0.3.0")
    ],
    targets: [
        .executableTarget(
            name: "cli",
            dependencies: [
                "blog",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]),
        .target(
            name: "blog",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown")
            ]),
        .testTarget(
            name: "tests",
            dependencies: [
                "blog",
                .product(name: "Testing", package: "swift-testing")
            ])
    ]
)
