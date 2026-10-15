// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Clair",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "Clair", targets: ["Clair"])],
    targets: [.executableTarget(name: "Clair")]
)
