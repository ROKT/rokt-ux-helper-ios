// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RoktUXHelper",
    platforms: [.iOS(.v12)],
    products: [
        .library(
            name: "RoktUXHelper",
            targets: ["RoktUXHelper"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/ROKT/dcui-swift-schema.git", exact: "2.2.0-alpha4"),
        .package(url: "https://github.com/nalexn/ViewInspector.git", exact: "0.10.0")
    ],
    targets: [
        .target(
            name: "RoktUXHelper",
            dependencies: [.product(name: "DcuiSchema", package: "dcui-swift-schema")],
            resources: [.process("PrivacyInfo.xcprivacy")]
        ),
        .testTarget(
            name: "RoktUXHelperTests",
            dependencies: ["RoktUXHelper",
                           .product(name: "ViewInspector", package: "ViewInspector"),
                           .product(name: "DcuiSchema", package: "dcui-swift-schema")],
            path: "Tests/RoktUXHelperTests",
            resources: [
                .process("Supporting Files")
            ]
        )
    ]
)
