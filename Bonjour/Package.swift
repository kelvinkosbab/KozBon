// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Bonjour",
    products: [
        .library(
            name: "Bonjour",
            targets: ["Bonjour"]
        ),
        .library(
            name: "KozBonCore",
            targets: ["KozBonCore"]
        ),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "Bonjour"
        ),
        .target(
            name: "KozBonCore"
        ),
    ]
)
