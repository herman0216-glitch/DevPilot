import Foundation

public enum AppPage: String, CaseIterable, Identifiable {
  case home
  case workflows
  case environment
  case commands
  case fileOrganizer
  case settings

  public var id: String { rawValue }

  public var title: String {
    switch self {
    case .home:
      "首页"
    case .workflows:
      "工作流"
    case .environment:
      "环境检测"
    case .commands:
      "常用命令"
    case .fileOrganizer:
      "下载整理"
    case .settings:
      "设置"
    }
  }

  public var systemImage: String {
    switch self {
    case .home:
      "house"
    case .workflows:
      "play.rectangle"
    case .environment:
      "terminal"
    case .commands:
      "command"
    case .fileOrganizer:
      "folder"
    case .settings:
      "gearshape"
    }
  }
}
