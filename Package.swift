// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "RecReplayKit",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "RecReplayKit", targets: ["RecReplayKit"]),
        .executable(name: "recreplay", targets: ["RecReplayCLI"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0")
    ],
    targets: [
        .target(
            name: "RecReplayKit"
        ),
        .executableTarget(
            name: "RecReplayCLI",
            dependencies: [
                "RecReplayKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "RecReplayKitTests",
            dependencies: ["RecReplayKit"]
        )
    ]
)
