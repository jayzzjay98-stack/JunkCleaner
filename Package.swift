// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "JunkCleaner",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "JunkCleaner",
            path: "Sources/JunkCleaner"
        )
    ]
)
