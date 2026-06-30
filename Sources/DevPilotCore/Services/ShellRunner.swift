import Foundation

public protocol ShellRunning: AnyObject {
  func run(_ command: String, workingDirectory: String?) async -> ShellCommandResult
}

public extension ShellRunning {
  func run(_ command: String) async -> ShellCommandResult
  {
    await run(command, workingDirectory: nil)
  }
}

public final class ShellRunner: ShellRunning, @unchecked Sendable {
  private let shellURL: URL
  private let environment: [String: String]
  private let timeout: TimeInterval

  public init(
    shellURL: URL = URL(fileURLWithPath: "/bin/zsh"),
    environment: [String: String]? = nil,
    timeout: TimeInterval = 20
  ) {
    self.shellURL = shellURL
    self.environment = environment ?? ShellRunner.defaultEnvironment()
    self.timeout = timeout
  }

  public func run(_ command: String, workingDirectory: String? = nil) async -> ShellCommandResult {
    await withCheckedContinuation { continuation in
      DispatchQueue.global(qos: .userInitiated).async {
        continuation.resume(returning: self.runSynchronously(command, workingDirectory: workingDirectory))
      }
    }
  }

  private func runSynchronously(_ command: String, workingDirectory: String?) -> ShellCommandResult {
    let startedAt = Date()
    let process = Process()
    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()

    process.executableURL = shellURL
    process.arguments = ["-lc", command]
    process.environment = environment
    if let workingDirectory, !workingDirectory.isEmpty {
      process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory, isDirectory: true)
    }
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe

    do {
      try process.run()
      let semaphore = DispatchSemaphore(value: 0)
      process.terminationHandler = { _ in semaphore.signal() }
      if semaphore.wait(timeout: .now() + timeout) == .timedOut {
        process.terminate()
        let stdout = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return ShellCommandResult(
          stdout: stdout,
          stderr: [stderr, "Command timed out after \(Int(timeout)) seconds"].filter { !$0.isEmpty }.joined(separator: "\n"),
          exitCode: 124,
          duration: Date().timeIntervalSince(startedAt)
        )
      }
      let stdout = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
      let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
      return ShellCommandResult(stdout: stdout, stderr: stderr, exitCode: process.terminationStatus, duration: Date().timeIntervalSince(startedAt))
    } catch {
      return .failure(stderr: error.localizedDescription, exitCode: 127)
    }
  }

  private static func defaultEnvironment() -> [String: String] {
    var environment = ProcessInfo.processInfo.environment
    let requiredPaths = [
      "/opt/homebrew/bin",
      "/usr/local/bin",
      "/usr/bin",
      "/bin",
      "/usr/sbin",
      "/sbin",
      "\(NSHomeDirectory())/.local/bin",
      "\(NSHomeDirectory())/.npm-global/bin",
      "\(NSHomeDirectory())/.cargo/bin",
      "\(NSHomeDirectory())/.bun/bin",
      "\(NSHomeDirectory())/go/bin",
      "/Library/Frameworks/Python.framework/Versions/Current/bin",
      "/opt/homebrew/opt/openjdk/bin",
      "/opt/homebrew/opt/postgresql@16/bin",
      "/opt/homebrew/opt/mysql/bin",
      "/opt/homebrew/share/dotnet",
      "/Applications/Visual Studio Code.app/Contents/Resources/app/bin",
      "/Applications/Cursor.app/Contents/Resources/app/bin",
      "\(NSHomeDirectory())/Library/Android/sdk/platform-tools",
      "\(NSHomeDirectory())/Library/Android/sdk/cmdline-tools/latest/bin",
      "\(NSHomeDirectory())/Library/Android/sdk/emulator"
    ]

    if let existingPath = environment["PATH"], !existingPath.isEmpty {
      let existingPaths = existingPath.components(separatedBy: ":")
      let mergedPaths = requiredPaths + existingPaths.filter { !requiredPaths.contains($0) }
      environment["PATH"] = mergedPaths.joined(separator: ":")
    } else {
      environment["PATH"] = requiredPaths.joined(separator: ":")
    }
    return environment
  }
}
