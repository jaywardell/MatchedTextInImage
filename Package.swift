// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MatchedTextInImage",
    platforms: [
        .iOS(.v17),
        .macOS(.v13),
        .tvOS(.v14),
        .visionOS(.v1),
        .watchOS(.v9)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "MatchedTextInImage",
            targets: ["MatchedTextInImage"]),
    ], dependencies: [
        // Here we define our package's external dependencies
        // and from where they can be fetched:
        .package(
            url: "https://github.com/jaywardell/MatchedText",
            .upToNextMajor(from: "0.1.5")
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "MatchedTextInImage",
            dependencies: [
                .product(name: "MatchedText", package: "MatchedText"),
            ]
        )
    ]
)
