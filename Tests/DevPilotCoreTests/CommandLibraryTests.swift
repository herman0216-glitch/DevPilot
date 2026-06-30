import XCTest
@testable import DevPilotCore

final class CommandLibraryTests: XCTestCase {
  func testCommandCategoriesUseSharedInformationArchitectureAndHaveCommands() {
    let expectedCategoryTitles = [
      "基础工具",
      "Homebrew",
      "Apple 原生开发",
      "Web 前端",
      "Python / AI",
      "Java / 后端",
      "数据库",
      "容器与 DevOps",
      "移动端",
      "编辑器与 AI 工具",
      "项目常用",
      "Git 工作流",
      "系统诊断"
    ]

    XCTAssertEqual(CommandCategory.allCases.map(\.rawValue), expectedCategoryTitles)
    XCTAssertEqual(CommandCategory.allCases.prefix(10).map(\.rawValue), DevToolCategory.allCases.map(\.rawValue))

    let categoriesWithCommands = Set(CommandSnippet.builtInCommands.map(\.category))
    CommandCategory.allCases.forEach { category in
      XCTAssertTrue(categoriesWithCommands.contains(category), "Missing commands for \(category.rawValue)")
    }
  }

  func testHomebrewCommandsLiveInDedicatedCategoryAndCoverCommonMacWorkflows() {
    let commandsByCommand = Dictionary(uniqueKeysWithValues: CommandSnippet.builtInCommands.map { ($0.command, $0) })
    let expectedHomebrewCommands = [
      "brew --version",
      "brew update",
      "brew upgrade",
      "brew doctor",
      "brew config",
      "brew list",
      "brew list --cask",
      "brew outdated",
      "brew search",
      "brew info",
      "brew cleanup -n",
      "brew services list"
    ]

    expectedHomebrewCommands.forEach { command in
      XCTAssertEqual(commandsByCommand[command]?.category, .homebrew, "Expected \(command) to be in Homebrew")
    }

    XCTAssertGreaterThanOrEqual(CommandSnippet.builtInCommands.filter { $0.category == .homebrew }.count, 12)
  }

  func testBuiltInCommandsAreAllAllowlistedCategorizedAndNonDangerous() {
    let commands = CommandSnippet.builtInCommands

    XCTAssertGreaterThanOrEqual(commands.count, 75)
    XCTAssertTrue(commands.allSatisfy(\.isBuiltInSafeCommand))
    XCTAssertFalse(commands.contains { $0.command.contains("rm -rf") })
    XCTAssertFalse(commands.contains { $0.command.contains("sudo rm") })
    XCTAssertFalse(commands.contains { $0.command.contains("diskutil erase") })
    XCTAssertFalse(commands.contains { $0.command.contains("mkfs") })
    XCTAssertTrue(commands.allSatisfy { !$0.description.isEmpty })
    XCTAssertTrue(commands.contains { $0.command == "codex --version" })
    XCTAssertEqual(Set(commands.map(\.category)), Set(CommandCategory.allCases))
  }

  func testProjectCommandsRequireWorkingDirectoryAndActivateIsCopyOnly() {
    let commandsByCommand = Dictionary(uniqueKeysWithValues: CommandSnippet.builtInCommands.map { ($0.command, $0) })

    ["git status", "npm install", "npm run dev", "cargo build", "cargo test"].forEach { command in
      XCTAssertEqual(commandsByCommand[command]?.runMode, .requiresProjectDirectory)
      XCTAssertEqual(commandsByCommand[command]?.workingDirectoryRequired, true)
    }

    XCTAssertEqual(commandsByCommand["source .venv/bin/activate"]?.runMode, .copyOnly)
    XCTAssertEqual(commandsByCommand["source .venv/bin/activate"]?.isSafeToRun, false)
  }
}
