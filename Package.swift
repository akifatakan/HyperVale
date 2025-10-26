// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HyperVale",
    // 1. Specify the minimum platform (iOS 15 for modern SwiftUI)
    platforms: [
        .iOS(.v15)
    ],
    products: [
        // 2. This is the library your app will import
        .library(
            name: "HyperVale",
            targets: ["HyperVale"]),
    ],
    dependencies: [
        // 3. Add the Hyperswitch SDK as a dependency
        .package(url: "https://github.com/juspay/hyperswitch-sdk-ios.git", .upToNextMajor(from: "1.8.0"))
    ],
    targets: [
        // 4. This is your package's target
        .target(
            name: "HyperVale",
            dependencies: [
                // 5. Link your target to the Hyperswitch product
                .product(name: "Hyperswitch", package: "hyperswitch-sdk-ios")
            ]),
    ]
)
