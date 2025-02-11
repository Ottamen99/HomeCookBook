// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RecipeBookKit",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "RecipeBookKit",
            targets: ["RecipeBookKit"]),
    ],
    targets: [
        .target(
            name: "RecipeBookKit",
            dependencies: [])
    ]
) 