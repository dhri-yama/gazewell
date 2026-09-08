// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LookAway",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "LookAwayCore", path: "Sources/LookAwayCore"),
        .executableTarget(name: "LookAway", dependencies: ["LookAwayCore"], path: "Sources/LookAway"),
        .testTarget(name: "LookAwayTests", dependencies: ["LookAwayCore"], path: "Tests/LookAwayTests"),
    ]
)
