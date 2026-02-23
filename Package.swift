// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DriveDownloader",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "DriveDownloader",
            path: "Sources/DriveDownloader"
        )
    ]
)
