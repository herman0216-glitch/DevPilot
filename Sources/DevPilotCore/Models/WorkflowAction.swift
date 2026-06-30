import Foundation

public enum WorkflowActionType: String, Codable, CaseIterable, Identifiable {
  case openApp
  case openFolder
  case openURL
  case runShellCommand

  public var id: String { rawValue }

  public var displayName: String {
    switch self {
    case .openApp: "打开 App"
    case .openFolder: "打开文件夹"
    case .openURL: "打开网址"
    case .runShellCommand: "执行命令"
    }
  }
}

public struct WorkflowAction: Identifiable, Equatable, Codable {
  public var id: UUID
  public var type: WorkflowActionType
  public var title: String
  public var value: String
  public var isEnabled: Bool
  public var requiresConfirmation: Bool
  public var workingDirectory: String?
  public var continueOnFailure: Bool

  public init(
    id: UUID = UUID(),
    type: WorkflowActionType,
    title: String,
    value: String,
    isEnabled: Bool = true,
    requiresConfirmation: Bool? = nil,
    workingDirectory: String? = nil,
    continueOnFailure: Bool = true
  ) {
    self.id = id
    self.type = type
    self.title = title
    self.value = value
    self.isEnabled = isEnabled
    self.requiresConfirmation = requiresConfirmation ?? (type == .runShellCommand)
    self.workingDirectory = workingDirectory
    self.continueOnFailure = continueOnFailure
  }
}

public struct WorkflowRunResult: Identifiable, Equatable, Codable {
  public var id: UUID
  public var workflowId: UUID
  public var workflowName: String
  public var startedAt: Date
  public var finishedAt: Date
  public var success: Bool
  public var actionResults: [WorkflowActionResult]

  public init(
    id: UUID = UUID(),
    workflowId: UUID,
    workflowName: String,
    startedAt: Date,
    finishedAt: Date,
    success: Bool,
    actionResults: [WorkflowActionResult]
  ) {
    self.id = id
    self.workflowId = workflowId
    self.workflowName = workflowName
    self.startedAt = startedAt
    self.finishedAt = finishedAt
    self.success = success
    self.actionResults = actionResults
  }

  public var succeeded: Bool { success }
  public var messages: [String] { actionResults.filter(\.success).map(\.message) }
  public var errors: [String] { actionResults.compactMap(\.error) }
}

public struct WorkflowActionResult: Identifiable, Equatable, Codable {
  public var id: UUID
  public var actionId: UUID
  public var actionTitle: String
  public var actionType: WorkflowActionType
  public var success: Bool
  public var message: String
  public var output: String?
  public var error: String?

  public init(
    id: UUID = UUID(),
    actionId: UUID,
    actionTitle: String,
    actionType: WorkflowActionType,
    success: Bool,
    message: String,
    output: String? = nil,
    error: String? = nil
  ) {
    self.id = id
    self.actionId = actionId
    self.actionTitle = actionTitle
    self.actionType = actionType
    self.success = success
    self.message = message
    self.output = output
    self.error = error
  }
}
