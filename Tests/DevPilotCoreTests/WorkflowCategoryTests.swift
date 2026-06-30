import AppKit
import XCTest
@testable import DevPilotCore

final class WorkflowCategoryTests: XCTestCase {
  func testWorkflowCategoriesUseExpectedOrderTitlesAndAvailableIcons() {
    XCTAssertEqual(WorkflowCategory.allCases, [
      .all,
      .builtin,
      .custom,
      .coding,
      .study,
      .school,
      .ai,
      .media,
      .utility,
      .disabled
    ])

    XCTAssertEqual(WorkflowCategory.allCases.map(\.rawValue), [
      "全部工作流",
      "内置模板",
      "自定义",
      "开发",
      "学习",
      "课程作业",
      "AI 辅助",
      "创作",
      "工具",
      "已停用"
    ])

    for category in WorkflowCategory.allCases {
      XCTAssertNotNil(
        NSImage(systemSymbolName: category.systemImage, accessibilityDescription: nil),
        "\(category.rawValue) uses unavailable SF Symbol: \(category.systemImage)"
      )
    }
  }

  func testDefaultWorkflowTemplatesCarrySpecificCategories() {
    let workflows = Workflow.defaultTemplates(now: Date(timeIntervalSince1970: 0))

    XCTAssertEqual(workflows.first { $0.name == "开始写代码" }?.category, .coding)
    XCTAssertEqual(workflows.first { $0.name == "开始学习" }?.category, .study)
    XCTAssertEqual(workflows.first { $0.name == "开始做作业" }?.category, .school)
  }

  func testCustomWorkflowDefaultsToCustomCategory() {
    XCTAssertEqual(Workflow.customTemplate().category, .custom)
  }

  func testDecodingLegacyWorkflowWithoutCategoryUsesNameBasedFallback() throws {
    let json = """
      [
        {
          "id": "00000000-0000-0000-0000-000000000001",
          "name": "开始写代码",
          "description": "旧数据",
          "icon": "hammer",
          "isBuiltIn": true,
          "isEnabled": true,
          "showInHome": true,
          "showInMenuBar": true,
          "actions": [],
          "createdAt": "2026-01-01T00:00:00Z",
          "updatedAt": "2026-01-01T00:00:00Z"
        },
        {
          "id": "00000000-0000-0000-0000-000000000002",
          "name": "F1 数据项目模式",
          "description": "旧自定义数据",
          "icon": "sparkles",
          "isBuiltIn": false,
          "isEnabled": true,
          "showInHome": true,
          "showInMenuBar": true,
          "actions": [],
          "createdAt": "2026-01-01T00:00:00Z",
          "updatedAt": "2026-01-01T00:00:00Z"
        }
      ]
      """.data(using: .utf8)!
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    let workflows = try decoder.decode([Workflow].self, from: json)

    XCTAssertEqual(workflows[0].category, .coding)
    XCTAssertEqual(workflows[1].category, .custom)
  }

  func testWorkflowCategoryMatchingCoversFilterOnlyAndRealCategories() {
    let coding = Workflow(
      name: "代码模式",
      description: "开发",
      icon: "hammer",
      category: .coding,
      isBuiltIn: true,
      actions: []
    )
    let disabledCustom = Workflow(
      name: "暂停的自定义",
      description: "停用",
      icon: "pause.circle",
      category: .utility,
      isBuiltIn: false,
      isEnabled: false,
      actions: []
    )

    XCTAssertTrue(WorkflowCategory.all.matches(coding))
    XCTAssertTrue(WorkflowCategory.builtin.matches(coding))
    XCTAssertTrue(WorkflowCategory.coding.matches(coding))
    XCTAssertFalse(WorkflowCategory.custom.matches(coding))
    XCTAssertTrue(WorkflowCategory.custom.matches(disabledCustom))
    XCTAssertTrue(WorkflowCategory.utility.matches(disabledCustom))
    XCTAssertTrue(WorkflowCategory.disabled.matches(disabledCustom))
  }
}
