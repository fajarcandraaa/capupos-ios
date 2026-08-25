// swift-tools-version: 6.3
import PackageDescription
let package = Package(
    name: "CapuPOS",
    platforms: [.iOS(.v15), .macOS(.v14)],
    products: [
        .executable(name: "CapuPOS", targets: ["CapuPOSApp"])
    ],
    targets: [
        .executableTarget(
            name: "CapuPOSApp",
            dependencies: []
        )
    ]
)