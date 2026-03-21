// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Gisk",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "Gisk", targets: ["Gisk"]),
    ],
    targets: [
        .target(
            name: "GiskLib",
            path: "Sources/GiskLib"
        ),
        .executableTarget(
            name: "Gisk",
            dependencies: ["GiskLib"],
            path: "Sources/Gisk"
        ),
        .testTarget(
            name: "GiskTests",
            dependencies: ["GiskLib"],
            path: "Tests/GiskTests"
        ),
    ]
)
