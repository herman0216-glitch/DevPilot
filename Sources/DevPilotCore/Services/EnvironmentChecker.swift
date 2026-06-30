import Foundation

public final class EnvironmentChecker {
  public static let toolDefinitions: [DevToolDefinition] = [
    .init(id: "git", name: "Git", category: .basic, pathCommand: "command -v git", versionCommand: "git --version", installHint: "brew install git", description: "版本控制工具。"),
    .init(id: "zsh", name: "Zsh", category: .basic, pathCommand: "command -v zsh", versionCommand: "zsh --version", description: "macOS 默认 shell。"),
    .init(id: "curl", name: "Curl", category: .basic, pathCommand: "command -v curl", versionCommand: "curl --version | head -n 1", description: "命令行 HTTP 客户端。"),
    .init(id: "wget", name: "Wget", category: .basic, pathCommand: "command -v wget", versionCommand: "wget --version | head -n 1", installHint: "brew install wget", description: "文件下载工具。"),
    .init(id: "make", name: "Make", category: .basic, pathCommand: "command -v make", versionCommand: "make --version | head -n 1", description: "通用构建工具。"),
    .init(id: "cmake", name: "CMake", category: .basic, pathCommand: "command -v cmake", versionCommand: "cmake --version | head -n 1", installHint: "brew install cmake", description: "跨平台构建系统。"),

    .init(id: "homebrew", name: "Homebrew", category: .homebrew, pathCommand: "command -v brew", versionCommand: "brew --version | head -n 1", installHint: "/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"", description: "macOS 常用包管理器。"),

    .init(id: "xcode-command-line-tools", name: "Xcode Command Line Tools", category: .apple, pathCommand: "xcode-select -p", versionCommand: "xcodebuild -version", installHint: "xcode-select --install", description: "Apple 编译器和命令行开发工具。"),
    .init(id: "xcode", name: "Xcode", category: .apple, versionCommand: "/usr/bin/xcodebuild -version", fallbackPaths: ["/Applications/Xcode.app"], installHint: "App Store 安装 Xcode", description: "Apple 原生应用开发 IDE。"),
    .init(id: "swift", name: "Swift", category: .apple, pathCommand: "command -v swift", versionCommand: "swift --version | head -n 1", description: "Swift 编程语言工具链。"),
    .init(id: "clang", name: "Clang", category: .apple, pathCommand: "command -v clang", versionCommand: "clang --version | head -n 1", description: "C/C++/Objective-C 编译器。"),

    .init(id: "node", name: "Node.js", category: .web, pathCommand: "command -v node", versionCommand: "node -v", installHint: "brew install node", description: "JavaScript 运行时。"),
    .init(id: "npm", name: "npm", category: .web, pathCommand: "command -v npm", versionCommand: "npm -v", description: "Node.js 包管理器。"),
    .init(id: "pnpm", name: "pnpm", category: .web, pathCommand: "command -v pnpm", versionCommand: "pnpm -v", installHint: "npm install -g pnpm 或 brew install pnpm", description: "高性能 Node.js 包管理器。"),
    .init(id: "yarn", name: "Yarn", category: .web, pathCommand: "command -v yarn", versionCommand: "yarn -v", installHint: "brew install yarn", description: "Node.js 包管理器。"),
    .init(id: "bun", name: "Bun", category: .web, pathCommand: "command -v bun", versionCommand: "bun --version", installHint: "brew install bun", description: "JavaScript 运行时和包管理器。"),
    .init(id: "deno", name: "Deno", category: .web, pathCommand: "command -v deno", versionCommand: "deno --version | head -n 1", installHint: "brew install deno", description: "安全默认的 JavaScript/TypeScript 运行时。"),
    .init(id: "vite", name: "Vite", category: .web, pathCommand: "command -v vite", versionCommand: "vite --version", installHint: "npm install -g vite", description: "前端开发服务器和构建工具。"),
    .init(id: "typescript", name: "TypeScript", category: .web, pathCommand: "command -v tsc", versionCommand: "tsc -v", installHint: "npm install -g typescript", description: "TypeScript 编译器。"),

    .init(id: "python3", name: "Python 3", category: .pythonAI, pathCommand: "command -v python3", versionCommand: "python3 --version", installHint: "brew install python", description: "Python 运行时。"),
    .init(id: "pip3", name: "pip3", category: .pythonAI, pathCommand: "command -v pip3", versionCommand: "pip3 --version", description: "Python 包管理器。"),
    .init(id: "conda", name: "Conda", category: .pythonAI, pathCommand: "command -v conda", versionCommand: "conda --version", installHint: "brew install --cask miniconda", description: "Python/数据科学环境管理器。"),
    .init(id: "jupyter", name: "Jupyter", category: .pythonAI, pathCommand: "command -v jupyter", versionCommand: "jupyter --version | head -n 1", installHint: "pip3 install jupyter", description: "交互式数据科学 notebook。"),
    .init(id: "uv", name: "uv", category: .pythonAI, pathCommand: "command -v uv", versionCommand: "uv --version", installHint: "brew install uv", description: "高速 Python 包和环境工具。"),
    .init(id: "pipx", name: "pipx", category: .pythonAI, pathCommand: "command -v pipx", versionCommand: "pipx --version", installHint: "brew install pipx", description: "隔离安装 Python CLI 工具。"),
    .init(id: "ollama", name: "Ollama", category: .pythonAI, pathCommand: "command -v ollama", versionCommand: "ollama --version", installHint: "brew install ollama", description: "本地大模型运行工具。"),

    .init(id: "java", name: "Java", category: .javaBackend, pathCommand: "command -v java", versionCommand: "java -version", description: "Java 运行时。"),
    .init(id: "maven", name: "Maven", category: .javaBackend, pathCommand: "command -v mvn", versionCommand: "mvn -v | head -n 1", installHint: "brew install maven", description: "Java 项目构建工具。"),
    .init(id: "gradle", name: "Gradle", category: .javaBackend, pathCommand: "command -v gradle", versionCommand: "gradle -v | grep Gradle | head -n 1", installHint: "brew install gradle", description: "多语言构建工具。"),
    .init(id: "go", name: "Go", category: .javaBackend, pathCommand: "command -v go", versionCommand: "go version", installHint: "brew install go", description: "Go 语言工具链。"),
    .init(id: "rustc", name: "Rust", category: .javaBackend, pathCommand: "command -v rustc", versionCommand: "rustc --version", installHint: "brew install rust 或 rustup", description: "Rust 编译器。"),
    .init(id: "cargo", name: "Cargo", category: .javaBackend, pathCommand: "command -v cargo", versionCommand: "cargo --version", description: "Rust 包管理和构建工具。"),
    .init(id: "php", name: "PHP", category: .javaBackend, pathCommand: "command -v php", versionCommand: "php -v | head -n 1", installHint: "brew install php", description: "PHP 运行时。"),
    .init(id: "composer", name: "Composer", category: .javaBackend, pathCommand: "command -v composer", versionCommand: "composer --version", installHint: "brew install composer", description: "PHP 包管理器。"),
    .init(id: "ruby", name: "Ruby", category: .javaBackend, pathCommand: "command -v ruby", versionCommand: "ruby -v", description: "Ruby 运行时。"),
    .init(id: "gem", name: "Gem", category: .javaBackend, pathCommand: "command -v gem", versionCommand: "gem -v", description: "Ruby 包管理器。"),
    .init(id: "dotnet", name: ".NET SDK", category: .javaBackend, pathCommand: "command -v dotnet", versionCommand: "dotnet --version", installHint: "brew install --cask dotnet-sdk", description: ".NET 开发工具链。"),

    .init(id: "mysql", name: "MySQL", category: .database, pathCommand: "command -v mysql", versionCommand: "mysql --version", installHint: "brew install mysql", description: "MySQL 客户端和服务工具。"),
    .init(id: "postgresql", name: "PostgreSQL", category: .database, pathCommand: "command -v psql", versionCommand: "psql --version", installHint: "brew install postgresql", description: "PostgreSQL 客户端。"),
    .init(id: "redis", name: "Redis", category: .database, pathCommand: "command -v redis-server", versionCommand: "redis-server --version", installHint: "brew install redis", description: "Redis 服务。"),
    .init(id: "mongosh", name: "MongoDB Shell", category: .database, pathCommand: "command -v mongosh", versionCommand: "mongosh --version", installHint: "brew install mongosh", description: "MongoDB 命令行 shell。"),
    .init(id: "sqlite", name: "SQLite", category: .database, pathCommand: "command -v sqlite3", versionCommand: "sqlite3 --version", description: "macOS 通常自带的轻量数据库。"),

    .init(id: "docker", name: "Docker", category: .devops, pathCommand: "command -v docker", versionCommand: "docker --version", installHint: "brew install --cask docker", description: "Docker CLI；CLI 存在不代表 Docker Desktop 正在运行。"),
    .init(id: "docker-compose", name: "Docker Compose", category: .devops, pathCommand: "command -v docker", versionCommand: "docker compose version", description: "新版 Docker Compose 子命令。"),
    .init(id: "kubectl", name: "kubectl", category: .devops, pathCommand: "command -v kubectl", versionCommand: "kubectl version --client --short || kubectl version --client", installHint: "brew install kubectl", description: "Kubernetes 命令行工具。"),
    .init(id: "helm", name: "Helm", category: .devops, pathCommand: "command -v helm", versionCommand: "helm version --short", installHint: "brew install helm", description: "Kubernetes 包管理器。"),
    .init(id: "terraform", name: "Terraform", category: .devops, pathCommand: "command -v terraform", versionCommand: "terraform version | head -n 1", installHint: "brew install terraform", description: "基础设施即代码工具。"),

    .init(id: "android-studio", name: "Android Studio", category: .mobile, fallbackPaths: ["/Applications/Android Studio.app"], installHint: "brew install --cask android-studio", description: "Android 官方 IDE。"),
    .init(id: "android-sdk", name: "Android SDK", category: .mobile, pathCommand: "printf '%s\\n' \"$ANDROID_HOME\" \"$ANDROID_SDK_ROOT\" | sed '/^$/d' | head -n 1", fallbackPaths: ["\(NSHomeDirectory())/Library/Android/sdk"], description: "Android SDK 路径。"),
    .init(id: "adb", name: "adb", category: .mobile, pathCommand: "command -v adb", versionCommand: "adb version | head -n 1", description: "Android Debug Bridge。"),
    .init(id: "flutter", name: "Flutter", category: .mobile, pathCommand: "command -v flutter", versionCommand: "flutter --version | head -n 1", installHint: "brew install --cask flutter", description: "跨平台应用开发工具链。"),
    .init(id: "dart", name: "Dart", category: .mobile, pathCommand: "command -v dart", versionCommand: "dart --version", description: "Dart 语言工具链。"),
    .init(id: "cocoapods", name: "CocoaPods", category: .mobile, pathCommand: "command -v pod", versionCommand: "pod --version", installHint: "sudo gem install cocoapods 或 brew install cocoapods", description: "iOS/macOS 依赖管理工具。"),

    .init(id: "vscode-cli", name: "VS Code CLI", category: .editorAI, pathCommand: "command -v code", versionCommand: "code --version | head -n 1", installHint: "在 VS Code 中运行 Shell Command: Install 'code' command in PATH", description: "VS Code 命令行入口。"),
    .init(id: "cursor-cli", name: "Cursor CLI", category: .editorAI, pathCommand: "command -v cursor", versionCommand: "cursor --version | head -n 1", installHint: "在 Cursor 中安装 shell command", description: "Cursor 命令行入口。"),
    .init(id: "codex", name: "Codex CLI", category: .editorAI, pathCommand: "command -v codex", versionCommand: "codex --version", fallbackPaths: ["/opt/homebrew/bin/codex", "/usr/local/bin/codex", "\(NSHomeDirectory())/.npm-global/bin/codex", "\(NSHomeDirectory())/.local/bin/codex"], description: "OpenAI Codex 命令行工具。"),
    .init(id: "claude", name: "Claude Code", category: .editorAI, pathCommand: "command -v claude", versionCommand: "claude --version", installHint: "按官方安装方式安装 Claude Code CLI", description: "Claude Code 命令行工具。"),
    .init(id: "gemini", name: "Gemini CLI", category: .editorAI, pathCommand: "command -v gemini", versionCommand: "gemini --version", installHint: "按官方安装方式安装 Gemini CLI", description: "Gemini 命令行工具。")
  ]

  public static let defaultChecks: [DevToolCheck] = toolDefinitions.compactMap { definition in
    guard let pathCommand = definition.pathCommand, pathCommand.hasPrefix("command -v ") else { return nil }
    let executable = String(pathCommand.dropFirst("command -v ".count))
    return DevToolCheck(name: definition.name, executable: executable, versionCommand: definition.versionCommand ?? "\(executable) --version")
  }

  private let shellRunner: ShellRunning
  private let definitions: [DevToolDefinition]

  public init(shellRunner: ShellRunning = ShellRunner(), toolDefinitions: [DevToolDefinition] = EnvironmentChecker.toolDefinitions) {
    self.shellRunner = shellRunner
    self.definitions = toolDefinitions
  }

  public convenience init(shellRunner: ShellRunning = ShellRunner(), checks: [DevToolCheck]) {
    self.init(shellRunner: shellRunner, toolDefinitions: checks.map(\.definition))
  }

  public func checkAll() async -> [DevToolStatus] {
    await withTaskGroup(of: (Int, DevToolStatus).self) { group in
      for (index, definition) in definitions.enumerated() {
        group.addTask { [shellRunner] in
          let checker = ToolCheckOperation(shellRunner: shellRunner, definition: definition)
          return (index, await checker.run())
        }
      }

      var indexedStatuses: [(Int, DevToolStatus)] = []
      for await status in group {
        indexedStatuses.append(status)
      }
      return indexedStatuses.sorted { $0.0 < $1.0 }.map(\.1)
    }
  }
}

private struct ToolCheckOperation {
  let shellRunner: ShellRunning
  let definition: DevToolDefinition

