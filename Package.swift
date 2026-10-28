// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Gazewell",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "GazewellCore", path: "Sources/GazewellCore"),
        .executableTarget(name: "Gazewell", dependencies: ["GazewellCore"], path: "Sources/Gazewell"),
        .testTarget(name: "GazewellTests", dependencies: ["GazewellCore"], path: "Tests/GazewellTests"),
    ]
)
