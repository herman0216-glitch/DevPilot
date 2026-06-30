import DevPilotCore
import Foundation

@MainActor
final class AppState: ObservableObject {
  @Published var selectedPage: AppPage = .home
  @Published var environmentStatuses: [DevToolStatus] = []
  @Published var isCheckingEnvironment = false
  @Published var organizeResult: FileOrganizeResult?
  @Published var lastWorkflowResult: WorkflowRunResult?
  @Published var workflowRunHistory: [WorkflowRunResult] = []
  @Published var workflows: [Workflow] = []
  @Published var isRunningWorkflow = false
  @Published var selectedCommand: CommandSnippet = CommandSnippet.builtInCommands[0]
  @Published var commandOutput = ""
  @Published var commandIsRunning = false
  @Published var commandExitCode: Int32?
  @Published var commandWorkingDirectory: String {
    didSet { defaults.set(commandWorkingDirectory, forKey: Keys.commandWorkingDirectory) }
  }

  @Published var autoCheckEnvironmentOnLaunch: Bool {
    didSet { defaults.set(autoCheckEnvironmentOnLaunch, forKey: Keys.autoCheckEnvironmentOnLaunch) }
  }

  @Published var defaultProjectFolder: String {
    didSet { defaults.set(defaultProjectFolder, forKey: Keys.defaultProjectFolder) }
  }

  @Published var defaultBrowserURL: String {
    didSet { defaults.set(defaultBrowserURL, forKey: Keys.defaultBrowserURL) }
  }

  @Published var shouldRunNpmDev: Bool {
    didSet { defaults.set(shouldRunNpmDev, forKey: Keys.shouldRunNpmDev) }
  }

  @Published var selectedEditor: CodeEditor {
    didSet { defaults.set(selectedEditor.rawValue, forKey: Keys.selectedEditor) }
  }

  private let defaults: UserDefaults
  private let shellRunner: ShellRunner
  private let environmentChecker: EnvironmentChecker
  private let fileOrganizer: FileOrganizer
  private let workflowRunner: WorkflowRunner
  private let workflowStore: WorkflowStore
  private let workflowHistoryStore: WorkflowRunHistoryStore
  private let commandSafetyValidator: CommandSafetyValidator

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    shellRunner = ShellRunner()
    environmentChecker = EnvironmentChecker(shellRunner: shellRunner)
    fileOrganizer = FileOrganizer()
    commandSafetyValidator = CommandSafetyValidator()
    workflowRunner = WorkflowRunner(appLauncher: AppLauncher(), shellRunner: shellRunner, commandSafetyValidator: commandSafetyValidator)
    workflowStore = WorkflowStore()
    workflowHistoryStore = WorkflowRunHistoryStore(limit: 10)

    let projectFolder = defaults.string(forKey: Keys.defaultProjectFolder) ?? "\(NSHomeDirectory())/Developer"
    defaultProjectFolder = projectFolder
    defaultBrowserURL = defaults.string(forKey: Keys.defaultBrowserURL) ?? "http://localhost:3000"
    shouldRunNpmDev = defaults.object(forKey: Keys.shouldRunNpmDev) as? Bool ?? false
    let editorRawValue = defaults.string(forKey: Keys.selectedEditor) ?? CodeEditor.vsCode.rawValue
    selectedEditor = CodeEditor(rawValue: editorRawValue) ?? .vsCode
    commandWorkingDirectory = defaults.string(forKey: Keys.commandWorkingDirectory) ?? projectFolder
    autoCheckEnvironmentOnLaunch = defaults.object(forKey: Keys.autoCheckEnvironmentOnLaunch) as? Bool ?? true

