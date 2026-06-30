import AppKit
import XCTest
@testable import DevPilotCore

final class MenuBarChromeTests: XCTestCase {
  func testMenuBarItemUsesDevPilotIdentityInsteadOfGenericSymbolName() {
    XCTAssertEqual(DevPilotMenuBarItem.title, "DevPilot")
    XCTAssertEqual(DevPilotMenuBarItem.assetName, "MenuBarIcon")
    XCTAssertEqual(DevPilotMenuBarItem.accessibilityLabel, "DevPilot")
    XCTAssertEqual(DevPilotMenuBarItem.fallbackSystemImage, "paperplane")
    XCTAssertEqual(DevPilotMenuBarItem.statusItemLength, 28)
  }

  func testMenuBarItemIconResolvesToSystemImage() {
    XCTAssertNotNil(
      NSImage(systemSymbolName: DevPilotMenuBarItem.fallbackSystemImage, accessibilityDescription: nil),
      "Menu bar item uses unavailable SF Symbol: \(DevPilotMenuBarItem.fallbackSystemImage)"
    )
  }
}
