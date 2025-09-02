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
        .package(url: "https://source.skip.tools/skip.git", from: "1.5.15"),
        .package(url: "https://source.skip.tools/skip-foundation.git", from: "1.3.5"),
    ],
    targets: [
        .target(name: "SkipModel", dependencies: [.product(name: "SkipFoundation", package: "skip-foundation")], plugins: [.plugin(name: "skipstone", package: "skip")]),
        .testTarget(name: "SkipModelTests", dependencies: ["SkipModel", .product(name: "SkipTest", package: "skip")], plugins: [.plugin(name: "skipstone", package: "skip")]),
    ]
)

#if !canImport(Combine)
// on Linux we need to import OpenCombine to get ObservableObject
package.dependencies += [.package(url: "https://github.com/OpenCombine/OpenCombine.git", from: "0.14.0")]
package.targets[0].dependencies += [.product(name: "OpenCombine", package: "OpenCombine")]
#endif

if Context.environment["SKIP_BRIDGE"] ?? "0" != "0" {
    // all library types must be dynamic to support bridging
    package.products = package.products.map({ product in
        guard let libraryProduct = product as? Product.Library else { return product }
        return .library(name: libraryProduct.name, type: .dynamic, targets: libraryProduct.targets)
    })
}
