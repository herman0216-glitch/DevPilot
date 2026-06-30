import XCTest
@testable import DevPilotCore

final class EnvironmentCheckerTests: XCTestCase {
  func testCheckAllReportsInstalledToolWithCategoryVersionAndPath() async {
    let shell = FakeShellRunner(results: [
      "command -v git": .success(stdout: "/usr/bin/git\n"),
      "git --version": .success(stdout: "git version 2.45.0\n")
    ])
    let checker = EnvironmentChecker(
      shellRunner: shell,
      toolDefinitions: [
        DevToolDefinition(
          id: "git",
          name: "Git",
          category: .basic,
          pathCommand: "command -v git",
          versionCommand: "git --version",
          installHint: "brew install git",
          description: "Distributed version control."
        )
      ]
    )

    let statuses = await checker.checkAll()

    XCTAssertEqual(statuses.count, 1)
    XCTAssertEqual(statuses[0].id, "git")
    XCTAssertEqual(statuses[0].name, "Git")
    XCTAssertEqual(statuses[0].category, .basic)
    XCTAssertTrue(statuses[0].installed)
    XCTAssertEqual(statuses[0].version, "git version 2.45.0")
    XCTAssertEqual(statuses[0].path, "/usr/bin/git")
    XCTAssertEqual(statuses[0].installHint, "brew install git")
    XCTAssertEqual(statuses[0].description, "Distributed version control.")
    XCTAssertNil(statuses[0].errorMessage)
  }

  func testCheckAllReportsMissingToolWithInstallHintWithoutCrashing() async {
    let shell = FakeShellRunner(results: [
      "command -v codex": .failure(stderr: "codex not found", exitCode: 1),
      "test -e '/opt/homebrew/bin/codex' && printf '%s\\n' '/opt/homebrew/bin/codex'": .failure(exitCode: 1)
    ])
    let checker = EnvironmentChecker(
      shellRunner: shell,
      toolDefinitions: [
        DevToolDefinition(
          id: "codex",
          name: "Codex CLI",
          category: .editorAI,
          pathCommand: "command -v codex",
          versionCommand: "codex --version",
          fallbackPaths: ["/opt/homebrew/bin/codex"],
          installHint: "按官方安装方式安装 Codex CLI"
        )
      ]
    )

    let statuses = await checker.checkAll()

    XCTAssertEqual(statuses.count, 1)
    XCTAssertEqual(statuses[0].name, "Codex CLI")
    XCTAssertFalse(statuses[0].installed)
    XCTAssertNil(statuses[0].version)
    XCTAssertNil(statuses[0].path)
    XCTAssertEqual(statuses[0].installHint, "按官方安装方式安装 Codex CLI")
    XCTAssertEqual(statuses[0].errorMessage, "codex not found")
  }

  func testToolFallsBackToCommonInstallPathsAndUsesFallbackVersionCommand() async {
    let localCodexPath = "\(NSHomeDirectory())/.local/bin/codex"
    let shell = FakeShellRunner(results: [
      "command -v codex": .failure(stderr: "codex not found", exitCode: 1),
      "test -e '\(localCodexPath)' && printf '%s\\n' '\(localCodexPath)'": .success(stdout: "\(localCodexPath)\n"),
      "'\(localCodexPath)' --version": .success(stdout: "codex-cli 0.142.3\n")
    ])
    let checker = EnvironmentChecker(
      shellRunner: shell,
      toolDefinitions: [
        DevToolDefinition(
          id: "codex",
          name: "Codex CLI",
          category: .editorAI,
          pathCommand: "command -v codex",
          versionCommand: "codex --version",
          fallbackPaths: [localCodexPath]
        )
      ]
    )

    let statuses = await checker.checkAll()

    XCTAssertEqual(statuses.count, 1)
    XCTAssertEqual(statuses[0].name, "Codex CLI")
    XCTAssertTrue(statuses[0].installed)
    XCTAssertEqual(statuses[0].version, "codex-cli 0.142.3")
    XCTAssertEqual(statuses[0].path, localCodexPath)
    XCTAssertNil(statuses[0].errorMessage)
  }

  func testInstalledToolWithFailingVersionStillReportsInstalledWithUnknownVersion() async {
    let shell = FakeShellRunner(results: [
      "command -v dart": .success(stdout: "/opt/homebrew/bin/dart\n"),
      "dart --version": .failure(stderr: "Dart SDK version: 3.5.0\n", exitCode: 1)
    ])
    let checker = EnvironmentChecker(
      shellRunner: shell,
      toolDefinitions: [
        DevToolDefinition(
          id: "dart",
          name: "Dart",
          category: .mobile,
          pathCommand: "command -v dart",
          versionCommand: "dart --version"
        )
      ]
    )

    let statuses = await checker.checkAll()

    XCTAssertTrue(statuses[0].installed)
    XCTAssertEqual(statuses[0].version, "Dart SDK version: 3.5.0")
    XCTAssertNil(statuses[0].errorMessage)
  }

  func testDefaultDefinitionsCoverRequestedMacDeveloperCategoriesAndTools() {
    let definitions = EnvironmentChecker.toolDefinitions
    let categories = Set(definitions.map(\.category))
    let ids = Set(definitions.map(\.id))

    XCTAssertEqual(DevToolCategory.allCases.map(\.rawValue), [
      "基础工具",
      "Homebrew",
      "Apple 原生开发",
      "Web 前端",
      "Python / AI",
      "Java / 后端",
      "数据库",
      "容器与 DevOps",
      "移动端",
      "编辑器与 AI 工具"
    ])
    XCTAssertEqual(definitions.filter { $0.id == "homebrew" }.first?.category, .homebrew)
    XCTAssertEqual(categories, Set(DevToolCategory.allCases))
    XCTAssertGreaterThanOrEqual(definitions.count, 50)
    [
      "homebrew", "git", "zsh", "curl", "wget", "cmake",
      "xcode-command-line-tools", "xcode", "swift", "clang",
      "node", "npm", "pnpm", "yarn", "bun", "deno", "vite", "typescript",
      "python3", "pip3", "java", "maven", "gradle", "go", "rustc", "cargo", "dotnet",
      "mysql", "postgresql", "redis", "mongosh", "sqlite",
      "docker", "docker-compose", "kubectl", "helm", "terraform",
      "android-studio", "android-sdk", "adb", "flutter", "dart", "cocoapods",
      "conda", "jupyter", "uv", "pipx", "ollama",
      "vscode-cli", "cursor-cli", "codex", "claude", "gemini"
    ].forEach { id in
      XCTAssertTrue(ids.contains(id), "Missing tool definition: \(id)")
    }
  }
}

private final class FakeShellRunner: ShellRunning {
  let results: [String: ShellCommandResult]

  init(results: [String: ShellCommandResult]) {
    self.results = results
  }

  func run(_ command: String, workingDirectory: String? = nil) async -> ShellCommandResult {
    results[command] ?? .failure(stderr: "Missing fake result for \(command)", exitCode: 127)
  }
}
