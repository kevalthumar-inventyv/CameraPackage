// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CameraPackage",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "CameraPackage",
            targets: ["CameraPackage"]
        )
    ],
    targets: [
        // Binary XCFramework
        .binaryTarget(
            name: "camera_lib",
            path: "camera_lib.xcframework"
        ),

        // Swift wrapper
        .target(
            name: "CameraPackage",
            dependencies: [
                "camera_lib"
            ]
        )
    ]
)

