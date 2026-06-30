import Foundation

public enum WorkflowCategory: String, CaseIterable, Identifiable, Codable {
  case all = "全部工作流"
  case builtin = "内置模板"
  case custom = "自定义"
  case coding = "开发"
  case study = "学习"
  case school = "课程作业"
  case ai = "AI 辅助"
  case media = "创作"
  case utility = "工具"
  case disabled = "已停用"

  public var id: String { rawValue }

  public var systemImage: String {
    switch self {
    case .all:
      "square.grid.2x2"
    case .builtin:
      "shippingbox"
    case .custom:
      "slider.horizontal.3"
    case .coding:
      "hammer"
    case .study:
      "book"
    case .school:
      "graduationcap"
    case .ai:
      "sparkles"
    case .media:
      "paintbrush"
    case .utility:
      "wrench.and.screwdriver"
    case .disabled:
      "pause.circle"
    }
  }

  public var isFilterOnly: Bool {
    switch self {
    case .all, .builtin, .custom, .disabled:
      true
    case .coding, .study, .school, .ai, .media, .utility:
      false
    }
  }

  public func matches(_ workflow: Workflow) -> Bool {
    switch self {
    case .all:
      true
    case .builtin:
      workflow.isBuiltIn
    case .custom:
      !workflow.isBuiltIn
    case .coding, .study, .school, .ai, .media, .utility:
      workflow.category == self
    case .disabled:
      !workflow.isEnabled
    }
  }
}
