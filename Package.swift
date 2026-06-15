// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NetScope",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "NetScope", targets: ["NetScope"]),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift", from: "7.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "NetScope",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
            ],
            path: "Sources/NetScope",
            resources: [
                .copy("Resources"),
            ]
        ),
        .testTarget(
            name: "NetScopeTests",
            dependencies: [
                "NetScope",
                .product(name: "GRDB", package: "GRDB.swift"),
            ],
            path: "Tests/NetScopeTests"
        ),
    ]
)