  func run() async -> DevToolStatus {
    let pathLookup = await resolvedPath()
    guard let path = pathLookup.path else {
      return status(
        installed: false,
        errorMessage: pathLookup.errorMessage ?? "未安装"
      )
    }

    let version = await resolvedVersion(path: path, useResolvedPathExecutable: pathLookup.isFallback)
    return status(
      installed: true,
      version: version.text,
      path: path,
      errorMessage: version.errorMessage
    )
  }

  private func resolvedPath() async -> (path: String?, errorMessage: String?, isFallback: Bool) {
    var pathError: String?
    if let pathCommand = definition.pathCommand {
      let result = await shellRunner.run(pathCommand)
      if result.succeeded, let path = firstUsefulLine(result.combinedOutput) {
        return (path, nil, false)
      }
      pathError = firstUsefulLine(from: result)
    }

    for fallbackPath in definition.fallbackPaths {
      let expandedPath = expandedTilde(fallbackPath)
      let quotedPath = FilePathHelper.shellQuoted(expandedPath)
      let result = await shellRunner.run("test -e \(quotedPath) && printf '%s\\n' \(quotedPath)")
      if result.succeeded {
        return (firstUsefulLine(result.stdout) ?? expandedPath, nil, true)
      }
    }

    return (nil, pathError, false)
  }

