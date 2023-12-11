// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "skip-model",
    defaultLocalization: "en",
    platforms: [.iOS(.v16), .macOS(.v13), .tvOS(.v16), .watchOS(.v9), .macCatalyst(.v16)],
    products: [
        .library(name: "SkipModel", type: .dynamic, targets: ["SkipModel"]),
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "0.7.32"),
        .package(url: "https://source.skip.tools/skip-foundation.git", from: "0.3.8"),
    ],
    targets: [
        .target(name: "SkipModel", dependencies: [.product(name: "SkipFoundation", package: "skip-foundation")], plugins: [.plugin(name: "skipstone", package: "skip")]),
        .testTarget(name: "SkipModelTests", dependencies: ["SkipModel", .product(name: "SkipTest", package: "skip")], plugins: [.plugin(name: "skipstone", package: "skip")]),
    ]
)
