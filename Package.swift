// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "mqtt-nio",
    products: [
        .library(name: "MQTTNIO", targets: ["MQTTNIO"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.70.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.30.0"),
        .package(url: "https://github.com/apple/swift-nio-transport-services.git", from: "1.22.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.3"),
        .package(url: "https://github.com/apple/swift-testing.git", from: "0.9.0"),
    ],
    targets: [
        .target(name: "MQTTNIO", dependencies: [
            .product(name: "Logging", package: "swift-log"),
            .product(name: "NIO", package: "swift-nio"),
            .product(name: "NIOHTTP1", package: "swift-nio"),
            .product(name: "NIOWebSocket", package: "swift-nio"),
            .product(name: "NIOSSL", package: "swift-nio-ssl", condition: .when(platforms: [.linux, .macOS])),
            .product(name: "NIOTransportServices", package: "swift-nio-transport-services"),
        ]),
        .testTarget(name: "MQTTNIOTests", dependencies: [
            .target(name: "MQTTNIO"),
            .product(name: "NIOTestUtils", package: "swift-nio"),
            .product(name: "Testing", package: "swift-testing"),
        ]),
    ],
    swiftLanguageVersions: [.v5, .version("6")]
)
