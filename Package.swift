// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "skip-model",
    defaultLocalization: "en",
    platforms: [.iOS(.v16), .macOS(.v13), .tvOS(.v16), .watchOS(.v9), .macCatalyst(.v16)],
    products: [
        .library(name: "SkipModel", targets: ["SkipModel"]),
    ],
    dependencies: [
        .package(url: "https://github.com/skiptools/skip.git", from: "1.9.6"),
        .package(url: "https://github.com/skiptools/skip-foundation.git", from: "1.4.3"),
    ],
    targets: [
        .target(name: "SkipModel", dependencies: [.product(name: "SkipFoundation", package: "skip-foundation")], plugins: [.plugin(name: "skipstone", package: "skip")]),
        .testTarget(name: "SkipModelTests", dependencies: ["SkipModel", .product(name: "SkipTest", package: "skip")], plugins: [.plugin(name: "skipstone", package: "skip")]),
    ]
)

#if !canImport(Combine)
// Only the tests use Combine natively (the SkipModel target's Swift is all `#if SKIP`),
// so OpenCombine is a test-only dependency on Linux. Linking it into the SkipModel
// product would statically embed OpenCombine into libSkipModel.so, and Swift 6.4's
// swiftbuild engine rejects that whenever a Fuse app also links OpenCombine into its own
// dynamic products ("linked as a static library by … This will result in duplication").
package.dependencies += [.package(url: "https://github.com/OpenSwiftUIProject/OpenCombine.git", from: "0.15.1")]
package.targets[1].dependencies += [.product(name: "OpenCombine", package: "OpenCombine")]
package.targets[1].dependencies += [.product(name: "OpenCombineFoundation", package: "OpenCombine")]
#endif

// SKIP_DYNAMIC_LIBRARIES and SKIP_BRIDGE both enforce building as dynamic
// libraries; SKIP_BRIDGE additionally puts the skipstone plugin in bridge mode
let bridgeMode = (Context.environment["SKIP_BRIDGE"] ?? "0") != "0"
let forceDylib = bridgeMode || (Context.environment["SKIP_DYNAMIC_LIBRARIES"] ?? "0") != "0"

if forceDylib {
    // all library types must be dynamic to support bridging
    package.products = package.products.map({ product in
        guard let libraryProduct = product as? Product.Library else { return product }
        return .library(name: libraryProduct.name, type: .dynamic, targets: libraryProduct.targets)
    })
}
