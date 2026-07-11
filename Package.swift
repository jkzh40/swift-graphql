// swift-tools-version: 6.3

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "swift-graphql",
    platforms: [
        .macOS(.v11),
    ],
    products: [
        .library(name: "GraphQL", targets: ["GraphQL"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "603.0.0"),
    ],
    targets: [
        .target(
            name: "GraphQL",
            dependencies: [
                "GraphQLMacros",
            ]
        ),
        .macro(
            name: "GraphQLMacros",
            dependencies: [
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "GraphQLTests",
            dependencies: [
                "GraphQL",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
