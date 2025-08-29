// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Main",
    platforms: [.macOS(.v13)],
    products: [
        .singleTargetLibrary("SnippetConverterCore"),
        .executable(name: "snippet-converter", targets: ["SnippetConverterCLI"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.6.1"),
    ],
    targets: [
        .target(
            name: "SnippetConverterCore",
            dependencies: []
        ),
        .testTarget(
            name: "SnippetConverterCoreTests",
            dependencies: [
                "SnippetConverterCore",
            ]
        ),

        // CLI
        .executableTarget(
            name: "SnippetConverterCLI",
            dependencies: [
                "SnippetConverterCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(name: "SnippetConverterCLITests",
                    dependencies: ["SnippetConverterCLI"]),
    ]
)

extension Product {
    static func singleTargetLibrary(_ name: String) -> Product {
        .library(name: name, targets: [name])
    }
}
