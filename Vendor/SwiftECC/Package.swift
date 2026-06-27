// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftECC",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SwiftECC",
            targets: ["SwiftECC"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(path: "../ASN1"),
        .package(path: "../BigInt"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SwiftECC",
            dependencies: ["ASN1", "BigInt"]),
        .testTarget(
            name: "SwiftECCTests",
            dependencies: ["SwiftECC"]),
    ]
)
