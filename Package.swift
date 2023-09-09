// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "skip-model",
    defaultLocalization: "en",
    platforms: [.iOS(.v16), .macOS(.v13), .tvOS(.v16), .watchOS(.v9), .macCatalyst(.v16)],
    products: [
        .library(name: "SkipModel", targets: ["SkipModel"]),
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "0.6.58"),
        .package(url: "https://source.skip.tools/skip-foundation.git", from: "0.1.18"),
    ],
    targets: [
        .target(name: "SkipModel", dependencies: [.product(name: "SkipFoundation", package: "skip-foundation", condition: .when(platforms: [.macOS]))], plugins: [.plugin(name: "skipstone", package: "skip")]),
        .testTarget(name: "SkipModelTests", dependencies: ["SkipModel", .product(name: "SkipTest", package: "skip", condition: .when(platforms: [.macOS]))], plugins: [.plugin(name: "skipstone", package: "skip")]),
    ]
)
