import Foundation

public struct ShellCommandResult: Equatable {
  public let stdout: String
  public let stderr: String
  public let exitCode: Int32
  public let duration: TimeInterval

  public init(stdout: String, stderr: String, exitCode: Int32, duration: TimeInterval = 0) {
    self.stdout = stdout
    self.stderr = stderr
    self.exitCode = exitCode
    self.duration = duration
  }

  public var succeeded: Bool {
    exitCode == 0
  }

  public var combinedOutput: String {
    [stdout, stderr]
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
      .joined(separator: "\n")
  }

  public static func success(stdout: String = "", stderr: String = "", exitCode: Int32 = 0) -> ShellCommandResult {
    ShellCommandResult(stdout: stdout, stderr: stderr, exitCode: exitCode)
  }

  public static func failure(stdout: String = "", stderr: String = "", exitCode: Int32 = 1) -> ShellCommandResult {
    ShellCommandResult(stdout: stdout, stderr: stderr, exitCode: exitCode)
  }
}
