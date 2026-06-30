import Foundation

public struct DevToolStatus: Identifiable, Equatable {
  public let id: String
  public let name: String
  public let category: DevToolCategory
  public let installed: Bool
  public let version: String?
  public let path: String?
  public let errorMessage: String?
  public let installHint: String?
  public let description: String?

  public init(
    id: String,
    name: String,
    category: DevToolCategory,
    installed: Bool,
    version: String? = nil,
    path: String? = nil,
    errorMessage: String? = nil,
    installHint: String? = nil,
    description: String? = nil
  ) {
    self.id = id
    self.name = name
    self.category = category
    self.installed = installed
    self.version = version
    self.path = path
    self.errorMessage = errorMessage
    self.installHint = installHint
    self.description = description
  }
}

public enum DevToolCategory: String, CaseIterable, Identifiable, Equatable, Hashable, Codable {
  case basic = "基础工具"
  case homebrew = "Homebrew"
  case apple = "Apple 原生开发"
  case web = "Web 前端"
  case pythonAI = "Python / AI"
  case javaBackend = "Java / 后端"
  case database = "数据库"
  case devops = "容器与 DevOps"
  case mobile = "移动端"
  case editorAI = "编辑器与 AI 工具"

  public var id: String { rawValue }
}

public struct DevToolDefinition: Identifiable, Equatable {
  public let id: String
  public let name: String
  public let category: DevToolCategory
  public let pathCommand: String?
  public let versionCommand: String?
  public let fallbackPaths: [String]
  public let installHint: String?
  public let description: String?

  public init(
    id: String,
    name: String,
    category: DevToolCategory,
    pathCommand: String? = nil,
    versionCommand: String? = nil,
    fallbackPaths: [String] = [],
    installHint: String? = nil,
    description: String? = nil
  ) {
    self.id = id
    self.name = name
    self.category = category
    self.pathCommand = pathCommand
    self.versionCommand = versionCommand
    self.fallbackPaths = fallbackPaths
    self.installHint = installHint
    self.description = description
  }
}

public struct DevToolCheck: Identifiable, Equatable {
  public var id: String { name }

  public let name: String
  public let executable: String
  public let versionCommand: String

  public init(name: String, executable: String, versionCommand: String) {
    self.name = name
    self.executable = executable
    self.versionCommand = versionCommand
  }

  public var definition: DevToolDefinition {
    DevToolDefinition(
      id: executable,
      name: name,
      category: .basic,
      pathCommand: "command -v \(executable)",
      versionCommand: versionCommand
    )
  }
}
