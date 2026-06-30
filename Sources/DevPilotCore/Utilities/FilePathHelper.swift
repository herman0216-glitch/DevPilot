import Foundation

public enum FilePathHelper {
  public static var downloadsDirectory: URL {
    FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
      ?? URL(fileURLWithPath: "\(NSHomeDirectory())/Downloads", isDirectory: true)
  }

  public static func expandTilde(in path: String) -> String {
    (path as NSString).expandingTildeInPath
  }

  public static func shellQuoted(_ value: String) -> String {
    "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
  }
}
