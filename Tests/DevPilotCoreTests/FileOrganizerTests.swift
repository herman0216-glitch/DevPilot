import XCTest
@testable import DevPilotCore

final class FileOrganizerTests: XCTestCase {
  private var rootURL: URL!

  override func setUpWithError() throws {
    rootURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("DevPilotFileOrganizerTests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
  }

  override func tearDownWithError() throws {
    if let rootURL {
      try? FileManager.default.removeItem(at: rootURL)
    }
  }

  func testOrganizeMovesKnownExtensionsIntoCategoriesAndRenamesCollisions() throws {
    try writeFile("setup.dmg")
    try writeFile("notes.pdf")
    try writeFile("script.py")
    try writeFile("report.csv")
    try writeFile("readme.unknown")
    try writeFile(".hidden.pdf")
    try FileManager.default.createDirectory(
      at: rootURL.appendingPathComponent("ExistingFolder", isDirectory: true),
      withIntermediateDirectories: true
    )
    let documentsURL = rootURL.appendingPathComponent("Documents", isDirectory: true)
    try FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true)
    try "old".write(
      to: documentsURL.appendingPathComponent("notes.pdf"),
      atomically: true,
      encoding: .utf8
    )

    let result = try FileOrganizer(fileManager: .default).organize(directory: rootURL)

    XCTAssertEqual(result.scannedCount, 8)
    XCTAssertEqual(result.movedCount, 5)
    XCTAssertEqual(result.skippedCount, 3)
    XCTAssertTrue(FileManager.default.fileExists(atPath: rootURL.appendingPathComponent("Installers/setup.dmg").path))
    XCTAssertTrue(FileManager.default.fileExists(atPath: rootURL.appendingPathComponent("Documents/notes-1.pdf").path))
    XCTAssertTrue(FileManager.default.fileExists(atPath: rootURL.appendingPathComponent("Code/script.py").path))
    XCTAssertTrue(FileManager.default.fileExists(atPath: rootURL.appendingPathComponent("Data/report.csv").path))
    XCTAssertTrue(FileManager.default.fileExists(atPath: rootURL.appendingPathComponent("Others/readme.unknown").path))
    XCTAssertTrue(FileManager.default.fileExists(atPath: rootURL.appendingPathComponent(".hidden.pdf").path))
    XCTAssertTrue(result.errors.isEmpty)
  }

  private func writeFile(_ relativePath: String) throws {
    try "sample".write(
      to: rootURL.appendingPathComponent(relativePath),
      atomically: true,
      encoding: .utf8
    )
  }
}
