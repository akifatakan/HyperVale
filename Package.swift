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
        // We no longer have source dependencies
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
            name: "Hyperswitch", // The module name is 'Hyperswitch'
            url: "https://github.com/juspay/hyperswitch-pods/raw/main/HyperswitchCore.tar.gz",
            checksum: "5a389047dbae96ad6af58196d0bdb7fe3e0ca9c30a01cabf1b368a42fe195414"
        )
    ]
)
