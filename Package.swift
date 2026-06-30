// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "DevPilot",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .executable(name: "DevPilot", targets: ["DevPilot"])
  ],
  targets: [
    .target(
      name: "DevPilotCore",
      path: "Sources/DevPilotCore"
    ),
    .executableTarget(
      name: "DevPilot",
      dependencies: ["DevPilotCore"],
      path: "Sources/DevPilot",
      exclude: ["Resources"]
    ),
    .testTarget(
      name: "DevPilotCoreTests",
      dependencies: ["DevPilotCore"],
      path: "Tests/DevPilotCoreTests"
    )
  ]
)
