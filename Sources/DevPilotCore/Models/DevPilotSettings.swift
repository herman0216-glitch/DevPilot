import Foundation

public enum CodeEditor: String, CaseIterable, Identifiable, Codable {
  case vsCode = "VS Code"
  case cursor = "Cursor"

  public var id: String { rawValue }

  public var appName: String {
    switch self {
    case .vsCode:
      return "Visual Studio Code"
    case .cursor:
      return "Cursor"
    }
  }
}

public struct DevPilotSettings: Equatable, Codable {
  public let defaultProjectFolder: String
  public let defaultBrowserURL: String
  public let shouldRunNpmDev: Bool
  public let selectedEditor: CodeEditor

  public init(
    defaultProjectFolder: String,
    defaultBrowserURL: String,
    shouldRunNpmDev: Bool,
    selectedEditor: CodeEditor
  ) {
    self.defaultProjectFolder = defaultProjectFolder
    self.defaultBrowserURL = defaultBrowserURL
    self.shouldRunNpmDev = shouldRunNpmDev
    self.selectedEditor = selectedEditor
  }
}
