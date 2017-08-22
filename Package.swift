// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "Chain-Swift",
    dependencies: [
        // Add dependencies
       .Package(url: "https://github.com/vapor/engine.git", majorVersion: 2),
       .Package(url: "https://github.com/vapor/json.git", majorVersion: 2),
    ]
)
