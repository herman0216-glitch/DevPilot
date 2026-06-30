import Foundation

public final class WorkflowRunner {
  private let appLauncher: AppLaunching
  private let shellRunner: ShellRunning
  private let commandSafetyValidator: CommandSafetyValidator

  public init(
    appLauncher: AppLaunching = AppLauncher(),
    shellRunner: ShellRunning = ShellRunner(),
    commandSafetyValidator: CommandSafetyValidator = CommandSafetyValidator()
  ) {
    self.appLauncher = appLauncher
    self.shellRunner = shellRunner
    self.commandSafetyValidator = commandSafetyValidator
  }

  public func run(_ workflow: Workflow) async -> WorkflowRunResult {
    let startedAt = Date()
    var actionResults: [WorkflowActionResult] = []

    guard workflow.isEnabled else {
      let finishedAt = Date()
      return WorkflowRunResult(
        workflowId: workflow.id,
        workflowName: workflow.name,
        startedAt: startedAt,
        finishedAt: finishedAt,
        success: false,
        actionResults: [
          WorkflowActionResult(
            actionId: workflow.id,
            actionTitle: workflow.name,
            actionType: .openApp,
            success: false,
            message: "Workflow is disabled.",
            error: "Workflow is disabled."
          )
        ]
      )
    }

    for action in workflow.actions where action.isEnabled {
      let result = await run(action)
      actionResults.append(result)

      if !result.success, !action.continueOnFailure {
        break
      }
    }

    let finishedAt = Date()
    return WorkflowRunResult(
      workflowId: workflow.id,
      workflowName: workflow.name,
      startedAt: startedAt,
      finishedAt: finishedAt,
      success: actionResults.allSatisfy(\.success),
      actionResults: actionResults
    )
  }

  private func run(_ action: WorkflowAction) async -> WorkflowActionResult {
    switch action.type {
    case .openApp:
      let success = appLauncher.openApp(named: action.value)
      return WorkflowActionResult(
        actionId: action.id,
        actionTitle: action.title,
        actionType: action.type,
        success: success,
        message: success ? "Opened app: \(action.value)" : "Failed to open app: \(action.value)",
        error: success ? nil : "Failed to open app: \(action.value)"
      )

    case .openFolder:
      let success = appLauncher.openFolder(path: action.value)
      return WorkflowActionResult(
        actionId: action.id,
        actionTitle: action.title,
        actionType: action.type,
        success: success,
        message: success ? "Opened folder: \(action.value)" : "Failed to open folder: \(action.value)",
        error: success ? nil : "Failed to open folder: \(action.value)"
      )

    case .openURL:
      let success = appLauncher.openURL(action.value)
      return WorkflowActionResult(
        actionId: action.id,
        actionTitle: action.title,
        actionType: action.type,
        success: success,
        message: success ? "Opened URL: \(action.value)" : "Failed to open URL: \(action.value)",
        error: success ? nil : "Failed to open URL: \(action.value)"
      )

    case .runShellCommand:
      return await runShellCommand(action)
    }
  }

  private func runShellCommand(_ action: WorkflowAction) async -> WorkflowActionResult {
    let risk = commandSafetyValidator.evaluate(action.value)
    guard risk != .blocked else {
      let reason = commandSafetyValidator.reason(for: action.value) ?? "Command is blocked."
      return WorkflowActionResult(
        actionId: action.id,
        actionTitle: action.title,
        actionType: action.type,
        success: false,
        message: reason,
        error: reason
      )
    }

    let result = await shellRunner.run(action.value, workingDirectory: action.workingDirectory)
    let output = result.combinedOutput.trimmingCharacters(in: .whitespacesAndNewlines)
    if result.succeeded {
      let confirmationNote = risk == .needsConfirmation ? " (needs confirmation)" : ""
      return WorkflowActionResult(
        actionId: action.id,
        actionTitle: action.title,
        actionType: action.type,
        success: true,
        message: "Command succeeded: \(action.value)\(confirmationNote)",
        output: output.isEmpty ? nil : output
      )
    }

    let detail = output.isEmpty ? "exit \(result.exitCode)" : output
    return WorkflowActionResult(
      actionId: action.id,
      actionTitle: action.title,
      actionType: action.type,
      success: false,
      message: "Command failed: \(action.value)",
      output: output.isEmpty ? nil : output,
      error: "Command failed: \(action.value) (\(detail))"
    )
  }
}
