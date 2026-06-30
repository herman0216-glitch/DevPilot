import XCTest
@testable import DevPilotCore

final class CommandSafetyValidatorTests: XCTestCase {
  func testBlocksDangerousCommands() {
    let validator = CommandSafetyValidator()

    XCTAssertEqual(validator.evaluate("rm -rf /"), .blocked)
    XCTAssertEqual(validator.evaluate("sudo rm -rf /Users/herman/tmp"), .blocked)
    XCTAssertEqual(validator.evaluate("diskutil eraseDisk APFS Test disk0"), .blocked)
    XCTAssertEqual(validator.evaluate("killall Finder"), .blocked)
  }

  func testMarksMutatingCommandsAsNeedingConfirmation() {
    let validator = CommandSafetyValidator()

    XCTAssertEqual(validator.evaluate("sudo xcode-select --switch /Applications/Xcode.app"), .needsConfirmation)
    XCTAssertEqual(validator.evaluate("brew install node"), .needsConfirmation)
    XCTAssertEqual(validator.evaluate("npm install"), .needsConfirmation)
  }

  func testAllowsReadOnlyCommands() {
    let validator = CommandSafetyValidator()

    XCTAssertEqual(validator.evaluate("git status"), .safe)
    XCTAssertEqual(validator.evaluate("node -v"), .safe)
    XCTAssertEqual(validator.evaluate("brew --version"), .safe)
  }
}
