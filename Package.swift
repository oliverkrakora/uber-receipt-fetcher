// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UberReceipts",
    platforms: [.macOS(.v12)],
    products: [
        .executable(name: "uber-receipt-fetcher", targets: ["UberReceiptFetcher"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(name: "UberReceiptFetcher", dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser")
        ]),
    ]
)
