// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "iOS-SDK",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "iOS-SDK",
            targets: ["iOS-SDK"]
        ),
        .library(
            name: "SyteUI",
            targets: ["SyteUI"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Moya/Moya.git", .upToNextMajor(from: "15.0.0")),
        .package(url: "https://github.com/mxcl/PromiseKit.git", .upToNextMajor(from: "6.18.1"))
    ],
    targets: [
        .target(
            name: "iOS-SDK",
            dependencies: [
                .product(name: "Moya", package: "Moya"),
                "PromiseKit"
            ]
        ),
        .target(
            name: "SyteUI",
            dependencies: ["iOS-SDK"]
        ),
        .testTarget(
            name: "iOS-SDKTests",
            dependencies: ["iOS-SDK"]
        ),
        .testTarget(
            name: "SyteUITests",
            dependencies: ["SyteUI", "iOS-SDK"]
        )
    ],
    swiftLanguageVersions: [.v5]
)
