import Foundation

public struct Workflow: Identifiable, Equatable, Codable {
  public var id: UUID
  public var name: String
  public var description: String
  public var icon: String
  public var category: WorkflowCategory
  public var colorName: String?
  public var isBuiltIn: Bool
  public var isEnabled: Bool
  public var showInHome: Bool
  public var showInMenuBar: Bool
  public var actions: [WorkflowAction]
  public var createdAt: Date
  public var updatedAt: Date

  public init(
    id: UUID = UUID(),
    name: String,
    description: String,
    icon: String,
    category: WorkflowCategory = .custom,
    colorName: String? = nil,
    isBuiltIn: Bool,
    isEnabled: Bool = true,
    showInHome: Bool = true,
    showInMenuBar: Bool = true,
    actions: [WorkflowAction],
    createdAt: Date = Date(),
    updatedAt: Date = Date()
  ) {
    self.id = id
    self.name = name
    self.description = description
    self.icon = icon
    self.category = category
    self.colorName = colorName
    self.isBuiltIn = isBuiltIn
    self.isEnabled = isEnabled
    self.showInHome = showInHome
    self.showInMenuBar = showInMenuBar
    self.actions = actions
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  private enum CodingKeys: String, CodingKey {
    case id
    case name
    case description
    case icon
    case category
    case colorName
    case isBuiltIn
    case isEnabled
    case showInHome
    case showInMenuBar
    case actions
    case createdAt
    case updatedAt
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(UUID.self, forKey: .id)
    name = try container.decode(String.self, forKey: .name)
    description = try container.decode(String.self, forKey: .description)
    icon = try container.decode(String.self, forKey: .icon)
    colorName = try container.decodeIfPresent(String.self, forKey: .colorName)
    isBuiltIn = try container.decode(Bool.self, forKey: .isBuiltIn)
    isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
    showInHome = try container.decode(Bool.self, forKey: .showInHome)
    showInMenuBar = try container.decode(Bool.self, forKey: .showInMenuBar)
    actions = try container.decode([WorkflowAction].self, forKey: .actions)
    createdAt = try container.decode(Date.self, forKey: .createdAt)
    updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    category = try container.decodeIfPresent(WorkflowCategory.self, forKey: .category)
      ?? Workflow.legacyCategoryFallback(name: name, isBuiltIn: isBuiltIn)
  }
}

public extension Workflow {
  static func customTemplate(name: String = "新的工作流") -> Workflow {
    Workflow(
      name: name,
      description: "描述这个工作流会帮你打开什么、运行什么。",
      icon: "sparkles",
      category: .custom,
      isBuiltIn: false,
      actions: []
    )
  }

  static func defaultTemplates(now: Date = Date()) -> [Workflow] {
    [
      Workflow(
        name: "开始写代码",
        description: "打开编辑器、Terminal、默认项目文件夹和本地开发地址。",
        icon: "hammer",
        category: .coding,
        isBuiltIn: true,
        actions: [
          WorkflowAction(type: .openApp, title: "打开默认代码编辑器", value: "Visual Studio Code"),
          WorkflowAction(type: .openApp, title: "打开 Terminal", value: "Terminal"),
          WorkflowAction(type: .openFolder, title: "打开默认项目文件夹", value: "\(NSHomeDirectory())/Developer"),
          WorkflowAction(type: .openURL, title: "打开 localhost", value: "http://localhost:3000")
        ],
        createdAt: now,
        updatedAt: now
      ),
      Workflow(
        name: "开始学习",
        description: "打开学习资料、ChatGPT、学习网站和笔记 App。",
        icon: "book",
        category: .study,
        isBuiltIn: true,
        actions: [
          WorkflowAction(type: .openFolder, title: "打开学习资料文件夹", value: "\(NSHomeDirectory())/Documents"),
          WorkflowAction(type: .openURL, title: "打开 ChatGPT", value: "https://chatgpt.com"),
          WorkflowAction(type: .openURL, title: "打开学习网站", value: "https://developer.apple.com"),
          WorkflowAction(type: .openApp, title: "打开笔记软件", value: "Notes")
        ],
        createdAt: now,
        updatedAt: now
      ),
      Workflow(
        name: "开始做作业",
        description: "打开课程资料、文档编辑器和作业提交网站。",
        icon: "graduationcap",
        category: .school,
        isBuiltIn: true,
        actions: [
          WorkflowAction(type: .openFolder, title: "打开课程资料文件夹", value: "\(NSHomeDirectory())/Documents"),
          WorkflowAction(type: .openApp, title: "打开文档编辑器", value: "Pages"),
          WorkflowAction(type: .openURL, title: "打开作业提交网站", value: "https://canvas.instructure.com")
        ],
        createdAt: now,
        updatedAt: now
      )
    ]
  }

  static func legacyCategoryFallback(name: String, isBuiltIn: Bool) -> WorkflowCategory {
    switch name {
    case "开始写代码":
      return .coding
    case "开始学习":
      return .study
    case "开始做作业":
      return .school
    default:
      return isBuiltIn ? .builtin : .custom
    }
  }
}
