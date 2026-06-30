# DevPilot

DevPilot 是一个面向 Mac 开发者、学生和效率用户的 macOS 菜单栏工作流助手，帮助你快速启动工作流、检测开发环境、运行常用命令并整理下载目录。

当前版本：`v0.1.0`

## 截图

截图会放在 `Docs/screenshots/` 目录中。

![DevPilot 首页](Docs/screenshots/home.png)
![命令中心](Docs/screenshots/commands.png)
![环境检测](Docs/screenshots/environment.png)

## 功能特性

- 菜单栏快捷入口。
- 单主窗口 macOS 原生界面。
- 自定义工作流。
- 开发环境检测。
- 常用命令中心。
- 下载目录整理。
- 安全的 Shell 命令执行。
- 可打包为普通 macOS `.app` 的使用体验。

## 适合谁使用

DevPilot v0.1.0 适合 Mac 开发者、计算机专业学生，以及希望把常用本地工作流集中管理的效率用户。

它的目标是轻量、直接、可理解。第一版不会试图替代 Raycast、Alfred、IDE 或包管理器，而是提供一个稳定的小入口，把常见开发和学习动作整理到一起。

## 下载与安装

进入 [GitHub Releases](https://github.com/herman0216-glitch/DevPilot/releases/tag/v0.1.0) 页面，下载：

[下载 DevPilot-v0.1.0-macOS.zip](https://github.com/herman0216-glitch/DevPilot/releases/download/v0.1.0/DevPilot-v0.1.0-macOS.zip)

然后：

1. 解压 ZIP 文件。
2. 将 `DevPilot.app` 拖到“应用程序”文件夹。
3. 双击打开 DevPilot。

项目也提供 DMG 安装包：

[下载 DevPilot-v0.1.0.dmg](https://github.com/herman0216-glitch/DevPilot/releases/download/v0.1.0/DevPilot-v0.1.0.dmg)

打开 DMG 后，把 DevPilot 拖到 Applications 即可。

## 第一次打开

DevPilot v0.1.0 可能没有使用 Apple Developer ID 签名，也可能没有经过 Apple notarization 公证。因此第一次打开时，macOS 可能提示“无法验证开发者”。

如果遇到这个提示：

1. 右键点击 `DevPilot.app`。
2. 选择“打开”。
3. 在弹窗中再次点击“打开”。

不要关闭 Gatekeeper，也不要关闭系统安全功能。

当前发布脚本会在本机支持 `codesign` 时添加本地 ad-hoc 签名。这个签名有助于本地验证，但不等于 Developer ID 签名或 Apple notarization。

## 使用方法

- 从“应用程序”启动 DevPilot。
- 启动后会打开主窗口。
- 菜单栏会保留 DevPilot 图标。
- 关闭主窗口不会退出 App。
- 使用 Command + Q，或菜单栏里的“退出”，才会真正退出 DevPilot。

DevPilot v0.1.0 包含这些核心能力：

- 打开并运行自定义工作流。
- 检测 Git、Homebrew、Swift、Node.js、Python、Docker、Flutter、编辑器 CLI 等开发工具。
- 运行内置常用命令，并显示 stdout、stderr、退出码、耗时和工作目录。
- 整理 Downloads 文件夹，把常见文件类型移动到分类文件夹中。DevPilot 不会删除文件。
- 保存默认项目目录、本地 URL、命令工作目录、编辑器偏好和环境检测设置。

## 从源码构建

DevPilot 当前是 Swift Package Manager macOS App。

```bash
git clone https://github.com/herman0216-glitch/DevPilot.git
cd DevPilot
open Package.swift
```

在 Xcode 中：

1. 选择 `DevPilot` scheme。
2. 运行目标选择 My Mac。
3. 点击 Run。

也可以打开 Xcode 自动生成的 SwiftPM workspace：

```bash
open .swiftpm/xcode/package.xcworkspace
```

## 命令行构建

运行测试：

```bash
swift test
```

构建并启动本地 app bundle：

```bash
./script/build_and_run.sh
```

构建并验证 App 进程可以启动：

```bash
./script/build_and_run.sh --verify
```

构建 Release app：

```bash
./Scripts/build_release.sh
```

打包 ZIP：

```bash
./Scripts/package_zip.sh
```

打包 DMG：

```bash
./Scripts/package_dmg.sh
```

发布产物会输出到 `dist/`。

## 项目结构

```text
DevPilot/
├── Package.swift
├── Sources/
│   ├── DevPilot/
│   │   ├── App/
│   │   ├── Resources/
│   │   └── Views/
│   └── DevPilotCore/
│       ├── Models/
│       ├── Services/
│       └── Utilities/
├── Tests/
│   └── DevPilotCoreTests/
├── Scripts/
│   ├── build_release.sh
│   ├── package_zip.sh
│   ├── package_dmg.sh
│   ├── generate_app_icons.sh
│   └── install_devpilot.sh
├── script/
│   └── build_and_run.sh
├── Docs/
│   └── screenshots/
├── README.md
└── CHANGELOG.md
```

## 架构说明

- `Sources/DevPilot/App`：App 启动、生命周期、菜单栏状态项和主窗口管理。
- `Sources/DevPilot/Views`：首页、命令中心、工作流、环境检测、下载整理和设置页。
- `Sources/DevPilotCore/Models`：跨界面共享的数据模型。
- `Sources/DevPilotCore/Services`：Shell 执行、环境检测、文件整理、工作流保存、工作流运行和命令安全校验。
- `Sources/DevPilotCore/Utilities`：布局常量、日志、菜单栏标识和路径工具。

## 安全说明

命令中心只运行内置命令片段。自定义工作流中的 Shell 动作会经过 `CommandSafetyValidator` 检查，阻止明显危险的命令，例如破坏性 `rm`、磁盘擦除、不安全的权限修改、fork bomb 和终止 Finder 的命令。

会修改系统或项目的命令，例如安装依赖或需要权限的命令，会被标记为“需要确认”。下载目录整理只移动文件并处理重名冲突，不会删除文件。

macOS GUI App 通常不会继承 Terminal 的完整 shell 环境，所以 DevPilot 会配置一组常见开发工具 PATH，并同时捕获 stdout 和 stderr。这对 `java -version`、`dart --version` 这类经常把版本输出写到 stderr 的工具很重要。

## 常见问题

### 为什么没有 `.xcodeproj`？

DevPilot 是 SwiftPM App。用 Xcode 打开 `Package.swift`，选择 `DevPilot` scheme 即可运行。

### 需要 Apple Developer 账号吗？

本地构建和 ZIP 分发不需要。没有 Developer ID 签名和 notarization 时，用户第一次打开可能会看到 macOS 的开发者验证提示。

### 本地 ad-hoc 签名能用于正式公开分发吗？

不能。Ad-hoc 签名适合本地验证。更正式的公开版本应该使用 Developer ID 签名和 Apple notarization。

### 为什么 Docker 显示已安装，但命令仍然失败？

DevPilot 可以检测 Docker CLI 是否存在，但 Docker Desktop 可能没有运行。这种情况下 Docker 命令仍然可能返回运行错误。

### 为什么 `source .venv/bin/activate` 只能复制？

激活虚拟环境只会影响当前 shell session。DevPilot 每次运行命令都会启动独立进程，所以直接执行 activate 不会影响后续命令。

## 已知限制

- DevPilot v0.1.0 可能没有 Developer ID 签名，也可能没有 notarization。
- 部分命令依赖用户本机安装的工具和 PATH。
- Docker CLI 存在不代表 Docker Desktop 正在运行。
- Android Studio 第一版优先检测 App 路径，可能无法读取精确版本。
- 自定义工作流在 v0.1.0 中保持轻量。
- 导入导出、通知、延迟动作、剪贴板动作、自动更新和 AI 功能尚未包含在第一版中。

## Roadmap

- Developer ID 签名和 Apple notarization。
- 自动更新。
- Homebrew Cask。
- 工作流导入导出。
- 工作流通知、延迟和剪贴板动作。
- 自定义命令库。
- 项目工作区管理。
- AI 报错解释。
- AI commit message 生成。

## 贡献方式

欢迎提交 issue 和 pull request。较大的改动建议先开 issue，说明要解决的问题、预期行为和测试方式。

提交 PR 前建议运行：

```bash
swift test
./script/build_and_run.sh --verify
```
