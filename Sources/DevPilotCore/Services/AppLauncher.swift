import AppKit
import Foundation

public protocol AppLaunching: AnyObject {
  func openApp(named name: String) -> Bool
  func openFolder(path: String) -> Bool
  func openURL(_ urlString: String) -> Bool
}

public final class AppLauncher: AppLaunching {
  private let workspace: NSWorkspace

  public init(workspace: NSWorkspace = .shared) {
    self.workspace = workspace
  }

  public func openApp(named name: String) -> Bool {
    let expandedPath = FilePathHelper.expandTilde(in: name)
    if expandedPath.hasSuffix(".app"),
       FileManager.default.fileExists(atPath: expandedPath) {
      return workspace.open(URL(fileURLWithPath: expandedPath, isDirectory: true))
    }

    if let bundleIdentifier = bundleIdentifier(for: name),
       let appURL = workspace.urlForApplication(withBundleIdentifier: bundleIdentifier) {
      return workspace.open(appURL)
    }

    for appURL in candidateApplicationURLs(for: name) where FileManager.default.fileExists(atPath: appURL.path) {
      return workspace.open(appURL)
    }

    return false
  }

  public func openFolder(path: String) -> Bool {
    let expandedPath = FilePathHelper.expandTilde(in: path)
    return workspace.open(URL(fileURLWithPath: expandedPath, isDirectory: true))
  }

  public func openURL(_ urlString: String) -> Bool {
    guard let url = URL(string: urlString) else {
      return false
    }
    return workspace.open(url)
  }

  private func bundleIdentifier(for name: String) -> String? {
    switch name {
    case "Visual Studio Code":
      return "com.microsoft.VSCode"
    case "Cursor":
      return "com.todesktop.230313mzl4w4u92"
    case "Terminal":
      return "com.apple.Terminal"
    default:
      return nil
    }
  }

  private func candidateApplicationURLs(for name: String) -> [URL] {
    [
      "/Applications/\(name).app",
      "/System/Applications/\(name).app",
      "/System/Applications/Utilities/\(name).app",
      "\(NSHomeDirectory())/Applications/\(name).app"
    ].map { URL(fileURLWithPath: $0) }
  }
}
