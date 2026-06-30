import XCTest
@testable import DevPilotCore

final class WorkflowRunnerTests: XCTestCase {
  func testRunExecutesEnabledActionsInOrderThroughDedicatedServices() async throws {
    let launcher = RecordingAppLauncher()
    let shell = RecordingShellRunner()
    let runner = WorkflowRunner(appLauncher: launcher, shellRunner: shell)
    let workflow = Workflow(
      id: UUID(),
      name: "F1 数据项目模式",
      description: "Open the default development setup.",
      icon: "car",
      colorName: nil,
      isBuiltIn: false,
      isEnabled: true,
      showInHome: true,
      showInMenuBar: true,
      actions: [
        WorkflowAction(type: .openApp, title: "Open editor", value: "Visual Studio Code"),
        WorkflowAction(type: .openFolder, title: "Open project", value: "/tmp/project"),
        WorkflowAction(type: .openURL, title: "Open localhost", value: "http://localhost:3000"),
        WorkflowAction(type: .runShellCommand, title: "Start server", value: "npm run dev"),
        WorkflowAction(type: .openApp, title: "Disabled action", value: "Notes", isEnabled: false)
      ],
      createdAt: Date(timeIntervalSince1970: 1),
      updatedAt: Date(timeIntervalSince1970: 1)
    )

    let result = await runner.run(workflow)

    XCTAssertTrue(result.success)
    XCTAssertEqual(result.workflowName, "F1 数据项目模式")
    XCTAssertEqual(result.actionResults.map(\.success), [true, true, true, true])
    XCTAssertEqual(result.actionResults.map(\.actionTitle), ["Open editor", "Open project", "Open localhost", "Start server"])
    XCTAssertEqual(launcher.events, [
      "app:Visual Studio Code",
      "folder:/tmp/project",
      "url:http://localhost:3000"
    ])
    XCTAssertEqual(shell.commands, ["npm run dev"])
  }

  func testRunStopsAfterFailedActionUnlessContinueOnFailureIsEnabled() async throws {
    let launcher = RecordingAppLauncher()
    launcher.appsToFail.insert("Missing App")
    let shell = RecordingShellRunner()
    let runner = WorkflowRunner(appLauncher: launcher, shellRunner: shell)
    let workflow = Workflow.makeTestWorkflow(actions: [
      WorkflowAction(type: .openApp, title: "Missing", value: "Missing App", continueOnFailure: false),
      WorkflowAction(type: .openURL, title: "Should not run", value: "https://chatgpt.com")
    ])

    let result = await runner.run(workflow)

    XCTAssertFalse(result.success)
    XCTAssertEqual(result.actionResults.count, 1)
    XCTAssertEqual(launcher.events, ["app:Missing App"])
  }

  func testRunBlocksDangerousShellCommand() async throws {
    let runner = WorkflowRunner(appLauncher: RecordingAppLauncher(), shellRunner: RecordingShellRunner())
    let workflow = Workflow.makeTestWorkflow(actions: [
      WorkflowAction(type: .runShellCommand, title: "Danger", value: "sudo rm -rf /", continueOnFailure: true),
      WorkflowAction(type: .openURL, title: "Continue", value: "https://chatgpt.com")
    ])

    let result = await runner.run(workflow)

    XCTAssertFalse(result.actionResults[0].success)
    XCTAssertEqual(result.actionResults[0].error, "Command is blocked by DevPilot safety rules.")
    XCTAssertEqual(result.actionResults[1].success, true)
  }
}

private final class RecordingAppLauncher: AppLaunching {
  var events: [String] = []
  var appsToFail: Set<String> = []

  func openApp(named name: String) -> Bool {
    events.append("app:\(name)")
    return !appsToFail.contains(name)
  }

  func openFolder(path: String) -> Bool {
    events.append("folder:\(path)")
    return true
  }

  func openURL(_ urlString: String) -> Bool {
    events.append("url:\(urlString)")
    return true
  }
}

private final class RecordingShellRunner: ShellRunning {
  var commands: [String] = []

  func run(_ command: String, workingDirectory: String? = nil) async -> ShellCommandResult {
    commands.append(command)
    return .success(stdout: "ok")
  }
}

private extension Workflow {
  static func makeTestWorkflow(actions: [WorkflowAction]) -> Workflow {
    Workflow(
      id: UUID(),
      name: "测试工作流",
      description: "Used by tests.",
      icon: "hammer",
      colorName: nil,
      isBuiltIn: false,
      isEnabled: true,
      showInHome: true,
      showInMenuBar: false,
      actions: actions,
      createdAt: Date(timeIntervalSince1970: 1),
      updatedAt: Date(timeIntervalSince1970: 1)
    )
  }
}
