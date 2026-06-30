import Foundation

public enum CommandCategory: String, CaseIterable, Identifiable, Hashable, Codable {
  case basic = "基础工具"
  case homebrew = "Homebrew"
  case apple = "Apple 原生开发"
  case web = "Web 前端"
  case pythonAI = "Python / AI"
  case javaBackend = "Java / 后端"
  case database = "数据库"
  case devops = "容器与 DevOps"
  case mobile = "移动端"
  case editorAI = "编辑器与 AI 工具"
  case project = "项目常用"
  case gitWorkflow = "Git 工作流"
  case system = "系统诊断"

  public var id: String { rawValue }

  public var systemImage: String {
    switch self {
    case .basic:
      return "wrench.and.screwdriver"
    case .homebrew:
      return "shippingbox"
    case .apple:
      return "apple.logo"
    case .web:
      return "globe"
    case .pythonAI:
      return "brain"
    case .javaBackend:
      return "server.rack"
    case .database:
      return "cylinder.split.1x2"
    case .devops:
      return "cube.box"
    case .mobile:
      return "iphone"
    case .editorAI:
      return "terminal"
    case .project:
      return "folder.badge.gearshape"
    case .gitWorkflow:
      return "arrow.triangle.branch"
    case .system:
      return "desktopcomputer"
    }
  }
}

public enum CommandRunMode: String, CaseIterable, Identifiable, Hashable, Codable {
  case runDirectly
  case copyOnly
  case requiresProjectDirectory
  case opensTerminal

  public var id: String { rawValue }
}

public struct CommandSnippet: Identifiable, Equatable, Hashable, Codable {
  public let id: String
  public let title: String
  public let command: String
  public let category: CommandCategory
  public let description: String
  public let workingDirectoryRequired: Bool
  public let isSafeToRun: Bool
  public let runMode: CommandRunMode

  public init(
    id: String,
    title: String,
    command: String,
    category: CommandCategory,
    description: String,
    workingDirectoryRequired: Bool = false,
    isSafeToRun: Bool = true,
    runMode: CommandRunMode = .runDirectly
  ) {
    self.id = id
    self.title = title
    self.command = command
    self.category = category
    self.description = description
    self.workingDirectoryRequired = workingDirectoryRequired || runMode == .requiresProjectDirectory
    self.isSafeToRun = isSafeToRun && runMode != .copyOnly
    self.runMode = runMode
  }

  public var isBuiltInSafeCommand: Bool {
    Self.safeCommandSet.contains(command) && !containsDangerousPattern(command)
  }

