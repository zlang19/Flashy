// swift-tools-version:5.9
import PackageDescription

// Platform-independent logic for Flashy: scheduling, card parsing, repo layout,
// sync planning and stats. Foundation only, so it builds and tests on Linux.
let package = Package(
    name: "FlashyCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "FlashyCore", targets: ["FlashyCore"]),
    ],
    targets: [
        .target(name: "FlashyCore"),
        .testTarget(
            name: "FlashyCoreTests",
            dependencies: ["FlashyCore"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
