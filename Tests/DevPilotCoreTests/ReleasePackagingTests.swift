import XCTest

final class ReleasePackagingTests: XCTestCase {
  func testReleaseScriptsAndOpenSourceFilesExist() throws {
    let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let requiredFiles = [
      "Scripts/build_release.sh",
      "Scripts/package_zip.sh",
      "Scripts/package_dmg.sh",
      "README.md",
      "CHANGELOG.md",
      ".gitignore"
    ]

    for relativePath in requiredFiles {
      let path = root.appendingPathComponent(relativePath).path
      XCTAssertTrue(FileManager.default.fileExists(atPath: path), "Missing \(relativePath)")
    }

    let licensePath = root.appendingPathComponent("LICENSE").path
    XCTAssertFalse(FileManager.default.fileExists(atPath: licensePath), "This project should not publish a LICENSE file yet.")
  }

  func testReadmeDocumentsUnsignedFirstLaunchAndDirectReleaseLinks() throws {
    let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let readme = try String(contentsOf: root.appendingPathComponent("README.md"), encoding: .utf8)

    XCTAssertTrue(readme.contains("https://github.com/herman0216-glitch/DevPilot/releases/download/v0.1.0/DevPilot-v0.1.0-macOS.zip"))
    XCTAssertTrue(readme.contains("https://github.com/herman0216-glitch/DevPilot/releases/download/v0.1.0/DevPilot-v0.1.0.dmg"))
    XCTAssertTrue(readme.contains("右键点击 `DevPilot.app`"))
    XCTAssertTrue(readme.contains("不要关闭 Gatekeeper"))
    XCTAssertTrue(readme.contains("./Scripts/build_release.sh"))
    XCTAssertFalse(readme.contains("MIT License"))
    XCTAssertFalse(readme.contains("[LICENSE]"))
  }
}
