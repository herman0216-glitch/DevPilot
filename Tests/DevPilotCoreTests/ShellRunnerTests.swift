import XCTest
@testable import DevPilotCore

final class ShellRunnerTests: XCTestCase {
  func testDefaultEnvironmentIncludesGuiAppToolPaths() async {
    let runner = ShellRunner()

    let result = await runner.run("printf '%s' \"$PATH\"")

    XCTAssertTrue(result.succeeded, result.combinedOutput)
    let pathEntries = Set(result.stdout.components(separatedBy: ":"))
    [
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
    ].forEach { expectedPath in
      XCTAssertTrue(pathEntries.contains(expectedPath), "PATH should contain \(expectedPath)")
    }
  }

  func testRunCapturesStdoutStderrExitCodeDurationAndWorkingDirectory() async {
    let runner = ShellRunner(timeout: 5)

    let result = await runner.run(
      "pwd; printf 'out'; printf 'err' >&2; exit 7",
      workingDirectory: NSTemporaryDirectory()
    )

    XCTAssertEqual(result.exitCode, 7)
    XCTAssertTrue(result.stdout.contains(NSTemporaryDirectory().trimmingCharacters(in: CharacterSet(charactersIn: "/"))))
    XCTAssertTrue(result.stdout.contains("out"))
    XCTAssertTrue(result.stderr.contains("err"))
    XCTAssertGreaterThanOrEqual(result.duration, 0)
  }
}
