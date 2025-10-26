// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HyperVale",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "HyperVale",
            targets: ["HyperVale"]),
    ],
    dependencies: [
        // No source dependencies
    ],
    targets: [
        // This is your HyperVale code
        .target(
            name: "HyperVale",
            dependencies: [
                // It now depends on the binary target below
                .target(name: "Hyperswitch")
            ]
        ),

        // This is the pre-compiled Hyperswitch SDK binary
        .binaryTarget(
            name: "Hyperswitch", // The module name
            url: "https://github.com/juspay/hyperswitch-pods/raw/main/HyperswitchCore.tar.gz",
            checksum: "4a5b4815a51c4a008c2d53965586616c52a373b8893708a0d4253ab1597c8d23"
        )
    ]
)
