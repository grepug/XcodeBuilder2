// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "xcode-builder-2",
    platforms: [.macOS(.v15)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Lib",
            targets: ["Core"])
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-sharing.git", from: "2.5.2"),
        .package(url: "https://github.com/pointfreeco/sharing-grdb.git", from: "0.5.0"),
    ],
    targets: [ 
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Core",
            dependencies: [
                .product(name: "Sharing", package: "swift-sharing"),
                .product(name: "SharingGRDB", package: "sharing-grdb"),
            ],
            path: "Sources/Core",
        ),
        .testTarget(
            name: "XcodeBuilderTests",
            dependencies: ["Core"]
        ),
    ]
)
