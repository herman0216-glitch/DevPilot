import XCTest
@testable import DevPilotCore

final class LayoutMetricsTests: XCTestCase {
  func testMainWindowAndWorkflowLayoutMetricsStayStable() {
    XCTAssertEqual(DevPilotLayout.mainSidebarWidth, 220)
    XCTAssertEqual(DevPilotLayout.mainWindowMinWidth, 1000)
    XCTAssertEqual(DevPilotLayout.mainWindowMinHeight, 650)
    XCTAssertEqual(DevPilotLayout.workflowCategoryWidth, 220)
    XCTAssertEqual(DevPilotLayout.workflowListWidth, 300)
    XCTAssertEqual(DevPilotLayout.workflowDetailMaxWidth, 860)
  }
}
