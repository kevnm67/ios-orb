// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "FixtureKit",
    products: [
        .library(name: "FixtureKit", targets: ["FixtureKit"]),
    ],
    targets: [
        .target(name: "FixtureKit"),
        .testTarget(name: "FixtureKitTests", dependencies: ["FixtureKit"]),
    ]
)
