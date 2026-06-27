// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "neo-swift-sdk",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(name: "NeoSwiftSDK",
                 targets: ["NeoSwiftSDK"]),
    ],
    dependencies: [
        .package(path: "Vendor/BigInt"),
        .package(path: "Vendor/ASN1"),
        .package(path: "Vendor/SwiftECC"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift", "1.8.0"..<"2.0.0"),
        .package(url: "https://github.com/greymass/swift-scrypt.git", "1.0.0"..<"2.0.0"),
    ],
    targets: [
        .target(name: "NeoSwiftSDK",
                dependencies: ["ASN1", "BigInt", "CryptoSwift", "SwiftECC",
                               .product(name: "Scrypt", package: "swift-scrypt")]),
        .testTarget(name: "NeoSwiftSDKTests",
                    dependencies: ["NeoSwiftSDK", "BigInt", "SwiftECC"],
                    resources: [.process("unit/resources/")]),
    ]
)