  public static let builtInCommands: [CommandSnippet] = [
    cmd("git-version", "Git Version", "git --version", .basic, "显示 Git 版本。"),
    cmd("zsh-version", "Zsh Version", "zsh --version", .basic, "显示 Zsh 版本。"),
    cmd("curl-version", "Curl Version", "curl --version | head -n 1", .basic, "显示 Curl 版本。"),
    cmd("make-version", "Make Version", "make --version | head -n 1", .basic, "显示 Make 版本。"),
    cmd("cmake-version", "CMake Version", "cmake --version | head -n 1", .basic, "显示 CMake 版本。"),

    cmd("brew-version", "Brew Version", "brew --version", .homebrew, "显示 Homebrew 版本。"),
    cmd("brew-update", "Brew Update", "brew update", .homebrew, "更新 Homebrew 软件源。"),
    cmd("brew-upgrade", "Brew Upgrade", "brew upgrade", .homebrew, "升级 Homebrew 已安装软件包，可能耗时较长。"),
    cmd("brew-doctor", "Brew Doctor", "brew doctor", .homebrew, "检查 Homebrew 配置是否健康。"),
    cmd("brew-config", "Brew Config", "brew config", .homebrew, "显示 Homebrew 配置和环境信息。"),
    cmd("brew-list", "Brew List", "brew list", .homebrew, "列出已安装的 formula。"),
    cmd("brew-list-cask", "Brew Cask List", "brew list --cask", .homebrew, "列出已安装的 cask 应用。"),
    cmd("brew-outdated", "Brew Outdated", "brew outdated", .homebrew, "列出可升级的 formula。"),
    cmd("brew-outdated-cask", "Brew Outdated Cask", "brew outdated --cask", .homebrew, "列出可升级的 cask 应用。"),
    copyCmd("brew-search", "Brew Search", "brew search", .homebrew, "复制后追加关键词，用于搜索 formula 或 cask。"),
    copyCmd("brew-info", "Brew Info", "brew info", .homebrew, "复制后追加包名，用于查看 formula 或 cask 信息。"),
    cmd("brew-cleanup-dry-run", "Brew Cleanup Preview", "brew cleanup -n", .homebrew, "预览 Homebrew 可清理内容，不实际删除。"),
    cmd("brew-services-list", "Brew Services List", "brew services list", .homebrew, "列出 Homebrew Services 管理的服务。"),
    cmd("brew-tap", "Brew Tap", "brew tap", .homebrew, "列出已添加的 tap 仓库。"),
    cmd("brew-leaves", "Brew Leaves", "brew leaves", .homebrew, "列出作为顶层依赖安装的 formula。"),
    cmd("brew-missing", "Brew Missing", "brew missing", .homebrew, "检查是否缺少依赖。"),
    cmd("brew-deps-installed", "Brew Installed Dependencies", "brew deps --installed", .homebrew, "列出已安装 formula 的依赖关系。"),
    copyCmd("brew-install-formula", "Brew Install Formula", "brew install <formula>", .homebrew, "复制到终端并替换包名后安装 formula。"),
    copyCmd("brew-install-cask", "Brew Install Cask", "brew install --cask <cask>", .homebrew, "复制到终端并替换应用名后安装 cask。"),

    cmd("xcode-select-path", "Xcode Select Path", "xcode-select -p", .apple, "显示当前 Xcode 开发目录。"),
    cmd("xcodebuild-version", "Xcode Version", "xcodebuild -version", .apple, "显示 Xcode 版本。"),
    cmd("swift-version", "Swift Version", "swift --version", .apple, "显示 Swift 版本。"),
    cmd("clang-version", "Clang Version", "clang --version | head -n 1", .apple, "显示 Clang 版本。"),
    cmd("simulators-list", "List Simulators", "xcrun simctl list devices", .apple, "列出本机 iOS 模拟器设备。"),

    cmd("node-version", "Node Version", "node -v", .web, "显示 Node.js 版本。"),
    cmd("npm-version", "npm Version", "npm -v", .web, "显示 npm 版本。"),
    projectCmd("npm-install", "npm Install", "npm install", .web, "在项目目录安装 npm 依赖。"),
    projectCmd("npm-dev", "npm Dev", "npm run dev", .web, "在项目目录启动 npm 开发脚本。"),
    projectCmd("npm-build", "npm Build", "npm run build", .web, "在项目目录执行 npm 构建脚本。"),
    cmd("pnpm-version", "pnpm Version", "pnpm -v", .web, "显示 pnpm 版本。"),
    projectCmd("pnpm-install", "pnpm Install", "pnpm install", .web, "在项目目录安装 pnpm 依赖。"),
    projectCmd("pnpm-dev", "pnpm Dev", "pnpm dev", .web, "在项目目录启动 pnpm 开发脚本。"),
    projectCmd("pnpm-build", "pnpm Build", "pnpm build", .web, "在项目目录执行 pnpm 构建脚本。"),
    cmd("yarn-version", "Yarn Version", "yarn -v", .web, "显示 Yarn 版本。"),
    projectCmd("yarn-install", "Yarn Install", "yarn install", .web, "在项目目录安装 Yarn 依赖。"),
    projectCmd("yarn-dev", "Yarn Dev", "yarn dev", .web, "在项目目录启动 Yarn 开发脚本。"),
    cmd("bun-version", "Bun Version", "bun --version", .web, "显示 Bun 版本。"),
    projectCmd("bun-install", "Bun Install", "bun install", .web, "在项目目录安装 Bun 依赖。"),
    projectCmd("bun-dev", "Bun Dev", "bun run dev", .web, "在项目目录启动 Bun 开发脚本。"),
    cmd("deno-version", "Deno Version", "deno --version | head -n 1", .web, "显示 Deno 版本。"),
    cmd("tsc-version", "TypeScript Version", "tsc -v", .web, "显示 TypeScript 编译器版本。"),
    cmd("vite-version", "Vite Version", "vite --version", .web, "显示 Vite 版本。"),

    cmd("python-version", "Python Version", "python3 --version", .pythonAI, "显示 Python 3 版本。"),
    cmd("pip-version", "pip Version", "pip3 --version", .pythonAI, "显示 pip3 版本。"),
    cmd("pip-list", "pip List", "pip3 list", .pythonAI, "列出当前 Python 环境安装的包。"),
    cmd("pip-freeze", "pip Freeze", "pip3 freeze", .pythonAI, "输出可写入 requirements.txt 的 Python 依赖版本。"),
    projectCmd("python-venv", "Create venv", "python3 -m venv .venv", .pythonAI, "在项目目录创建 .venv 虚拟环境。"),
    copyCmd("venv-activate", "Activate venv", "source .venv/bin/activate", .pythonAI, "复制到终端执行；独立 Process 中不会持久激活环境。"),
    cmd("uv-version", "uv Version", "uv --version", .pythonAI, "显示 uv 版本。"),
    projectCmd("uv-pip-list", "uv pip list", "uv pip list", .pythonAI, "列出项目环境中的 Python 包。"),
    cmd("jupyter-version", "Jupyter Version", "jupyter --version | head -n 1", .pythonAI, "显示 Jupyter 版本信息。"),
    cmd("conda-version", "Conda Version", "conda --version", .pythonAI, "显示 Conda 版本。"),
    cmd("conda-env-list", "Conda Env List", "conda env list", .pythonAI, "列出 Conda 环境。"),
    cmd("ollama-version", "Ollama Version", "ollama --version", .pythonAI, "显示 Ollama 版本。"),
    cmd("ollama-list", "Ollama List", "ollama list", .pythonAI, "列出本机 Ollama 模型。"),

    cmd("java-version", "Java Version", "java -version", .javaBackend, "显示 Java 版本，输出可能在 stderr。"),
    cmd("maven-version", "Maven Version", "mvn -v | head -n 1", .javaBackend, "显示 Maven 版本。"),
    cmd("gradle-version", "Gradle Version", "gradle -v | grep Gradle | head -n 1", .javaBackend, "显示 Gradle 版本。"),
    cmd("go-version", "Go Version", "go version", .javaBackend, "显示 Go 版本。"),
    cmd("rust-version", "Rust Version", "rustc --version", .javaBackend, "显示 Rust 编译器版本。"),
    cmd("cargo-version", "Cargo Version", "cargo --version", .javaBackend, "显示 Cargo 版本。"),
    projectCmd("cargo-build", "Cargo Build", "cargo build", .javaBackend, "在 Rust 项目目录执行构建。"),
    projectCmd("cargo-test", "Cargo Test", "cargo test", .javaBackend, "在 Rust 项目目录执行测试。"),
    cmd("php-version", "PHP Version", "php -v | head -n 1", .javaBackend, "显示 PHP 版本。"),
    cmd("composer-version", "Composer Version", "composer --version", .javaBackend, "显示 Composer 版本。"),
    cmd("ruby-version", "Ruby Version", "ruby -v", .javaBackend, "显示 Ruby 版本。"),
    cmd("dotnet-version", ".NET Version", "dotnet --version", .javaBackend, "显示 .NET SDK 版本。"),

    cmd("mysql-version", "MySQL Version", "mysql --version", .database, "显示 MySQL 客户端版本。"),
    cmd("mysql-start", "Start MySQL", "mysql.server start", .database, "启动本机 MySQL 服务并显示结果。"),
    cmd("mysql-stop", "Stop MySQL", "mysql.server stop", .database, "停止本机 MySQL 服务并显示结果。"),
    cmd("mysql-status", "MySQL Status", "mysql.server status", .database, "查看本机 MySQL 服务状态。"),
    cmd("psql-version", "PostgreSQL Version", "psql --version", .database, "显示 PostgreSQL 客户端版本。"),
    cmd("postgres-start", "Start PostgreSQL", "brew services start postgresql", .database, "通过 Homebrew Services 启动 PostgreSQL。"),
    cmd("postgres-stop", "Stop PostgreSQL", "brew services stop postgresql", .database, "通过 Homebrew Services 停止 PostgreSQL。"),
    cmd("redis-version", "Redis Version", "redis-server --version", .database, "显示 Redis 服务版本。"),
    cmd("redis-start", "Start Redis", "brew services start redis", .database, "通过 Homebrew Services 启动 Redis。"),
    cmd("redis-stop", "Stop Redis", "brew services stop redis", .database, "通过 Homebrew Services 停止 Redis。"),
    cmd("mongosh-version", "MongoDB Shell Version", "mongosh --version", .database, "显示 MongoDB Shell 版本。"),
    cmd("sqlite-version", "SQLite Version", "sqlite3 --version", .database, "显示 SQLite 版本。"),

    cmd("docker-version", "Docker Version", "docker --version", .devops, "显示 Docker CLI 版本。"),
    cmd("docker-ps", "Docker Containers", "docker ps", .devops, "列出运行中的容器；Docker Desktop 未启动时会显示错误。"),
    cmd("docker-images", "Docker Images", "docker images", .devops, "列出本地 Docker 镜像。"),
    cmd("docker-compose-version", "Compose Version", "docker compose version", .devops, "显示 Docker Compose 版本。"),
    cmd("docker-compose-ps", "Compose Services", "docker compose ps", .devops, "列出当前目录 Compose 服务状态。", runMode: .requiresProjectDirectory),
    cmd("kubectl-version", "kubectl Version", "kubectl version --client", .devops, "显示 kubectl 客户端版本。"),
    cmd("kubectl-context", "kubectl Context", "kubectl config current-context", .devops, "显示当前 Kubernetes 上下文。"),
    cmd("kubectl-pods", "kubectl Pods", "kubectl get pods", .devops, "列出当前命名空间的 Pod。"),
    cmd("helm-version", "Helm Version", "helm version --short", .devops, "显示 Helm 版本。"),
    cmd("terraform-version", "Terraform Version", "terraform version | head -n 1", .devops, "显示 Terraform 版本。"),

    cmd("adb-version", "ADB Version", "adb version | head -n 1", .mobile, "显示 Android Debug Bridge 版本。"),
    cmd("flutter-version", "Flutter Version", "flutter --version | head -n 1", .mobile, "显示 Flutter 版本。"),
    cmd("flutter-doctor", "Flutter Doctor", "flutter doctor", .mobile, "检查 Flutter 开发环境。"),
    cmd("dart-version", "Dart Version", "dart --version", .mobile, "显示 Dart 版本，输出可能在 stderr。"),
    cmd("pod-version", "CocoaPods Version", "pod --version", .mobile, "显示 CocoaPods 版本。"),

    cmd("code-version", "VS Code Version", "code --version", .editorAI, "显示 VS Code CLI 版本。"),
    cmd("cursor-version", "Cursor Version", "cursor --version", .editorAI, "显示 Cursor CLI 版本。"),
    cmd("codex-version", "Codex Version", "codex --version", .editorAI, "显示 Codex CLI 版本。"),
    cmd("claude-version", "Claude Version", "claude --version", .editorAI, "显示 Claude Code CLI 版本。"),
    cmd("gemini-version", "Gemini Version", "gemini --version", .editorAI, "显示 Gemini CLI 版本。"),

    projectCmd("project-list-files", "List Files", "ls -la", .project, "列出当前项目目录文件。"),
    projectCmd("project-pwd", "Print Working Directory", "pwd", .project, "显示当前项目工作目录。"),
    projectCmd("project-open-current-directory", "Open Current Directory", "open .", .project, "在 Finder 中打开当前项目目录。"),
    projectCmd("project-find-package-json", "Find Package JSON", "find . -maxdepth 2 -name package.json", .project, "查找项目两层内的 package.json。"),
    projectCmd("project-find-readme", "Find README", "find . -maxdepth 2 -iname \"readme*\"", .project, "查找项目两层内的 README 文件。"),
    projectCmd("project-disk-usage", "Disk Usage Current Folder", "du -sh .", .project, "显示当前项目目录占用空间。"),

    projectCmd("git-status", "Git Status", "git status", .gitWorkflow, "查看当前 Git 仓库状态。"),
    projectCmd("git-branch", "Git Branch", "git branch", .gitWorkflow, "列出当前 Git 仓库分支。"),
    projectCmd("git-log", "Git Log", "git log --oneline -n 10", .gitWorkflow, "查看最近 10 条 Git 提交。"),
    projectCmd("git-remote", "Git Remote", "git remote -v", .gitWorkflow, "查看当前仓库远程地址。"),
    projectCmd("git-diff", "Git Diff", "git diff", .gitWorkflow, "查看尚未暂存的改动。"),
    projectCmd("git-staged-diff", "Git Staged Diff", "git diff --staged", .gitWorkflow, "查看已暂存的改动。"),

    cmd("macos-version", "macOS Version", "sw_vers", .system, "显示 macOS 系统版本。"),
    cmd("disk-free", "Disk Free", "df -h", .system, "显示磁盘可用空间。"),
    cmd("memory-pressure", "Memory Pressure", "memory_pressure", .system, "显示当前内存压力。"),
    cmd("top-cpu-processes", "Top CPU Processes", "ps aux | sort -nrk 3,3 | head -n 10", .system, "显示 CPU 占用最高的 10 个进程。"),
    cmd("top-memory-processes", "Top Memory Processes", "ps aux | sort -nrk 4,4 | head -n 10", .system, "显示内存占用最高的 10 个进程。"),
    cmd("network-interfaces", "Network Interfaces", "ifconfig | head -n 40", .system, "显示前 40 行网络接口信息。")
  ]

