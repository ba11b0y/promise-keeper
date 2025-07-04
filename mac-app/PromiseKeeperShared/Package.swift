// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "PromiseKeeperShared",
    platforms: [
        .macOS(.v12),
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "PromiseKeeperShared",
            targets: ["PromiseKeeperShared"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "PromiseKeeperShared",
            dependencies: [],
            path: "Sources"
        )
    ]
)