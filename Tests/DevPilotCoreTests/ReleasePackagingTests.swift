import XCTest

final class ReleasePackagingTests: XCTestCase {
  func testReleaseScriptsAndOpenSourceFilesExist() throws {
    let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let requiredFiles = [
      "Scripts/build_release.sh",
      "Scripts/package_zip.sh",
      "Scripts/package_dmg.sh",
      "README.md",
      "LICENSE",
      "CHANGELOG.md",
      ".gitignore"
    ]

    for relativePath in requiredFiles {
      let path = root.appendingPathComponent(relativePath).path
      XCTAssertTrue(FileManager.default.fileExists(atPath: path), "Missing \(relativePath)")
    }
  }

  func testReadmeDocumentsUnsignedFirstLaunchAndReleaseArtifacts() throws {
    let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let readme = try String(contentsOf: root.appendingPathComponent("README.md"), encoding: .utf8)

    XCTAssertTrue(readme.contains("DevPilot-v0.1.0-macOS.zip"))
    XCTAssertTrue(readme.contains("Right-click DevPilot.app"))
    XCTAssertTrue(readme.contains("Do not disable Gatekeeper"))
    XCTAssertTrue(readme.contains("./Scripts/build_release.sh"))
  }
}
