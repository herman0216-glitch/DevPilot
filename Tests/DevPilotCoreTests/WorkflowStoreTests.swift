import XCTest
@testable import DevPilotCore

final class WorkflowStoreTests: XCTestCase {
  func testLoadCreatesDefaultTemplatesWhenFileDoesNotExist() throws {
    let url = try temporaryURL(named: "workflows.json")
    let store = WorkflowStore(fileURL: url)

    store.load()

    XCTAssertEqual(store.workflows.map(\.name), ["开始写代码", "开始学习", "开始做作业"])
    XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    XCTAssertTrue(store.workflows.allSatisfy(\.showInHome))
    XCTAssertTrue(store.workflows.allSatisfy(\.showInMenuBar))
  }

  func testCreateUpdateDeleteAndReloadPersistsWorkflows() throws {
    let url = try temporaryURL(named: "workflows.json")
    let store = WorkflowStore(fileURL: url)
    store.load()

    var workflow = Workflow.customTemplate(name: "F1 数据项目模式")
    workflow.actions.append(WorkflowAction(type: .openURL, title: "Open telemetry", value: "http://localhost:3000"))
    store.create(workflow)

    workflow.name = "F1 Dashboard 模式"
    store.update(workflow)
    store.delete(store.workflows.first { $0.name == "开始学习" }!)

    let reloaded = WorkflowStore(fileURL: url)
    reloaded.load()

    XCTAssertTrue(reloaded.workflows.contains { $0.name == "F1 Dashboard 模式" })
    XCTAssertFalse(reloaded.workflows.contains { $0.name == "开始学习" })
  }

  func testHistoryStoreKeepsMostRecentTenResults() throws {
    let url = try temporaryURL(named: "workflow-history.json")
    let store = WorkflowRunHistoryStore(fileURL: url, limit: 10)

    for index in 0..<12 {
      store.record(WorkflowRunResult(
        workflowId: UUID(),
        workflowName: "Workflow \(index)",
        startedAt: Date(timeIntervalSince1970: TimeInterval(index)),
        finishedAt: Date(timeIntervalSince1970: TimeInterval(index + 1)),
        success: true,
        actionResults: []
      ))
    }

    XCTAssertEqual(store.results.count, 10)
    XCTAssertEqual(store.results.first?.workflowName, "Workflow 11")
    XCTAssertEqual(store.results.last?.workflowName, "Workflow 2")
  }

  private func temporaryURL(named fileName: String) throws -> URL {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("DevPilotTests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory.appendingPathComponent(fileName)
  }
}
