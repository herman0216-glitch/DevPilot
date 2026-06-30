import AppKit
import DevPilotCore
import SwiftUI

struct CommandPanelView: View {
  @EnvironmentObject private var appState: AppState
  @State private var selectedCategory: CommandCategory = .basic
  @State private var selectedCommandID: CommandSnippet.ID?
  @State private var searchText = ""

  private var commands: [CommandSnippet] {
    CommandSnippet.builtInCommands
  }

  private var selectedCategoryCommands: [CommandSnippet] {
    commands.filter { $0.category == selectedCategory }
  }

  private var filteredCommands: [CommandSnippet] {
    selectedCategoryCommands.filter { snippet in
      searchText.isEmpty
        || snippet.title.localizedCaseInsensitiveContains(searchText)
        || snippet.command.localizedCaseInsensitiveContains(searchText)
        || snippet.description.localizedCaseInsensitiveContains(searchText)
    }
  }

  private var selectedCommand: CommandSnippet? {
    guard let selectedCommandID else { return nil }
    return commands.first { $0.id == selectedCommandID }
  }

  var body: some View {
    HStack(spacing: 0) {
      categoryPanel
        .frame(width: 220)

      Divider()

      commandListPanel
        .frame(width: 300)

      Divider()

      commandDetailPanel
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .onAppear {
      selectedCommandID = appState.selectedCommand.id
      ensureSelectedCommandVisible()
    }
    .onChange(of: searchText) { _, _ in
      ensureSelectedCommandVisible()
    }
  }

  private var categoryPanel: some View {
    VStack(alignment: .leading, spacing: 10) {
      VStack(alignment: .leading, spacing: 4) {
        Text("分类")
          .font(.headline)
        Text("选择分类查看对应命令")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .padding(.horizontal, 14)
      .padding(.top, 14)

      ScrollView {
        LazyVStack(spacing: 4) {
          ForEach(CommandCategory.allCases) { category in
            CategoryButton(
              category: category,
              count: commandCount(for: category),
              isSelected: selectedCategory == category
            ) {
              selectCategory(category)
            }
          }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 12)
      }
    }
  }

  private var commandListPanel: some View {
    VStack(alignment: .leading, spacing: 10) {
      TextField("搜索当前分类命令", text: $searchText)
        .textFieldStyle(.roundedBorder)
        .padding([.horizontal, .top], 12)

      HStack(spacing: 4) {
        Text(selectedCategory.rawValue)
          .font(.headline)
        Text("· \(selectedCategoryCommands.count) 条命令")
          .font(.caption)
          .foregroundStyle(.secondary)
        Spacer()
      }
      .padding(.horizontal, 12)

      if selectedCategoryCommands.isEmpty {
        ContentUnavailableView("该分类暂无命令", systemImage: selectedCategory.systemImage)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if filteredCommands.isEmpty {
        ContentUnavailableView("没有找到匹配命令", systemImage: "magnifyingglass")
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        ScrollView {
          LazyVStack(spacing: 6) {
            ForEach(filteredCommands) { snippet in
              CommandButton(
                snippet: snippet,
                isSelected: selectedCommandID == snippet.id
              ) {
                selectCommand(snippet)
              }
            }
          }
          .padding(.horizontal, 10)
          .padding(.bottom, 12)
        }
      }
    }
  }

  @ViewBuilder
  private var commandDetailPanel: some View {
    if let selectedCommand {
      VStack(alignment: .leading, spacing: 16) {
        HStack(alignment: .top, spacing: 16) {
          VStack(alignment: .leading, spacing: 8) {
            Text(selectedCommand.title)
              .font(.title2.bold())
            Text(selectedCommand.description)
              .foregroundStyle(.secondary)
            Text(selectedCommand.command)
              .font(.system(.body, design: .monospaced))
              .textSelection(.enabled)
              .lineLimit(3)
          }

          Spacer(minLength: 16)

          HStack(spacing: 8) {
            Button {
              copy(selectedCommand.command)
            } label: {
              Label("复制命令", systemImage: "doc.on.doc")
            }

            Button {
              runOrCopy(selectedCommand)
            } label: {
              Label(primaryActionTitle(for: selectedCommand), systemImage: primaryActionIcon(for: selectedCommand))
            }
            .disabled(primaryActionDisabled(for: selectedCommand))
          }
        }

        metadataGrid(for: selectedCommand)

        if selectedCommand.workingDirectoryRequired {
          workingDirectoryPicker
        } else if selectedCommand.runMode == .copyOnly {
          Label("此命令只复制到终端使用，不在独立 Process 中直接运行。", systemImage: "doc.on.clipboard")
            .foregroundStyle(.secondary)
        }

        GroupBox("输出") {
          ScrollView {
            Text(appState.commandOutput.isEmpty ? "选择命令后点击执行。" : appState.commandOutput)
              .font(.system(.body, design: .monospaced))
              .textSelection(.enabled)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(8)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)

        if let exitCode = appState.commandExitCode {
          Label(exitCode == 0 ? "成功" : "失败，退出码 \(exitCode)", systemImage: exitCode == 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
            .foregroundStyle(exitCode == 0 ? .green : .orange)
        }
      }
      .padding(20)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    } else {
      ContentUnavailableView("请选择左侧分类和命令", systemImage: "terminal")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }

  private func metadataGrid(for snippet: CommandSnippet) -> some View {
    Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 8) {
      metadataRow("分类", snippet.category.rawValue)
      metadataRow("运行模式", runModeTitle(snippet.runMode))
      metadataRow("工作目录", snippet.workingDirectoryRequired ? "需要" : "不需要")
    }
    .font(.caption)
    .padding(10)
    .background(Color.secondary.opacity(0.08))
    .clipShape(RoundedRectangle(cornerRadius: 8))
  }

  private func metadataRow(_ title: String, _ value: String) -> some View {
    GridRow {
      Text(title)
        .foregroundStyle(.secondary)
      Text(value)
        .fontWeight(.medium)
    }
  }

  private var workingDirectoryPicker: some View {
    HStack(spacing: 8) {
      Label("工作目录", systemImage: "folder")
        .foregroundStyle(.secondary)
      Text(appState.commandWorkingDirectory.isEmpty ? "未选择" : appState.commandWorkingDirectory)
        .font(.system(.body, design: .monospaced))
        .lineLimit(1)
        .truncationMode(.middle)
        .help(appState.commandWorkingDirectory)
      Spacer()
      Button {
        chooseWorkingDirectory()
      } label: {
        Label("选择工作目录", systemImage: "folder.badge.plus")
      }
    }
    .padding(10)
    .background(Color.secondary.opacity(0.08))
    .clipShape(RoundedRectangle(cornerRadius: 8))
  }

  private func selectCategory(_ category: CommandCategory) {
    selectedCategory = category
    searchText = ""

    if let firstCommand = commands.first(where: { $0.category == category }) {
      selectCommand(firstCommand)
    } else {
      selectedCommandID = nil
    }
  }

  private func selectCommand(_ snippet: CommandSnippet) {
    if appState.selectedCommand.id != snippet.id {
      appState.commandOutput = ""
      appState.commandExitCode = nil
    }
    selectedCommandID = snippet.id
    appState.selectedCommand = snippet
  }

  private func ensureSelectedCommandVisible() {
    if let selectedCommandID, filteredCommands.contains(where: { $0.id == selectedCommandID }) {
      if let snippet = filteredCommands.first(where: { $0.id == selectedCommandID }) {
        appState.selectedCommand = snippet
      }
      return
    }

    if let first = filteredCommands.first {
      selectCommand(first)
    } else {
      selectedCommandID = nil
    }
  }

  private func commandCount(for category: CommandCategory) -> Int {
    commands.filter { $0.category == category }.count
  }

  private func chooseWorkingDirectory() {
    let panel = NSOpenPanel()
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = false
    panel.directoryURL = URL(fileURLWithPath: appState.commandWorkingDirectory.isEmpty ? NSHomeDirectory() : appState.commandWorkingDirectory)
    if panel.runModal() == .OK, let url = panel.url {
      appState.commandWorkingDirectory = url.path
    }
  }

  private func runOrCopy(_ snippet: CommandSnippet) {
    guard snippet.runMode != .copyOnly else {
      copy(snippet.command)
      appState.commandOutput = "已复制命令到剪贴板：\n\(snippet.command)"
      appState.commandExitCode = nil
      return
    }

    appState.selectedCommand = snippet
    Task { await appState.runCommand(snippet) }
  }

  private func copy(_ text: String) {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)
  }

  private func primaryActionTitle(for snippet: CommandSnippet) -> String {
    if appState.commandIsRunning { return "执行中" }
    if snippet.runMode == .copyOnly { return "复制到剪贴板" }
    return "执行"
  }

  private func primaryActionIcon(for snippet: CommandSnippet) -> String {
    snippet.runMode == .copyOnly ? "doc.on.doc" : "play.fill"
  }

  private func primaryActionDisabled(for snippet: CommandSnippet) -> Bool {
    if snippet.runMode == .copyOnly {
      return appState.commandIsRunning
    }

    return appState.commandIsRunning
      || !snippet.isSafeToRun
      || (snippet.workingDirectoryRequired && appState.commandWorkingDirectory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
  }

  private func runModeTitle(_ runMode: CommandRunMode) -> String {
    switch runMode {
    case .runDirectly:
      return "可运行"
    case .copyOnly:
      return "仅复制"
    case .requiresProjectDirectory:
      return "需目录"
    case .opensTerminal:
      return "打开终端"
    }
  }
}

private struct CategoryButton: View {
  let category: CommandCategory
  let count: Int
  let isSelected: Bool
  let action: () -> Void

  @State private var isHovering = false

  var body: some View {
    Button(action: action) {
      HStack(spacing: 10) {
        Image(systemName: category.systemImage)
          .frame(width: 22)
        Text(category.rawValue)
          .lineLimit(1)
        Spacer()
        Text("\(count)")
          .font(.caption)
          .foregroundStyle(isSelected ? .white.opacity(0.82) : .secondary)
      }
      .foregroundStyle(isSelected ? .white : .primary)
      .padding(.horizontal, 10)
      .padding(.vertical, 8)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(rowBackground)
      .clipShape(RoundedRectangle(cornerRadius: 8))
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .onHover { isHovering = $0 }
  }

  private var rowBackground: Color {
    if isSelected { return .accentColor }
    if isHovering { return Color.secondary.opacity(0.10) }
    return .clear
  }
}

private struct CommandButton: View {
  let snippet: CommandSnippet
  let isSelected: Bool
  let action: () -> Void

  @State private var isHovering = false

  var body: some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: 6) {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
          Text(snippet.title)
            .font(.headline)
            .lineLimit(1)
          Spacer()
          Text(badgeTitle)
            .font(.caption2)
            .foregroundStyle(isSelected ? .white.opacity(0.86) : .secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(isSelected ? Color.white.opacity(0.16) : Color.secondary.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }

        Text(snippet.command)
          .font(.system(.caption, design: .monospaced))
          .foregroundStyle(isSelected ? .white.opacity(0.88) : .secondary)
          .lineLimit(1)
          .truncationMode(.middle)
      }
      .foregroundStyle(isSelected ? .white : .primary)
      .padding(10)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(rowBackground)
      .clipShape(RoundedRectangle(cornerRadius: 8))
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .onHover { isHovering = $0 }
  }

  private var rowBackground: Color {
    if isSelected { return .accentColor }
    if isHovering { return Color.secondary.opacity(0.10) }
    return Color.secondary.opacity(0.05)
  }

  private var badgeTitle: String {
    switch snippet.runMode {
    case .runDirectly:
      return "可运行"
    case .copyOnly:
      return "仅复制"
    case .requiresProjectDirectory:
      return "需目录"
    case .opensTerminal:
      return "终端"
    }
  }
}