  private func resolvedVersion(path: String, useResolvedPathExecutable: Bool) async -> (text: String?, errorMessage: String?) {
    guard let versionCommand = definition.versionCommand else {
      return ("已安装", nil)
    }

    let command = useResolvedPathExecutable ? versionCommandForResolvedPath(versionCommand, path: path) : versionCommand
    let result = await shellRunner.run(command)
    if let version = firstUsefulLine(from: result) {
      return (version, nil)
    }
    return ("已安装，版本未知", result.succeeded ? nil : "版本检测失败")
  }

  private func versionCommandForResolvedPath(_ versionCommand: String, path: String) -> String {
    guard
      definition.pathCommand?.hasPrefix("command -v ") == true,
      let executable = definition.pathCommand?.replacingOccurrences(of: "command -v ", with: ""),
      versionCommand == "\(executable) --version"
    else {
      return versionCommand
    }
    return "\(FilePathHelper.shellQuoted(path)) --version"
  }

  private func status(
    installed: Bool,
    version: String? = nil,
    path: String? = nil,
    errorMessage: String? = nil
  ) -> DevToolStatus {
    DevToolStatus(
      id: definition.id,
      name: definition.name,
      category: definition.category,
      installed: installed,
      version: version,
      path: path,
      errorMessage: errorMessage,
      installHint: definition.installHint,
      description: definition.description
    )
  }

  private func firstUsefulLine(from result: ShellCommandResult) -> String? {
    firstUsefulLine(result.combinedOutput)
  }

  private func firstUsefulLine(_ text: String) -> String? {
    text
      .components(separatedBy: .newlines)
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .first { !$0.isEmpty }
  }

  private func expandedTilde(_ path: String) -> String {
    guard path == "~" || path.hasPrefix("~/") else { return path }
    return NSHomeDirectory() + String(path.dropFirst())
  }
}
