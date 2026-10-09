// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "INDD2IDML",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "INDDConverterEngine",
            targets: ["INDDConverterEngine"]
        ),
        .executable(
            name: "indd2idml-cli",
            targets: ["INDDConverterCLI"]
        ),
        .executable(
            name: "INDD2IDML",
            targets: ["INDDConverterApp"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "INDDConverterEngine",
            dependencies: [],
            path: "Sources/INDDConverterEngine"
        ),
        .executableTarget(
            name: "INDDConverterCLI",
            dependencies: ["INDDConverterEngine"],
            path: "Sources/INDDConverterCLI"
        ),
        .executableTarget(
            name: "INDDConverterApp",
            dependencies: ["INDDConverterEngine"],
            path: "Sources/INDDConverterApp"
        ),
        .testTarget(
            name: "INDDConverterEngineTests",
            dependencies: ["INDDConverterEngine"],
            path: "Tests/INDDConverterEngineTests"
        )
    ]
)