  private static let safeCommandSet = Set(builtInCommands.map(\.command))

  private static func cmd(
    _ id: String,
    _ title: String,
    _ command: String,
    _ category: CommandCategory,
    _ description: String,
    runMode: CommandRunMode = .runDirectly
  ) -> CommandSnippet {
    CommandSnippet(
      id: id,
      title: title,
      command: command,
      category: category,
      description: description,
      runMode: runMode
    )
  }

  private static func projectCmd(
    _ id: String,
    _ title: String,
    _ command: String,
    _ category: CommandCategory,
    _ description: String
  ) -> CommandSnippet {
    CommandSnippet(
      id: id,
      title: title,
      command: command,
      category: category,
      description: description,
      workingDirectoryRequired: true,
      runMode: .requiresProjectDirectory
    )
  }

  private static func copyCmd(
    _ id: String,
    _ title: String,
    _ command: String,
    _ category: CommandCategory,
    _ description: String
  ) -> CommandSnippet {
    CommandSnippet(
      id: id,
      title: title,
      command: command,
      category: category,
      description: description,
      isSafeToRun: false,
      runMode: .copyOnly
    )
  }

  private func containsDangerousPattern(_ command: String) -> Bool {
    let lowercased = command.lowercased()
    return [
      "rm -rf",
      "sudo rm",
      "diskutil erase",
      "mkfs",
      "chmod -r 777 /",
      "chown -r",
      "killall finder"
    ].contains { lowercased.contains($0) }
  }
}