    workflowStore.load()
    workflows = workflowStore.workflows
    workflowRunHistory = workflowHistoryStore.results
    lastWorkflowResult = workflowRunHistory.first
  }

  var environmentPathSummary: String {
    ProcessInfo.processInfo.environment["PATH"] ?? "(未设置 PATH)"
  }

  func openMainWindow(page: AppPage? = nil) {
    if let page {
      switchToPage(page)
    }
  }

  func switchToPage(_ page: AppPage) {
    selectedPage = page
  }

  func refreshEnvironment() async {
    isCheckingEnvironment = true
    environmentStatuses = await environmentChecker.checkAll()
    isCheckingEnvironment = false
  }

  func organizeDownloads() async {
    do {
      organizeResult = try fileOrganizer.organizeDownloads()
    } catch {
      organizeResult = FileOrganizeResult(
        scannedCount: 0,
        movedCount: 0,
        skippedCount: 0,
        errors: [FileOrganizeError(fileName: "Downloads", message: error.localizedDescription)]
      )
    }
  }

  func showFileOrganizerResult(_ result: FileOrganizeResult) {
    organizeResult = result
    selectedPage = .fileOrganizer
  }

  func runDevelopmentMode() async {
    guard let workflow = workflows.first(where: { $0.name == "开始写代码" }) ?? workflows.first(where: { $0.showInHome && $0.isEnabled }) else {
      return
    }
    await runWorkflow(workflow)
  }

  func runWorkflow(_ workflow: Workflow) async {
    isRunningWorkflow = true
    let result = await workflowRunner.run(workflow)
    lastWorkflowResult = result
    workflowHistoryStore.record(result)
    workflowRunHistory = workflowHistoryStore.results
    isRunningWorkflow = false
  }

  func markReservedMode(_ name: String) {
    let actionResult = WorkflowActionResult(
      actionId: UUID(),
      actionTitle: name,
      actionType: .openApp,
      success: true,
      message: "\(name) 已预留入口，后续可配置课程文件夹、学习资料和常用网站。"
    )
    lastWorkflowResult = WorkflowRunResult(
      workflowId: UUID(),
      workflowName: name,
      startedAt: Date(),
      finishedAt: Date(),
      success: true,
      actionResults: [actionResult]
    )
  }

  func createWorkflow(_ workflow: Workflow) {
    workflowStore.create(workflow)
    syncWorkflowsFromStore()
  }

  func updateWorkflow(_ workflow: Workflow) {
    workflowStore.update(workflow)
    syncWorkflowsFromStore()
  }

  func deleteWorkflow(_ workflow: Workflow) {
    workflowStore.delete(workflow)
    syncWorkflowsFromStore()
  }

  func duplicateWorkflow(_ workflow: Workflow) {
    workflowStore.duplicate(workflow)
    syncWorkflowsFromStore()
  }

  func resetDefaultWorkflowTemplates() {
    workflowStore.resetBuiltInTemplates()
    syncWorkflowsFromStore()
  }

  func riskLevel(for action: WorkflowAction) -> CommandRiskLevel? {
    guard action.type == .runShellCommand else {
      return nil
    }
    return commandSafetyValidator.evaluate(action.value)
  }

  func riskReason(for action: WorkflowAction) -> String? {
    guard action.type == .runShellCommand else {
      return nil
    }
    return commandSafetyValidator.reason(for: action.value)
  }

  func runSelectedCommand() async {
    await runCommand(selectedCommand)
  }

  func runCommand(_ snippet: CommandSnippet) async {
    guard snippet.isBuiltInSafeCommand else {
      commandOutput = "已阻止非内置命令：\(snippet.command)"
      commandExitCode = 126
      return
    }

    guard snippet.runMode != .copyOnly else {
      commandOutput = "此命令只适合复制到终端执行：\n\(snippet.command)"
      commandExitCode = nil
      return
    }

    guard snippet.isSafeToRun else {
      commandOutput = "此命令未开放直接执行：\(snippet.command)"
      commandExitCode = 126
      return
    }

    let workingDirectory = snippet.workingDirectoryRequired ? commandWorkingDirectory.trimmingCharacters(in: .whitespacesAndNewlines) : nil
    if snippet.workingDirectoryRequired, workingDirectory?.isEmpty != false {
      commandOutput = "该命令需要先选择项目目录。"
      commandExitCode = nil
      return
    }

    commandIsRunning = true
    commandOutput = "Running: \(snippet.command)\n"
    let result = await shellRunner.run(snippet.command, workingDirectory: workingDirectory)
    commandExitCode = result.exitCode
    commandOutput = formattedCommandOutput(snippet, result: result, workingDirectory: workingDirectory)
    commandIsRunning = false
  }

  private func formattedCommandOutput(
    _ snippet: CommandSnippet,
    result: ShellCommandResult,
    workingDirectory: String?
  ) -> String {
    let stdout = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    let stderr = result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
    return """
    命令:
    \(snippet.command)

    工作目录:
    \(workingDirectory ?? "(未指定)")

    Exit code:
    \(result.exitCode)

    耗时:
    \(String(format: "%.2f", result.duration))s

    stdout:
    \(stdout.isEmpty ? "(无)" : stdout)

    stderr:
    \(stderr.isEmpty ? "(无)" : stderr)
    """
  }

  private func syncWorkflowsFromStore() {
    workflows = workflowStore.workflows
  }

  private enum Keys {
    static let defaultProjectFolder = "defaultProjectFolder"
    static let defaultBrowserURL = "defaultBrowserURL"
    static let shouldRunNpmDev = "shouldRunNpmDev"
    static let selectedEditor = "selectedEditor"
    static let commandWorkingDirectory = "commandWorkingDirectory"
    static let autoCheckEnvironmentOnLaunch = "autoCheckEnvironmentOnLaunch"
  }
}
