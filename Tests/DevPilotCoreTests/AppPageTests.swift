import AppKit
import XCTest
@testable import DevPilotCore

final class AppPageTests: XCTestCase {
  func testMainNavigationPagesUseExpectedOrderTitlesAndIcons() {
    XCTAssertEqual(AppPage.allCases, [
      .home,
      .workflows,
      .environment,
      .commands,
      .fileOrganizer,
      .settings
    ])

    XCTAssertEqual(AppPage.allCases.map(\.title), [
      "首页",
      "工作流",
      "环境检测",
      "常用命令",
      "下载整理",
      "设置"
    ])

    XCTAssertEqual(AppPage.allCases.map(\.systemImage), [
      "house",
      "play.rectangle",
      "terminal",
      "command",
      "folder",
      "gearshape"
    ])
  }

  func testMainNavigationIconsResolveToSystemImages() {
    for page in AppPage.allCases {
      XCTAssertNotNil(
        NSImage(systemSymbolName: page.systemImage, accessibilityDescription: nil),
        "\(page.title) uses unavailable SF Symbol: \(page.systemImage)"
      )
    }
  }
}
