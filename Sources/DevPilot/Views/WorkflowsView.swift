import DevPilotCore
import SwiftUI

struct WorkflowsView: View {
  @EnvironmentObject private var appState: AppState
  @State private var selectedWorkflowCategory: WorkflowCategory = .all
  @State private var selectedWorkflowID: UUID?
  @State private var workflowSearchText: String = ""
  @State private var editingWorkflow: Workflow?

  private var categoryWorkflows: [Workflow] {
    appState.workflows.filter { selectedWorkflowCategory.matches($0) }
  }

  private var filteredWorkflows: [Workflow] {
    categoryWorkflows.filter { workflow in
      workflowSearchText.isEmpty
        || workflow.name.localizedCaseInsensitiveContains(workflowSearchText)
        || workflow.description.localizedCaseInsensitiveContains(workflowSearchText)
    }
  }

  private var selectedWorkflow: Workflow? {
    guard let selectedWorkflowID else { return nil }
    return appState.workflows.first { $0.id == selectedWorkflowID }
  }

  var body: some View {
    HStack(spacing: 0) {
      workflowCategoryPanel
        .frame(width: DevPilotLayout.workflowCategoryWidth)

      Divider()

      workflowListPanel
        .frame(width: DevPilotLayout.workflowListWidth)

      Divider()

      workflowDetailPanel
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .onAppear {
      ensureSelectedWorkflowVisible()
    }
    .onChange(of: workflowSearchText) { _, _ in
      ensureSelectedWorkflowVisible()
    }
    .onChange(of: appState.workflows) { _, _ in
      ensureSelectedWorkflowVisible()
    }
    .sheet(item: $editingWorkflow) { workflow in
      WorkflowEditorView(workflow: workflow) { savedWorkflow in
        if appState.workflows.contains(where: { $0.id == savedWorkflow.id }) {
          appState.updateWorkflow(savedWorkflow)
        } else {
          appState.createWorkflow(savedWorkflow)
        }
        selectedWorkflowID = savedWorkflow.id
        if !selectedWorkflowCategory.matches(savedWorkflow) {
          selectedWorkflowCategory = savedWorkflow.isEnabled ? savedWorkflow.category : .disabled
        }
      }
    }
  }

  private var workflowCategoryPanel: some View {
    VStack(alignment: .leading, spacing: 10) {
      VStack(alignment: .leading, spacing: 4) {
        Text("分类")
          .font(.headline)
        Text("选择分类查看工作流")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .padding(.horizontal, 14)
      .padding(.top, 14)

      ScrollView {
        LazyVStack(spacing: 4) {
          ForEach(WorkflowCategory.allCases) { category in
            WorkflowCategoryButton(
              category: category,
              count: workflowCount(for: category),
              isSelected: selectedWorkflowCategory == category
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

  private var workflowListPanel: some View {
    VStack(alignment: .leading, spacing: 10) {
      TextField("搜索工作流", text: $workflowSearchText)
        .textFieldStyle(.roundedBorder)
        .padding([.horizontal, .top], 12)

      HStack(spacing: 4) {
        Text(selectedWorkflowCategory.rawValue)
          .font(.headline)
        Text("· \(categoryWorkflows.count) 个工作流")
          .font(.caption)
          .foregroundStyle(.secondary)
        Spacer()
      }
      .padding(.horizontal, 12)

      Group {
        if categoryWorkflows.isEmpty {
          ContentUnavailableView("该分类暂无工作流", systemImage: selectedWorkflowCategory.systemImage)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if filteredWorkflows.isEmpty {
          ContentUnavailableView("没有找到匹配工作流", systemImage: "magnifyingglass")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          ScrollView {
            LazyVStack(spacing: 6) {
              ForEach(filteredWorkflows) { workflow in
                WorkflowListButton(
                  workflow: workflow,
                  isSelected: selectedWorkflowID == workflow.id
                ) {
                  selectWorkflow(workflow)
                }
              }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 12)
          }
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)

      Divider()

      Button {
        editingWorkflow = newWorkflowTemplate()
      } label: {
        Label("新建工作流", systemImage: "plus")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .padding(12)
    }
  }

  @ViewBuilder
  private var workflowDetailPanel: some View {
    if let workflow = selectedWorkflow {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          workflowHeader(workflow)
          metadataGrid(for: workflow)
          actionList(for: workflow)
          latestResult(for: workflow)
        }
        .frame(maxWidth: DevPilotLayout.workflowDetailMaxWidth, alignment: .leading)
        .padding(20)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    } else {
      ContentUnavailableView("请选择一个工作流", systemImage: "play.rectangle", description: Text("从左侧分类和列表中选择一个工作流。"))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }

  private func workflowHeader(_ workflow: Workflow) -> some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(alignment: .top, spacing: 16) {
        Image(systemName: workflow.icon)
          .font(.system(size: 28, weight: .semibold))
          .foregroundStyle(.secondary)
          .frame(width: 52, height: 52)
          .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))

        VStack(alignment: .leading, spacing: 8) {
          HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(workflow.name)
              .font(.title2.bold())
              .lineLimit(2)
            workflowTag(workflow.isBuiltIn ? "内置" : "自定义", tint: workflow.isBuiltIn ? .blue : .green)
            if !workflow.isEnabled {
              workflowTag("已停用", tint: .secondary)
            }
          }
          Text(workflow.description)
            .foregroundStyle(.secondary)
        }

        Spacer(minLength: 16)
      }

      HStack(spacing: 8) {
        Button {
          Task { await appState.runWorkflow(workflow) }
        } label: {
          Label("运行", systemImage: "play.fill")
        }
        .buttonStyle(.borderedProminent)
        .disabled(appState.isRunningWorkflow || !workflow.isEnabled)

        Button {
          editingWorkflow = workflow
        } label: {
          Label("编辑", systemImage: "pencil")
        }

        Button {
          appState.duplicateWorkflow(workflow)
          selectedWorkflowID = appState.workflows.last?.id
          ensureSelectedWorkflowVisible()
        } label: {
          Label("复制", systemImage: "doc.on.doc")
        }

        Button(role: .destructive) {
          appState.deleteWorkflow(workflow)
          ensureSelectedWorkflowVisible()
        } label: {
          Label("删除", systemImage: "trash")
        }
      }
    }
  }

  private func metadataGrid(for workflow: Workflow) -> some View {
    Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 8) {
      metadataRow("分类", workflow.category.rawValue)
      metadataRow("类型", workflow.isBuiltIn ? "内置模板" : "自定义")
      metadataRow("状态", workflow.isEnabled ? "已启用" : "已停用")
      metadataRow("显示位置", displayLocations(for: workflow))
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

  private func actionList(for workflow: Workflow) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("动作列表")
        .font(.headline)

      if workflow.actions.isEmpty {
        ContentUnavailableView("还没有动作", systemImage: "list.bullet", description: Text("点击编辑后添加一个动作。"))
          .frame(maxWidth: .infinity, minHeight: 160)
          .background(Color.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
      } else {
        VStack(alignment: .leading, spacing: 8) {
          ForEach(workflow.actions) { action in
            actionRow(action)
          }
        }
      }
    }
  }

  private func actionRow(_ action: WorkflowAction) -> some View {
    HStack(alignment: .top, spacing: 10) {
      Image(systemName: icon(for: action.type))
        .frame(width: 22)
        .foregroundStyle(action.isEnabled ? .primary : .secondary)

      VStack(alignment: .leading, spacing: 4) {
        HStack {
          Text(action.title.isEmpty ? action.type.displayName : action.title)
            .font(.headline)
          Text(action.type.displayName)
            .font(.caption)
            .foregroundStyle(.secondary)
          if !action.isEnabled {
            Text("已停用")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          if let risk = appState.riskLevel(for: action) {
            RiskBadge(risk: risk)
          }
        }

        Text(action.value.isEmpty ? "需要配置" : action.value)
          .font(.system(.callout, design: action.type == .runShellCommand ? .monospaced : .default))
          .foregroundStyle(action.value.isEmpty ? .orange : .secondary)

        if let workingDirectory = action.workingDirectory, !workingDirectory.isEmpty {
          Text("工作目录：\(workingDirectory)")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      Spacer()
    }
    .padding(10)
    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
  }

  private func latestResult(for workflow: Workflow) -> some View {
    GroupBox("最近结果") {
      let results = appState.workflowRunHistory.filter { $0.workflowId == workflow.id }.prefix(3)
      if results.isEmpty {
        ContentUnavailableView("还没有运行记录", systemImage: "clock", description: Text("运行一次后会显示结果。"))
      } else {
        VStack(alignment: .leading, spacing: 10) {
          ForEach(Array(results)) { result in
            VStack(alignment: .leading, spacing: 6) {
              Label(result.success ? "成功" : "失败", systemImage: result.success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(result.success ? .green : .orange)
              ForEach(result.actionResults) { actionResult in
                let message = actionResult.error ?? actionResult.message
                Text(message)
                  .font(.caption)
                  .foregroundStyle(actionResult.success ? Color.secondary : Color.red)
              }
            }
            .padding(8)
            .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }

  private func workflowTag(_ title: String, tint: Color) -> some View {
    Text(title)
      .font(.caption.weight(.semibold))
      .foregroundStyle(tint)
      .padding(.horizontal, 8)
      .padding(.vertical, 3)
      .background(tint.opacity(0.12), in: Capsule())
  }

  private func icon(for type: WorkflowActionType) -> String {
    switch type {
    case .openApp: "app"
    case .openFolder: "folder"
    case .openURL: "link"
    case .runShellCommand: "terminal"
    }
  }

  private func selectCategory(_ category: WorkflowCategory) {
    selectedWorkflowCategory = category
    workflowSearchText = ""
    if let first = appState.workflows.first(where: { category.matches($0) }) {
      selectWorkflow(first)
    } else {
      selectedWorkflowID = nil
    }
  }

  private func selectWorkflow(_ workflow: Workflow) {
    selectedWorkflowID = workflow.id
  }

  private func ensureSelectedWorkflowVisible() {
    if let selectedWorkflowID,
       filteredWorkflows.contains(where: { $0.id == selectedWorkflowID }) {
      return
    }

    selectedWorkflowID = filteredWorkflows.first?.id
  }

  private func workflowCount(for category: WorkflowCategory) -> Int {
    appState.workflows.filter { category.matches($0) }.count
  }

  private func newWorkflowTemplate() -> Workflow {
    var workflow = Workflow.customTemplate()
    if !selectedWorkflowCategory.isFilterOnly {
      workflow.category = selectedWorkflowCategory
      workflow.icon = selectedWorkflowCategory.systemImage
    }
    return workflow
  }

  private func displayLocations(for workflow: Workflow) -> String {
    var locations: [String] = []
    if workflow.showInHome {
      locations.append("首页显示")
    }
    if workflow.showInMenuBar {
      locations.append("菜单栏显示")
    }
    return locations.isEmpty ? "未显示" : locations.joined(separator: " / ")
  }
}

private struct WorkflowCategoryButton: View {
  let category: WorkflowCategory
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

private struct WorkflowListButton: View {
  let workflow: Workflow
  let isSelected: Bool
  let action: () -> Void

  @State private var isHovering = false

  var body: some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: 7) {
        HStack(alignment: .top, spacing: 8) {
          Image(systemName: workflow.icon)
            .frame(width: 18)
            .padding(.top, 2)

          VStack(alignment: .leading, spacing: 4) {
            Text(workflow.name)
              .font(.headline)
              .lineLimit(1)
            Text(workflow.description)
              .font(.caption)
              .foregroundStyle(isSelected ? .white.opacity(0.88) : .secondary)
              .lineLimit(2)
          }

          Spacer(minLength: 8)
        }

        HStack(spacing: 6) {
          workflowBadge(workflow.isBuiltIn ? "内置" : "自定义")
          workflowBadge(workflow.isEnabled ? "已启用" : "已停用")
        }
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

  private func workflowBadge(_ title: String) -> some View {
    Text(title)
      .font(.caption2)
      .foregroundStyle(isSelected ? .white.opacity(0.86) : .secondary)
      .padding(.horizontal, 6)
      .padding(.vertical, 3)
      .background(isSelected ? Color.white.opacity(0.16) : Color.secondary.opacity(0.10))
      .clipShape(RoundedRectangle(cornerRadius: 6))
  }

  private var rowBackground: Color {
    if isSelected { return .accentColor }
    if isHovering { return Color.secondary.opacity(0.10) }
    return Color.secondary.opacity(0.05)
  }
}

private struct WorkflowEditorView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var draft: Workflow
  @State private var newActionType: WorkflowActionType = .openApp
  private let onSave: (Workflow) -> Void
  private let validator = CommandSafetyValidator()

  init(workflow: Workflow, onSave: @escaping (Workflow) -> Void) {
    _draft = State(initialValue: workflow)
    self.onSave = onSave
  }

  var body: some View {
    VStack(spacing: 0) {
      Form {
        Section("基本信息") {
          TextField("名称", text: $draft.name)
          TextField("描述", text: $draft.description, axis: .vertical)
            .lineLimit(2...4)
          TextField("SF Symbol 图标名", text: $draft.icon)
          Picker("分类", selection: $draft.category) {
            ForEach(editableCategories) { category in
              Label(category.rawValue, systemImage: category.systemImage)
                .tag(category)
            }
          }
        }

        Section("显示") {
          Toggle("启用工作流", isOn: $draft.isEnabled)
          Toggle("显示在首页", isOn: $draft.showInHome)
          Toggle("显示在菜单栏", isOn: $draft.showInMenuBar)
        }

        Section("动作") {
          HStack {
            Picker("动作类型", selection: $newActionType) {
              ForEach(WorkflowActionType.allCases) { type in
                Text(type.displayName)
                  .tag(type)
              }
            }
            Button {
              draft.actions.append(WorkflowAction(type: newActionType, title: newActionType.displayName, value: ""))
            } label: {
              Label("添加动作", systemImage: "plus")
            }
          }

          ForEach($draft.actions) { $action in
            actionEditor(action: $action)
          }
        }
      }
      .formStyle(.grouped)

      Divider()

      HStack {
        Spacer()
        Button("取消") {
          dismiss()
        }
        Button("保存") {
          draft.updatedAt = Date()
          onSave(draft)
          dismiss()
        }
        .buttonStyle(.borderedProminent)
        .disabled(draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
      .padding()
    }
    .frame(minWidth: 640, minHeight: 620)
  }

  private func actionEditor(action: Binding<WorkflowAction>) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Picker("类型", selection: action.type) {
          ForEach(WorkflowActionType.allCases) { type in
            Text(type.displayName)
              .tag(type)
          }
        }
        .frame(width: 170)

        Toggle("启用", isOn: action.isEnabled)
        Toggle("失败后继续", isOn: action.continueOnFailure)

        Spacer()

        Button {
          moveAction(action.wrappedValue, offset: -1)
        } label: {
          Image(systemName: "chevron.up")
        }
        .disabled(actionIndex(action.wrappedValue) == 0)

        Button {
          moveAction(action.wrappedValue, offset: 1)
        } label: {
          Image(systemName: "chevron.down")
        }
        .disabled(actionIndex(action.wrappedValue) == draft.actions.count - 1)

        Button(role: .destructive) {
          draft.actions.removeAll { $0.id == action.wrappedValue.id }
        } label: {
          Image(systemName: "trash")
        }
      }

      TextField("动作标题", text: action.title)
      TextField(valueLabel(for: action.wrappedValue.type), text: action.value, axis: action.wrappedValue.type == .runShellCommand ? .vertical : .horizontal)
        .font(action.wrappedValue.type == .runShellCommand ? .system(.body, design: .monospaced) : .body)
        .lineLimit(action.wrappedValue.type == .runShellCommand ? 2...4 : 1...1)

      if action.wrappedValue.type == .runShellCommand {
        TextField("工作目录（可选）", text: Binding(
          get: { action.wrappedValue.workingDirectory ?? "" },
          set: { action.wrappedValue.workingDirectory = $0.isEmpty ? nil : $0 }
        ))
        Toggle("运行前需要确认", isOn: action.requiresConfirmation)
        HStack {
          RiskBadge(risk: validator.evaluate(action.wrappedValue.value))
          if let reason = validator.reason(for: action.wrappedValue.value) {
            Text(reason)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      }
    }
    .padding(10)
    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
  }

  private func valueLabel(for type: WorkflowActionType) -> String {
    switch type {
    case .openApp: "App 名称或路径"
    case .openFolder: "文件夹路径"
    case .openURL: "网址"
    case .runShellCommand: "Shell 命令"
    }
  }

  private func actionIndex(_ action: WorkflowAction) -> Int? {
    draft.actions.firstIndex(where: { $0.id == action.id })
  }

  private func moveAction(_ action: WorkflowAction, offset: Int) {
    guard let index = actionIndex(action) else {
      return
    }
    let newIndex = index + offset
    guard draft.actions.indices.contains(newIndex) else {
      return
    }
    draft.actions.swapAt(index, newIndex)
  }

  private var editableCategories: [WorkflowCategory] {
    [.custom, .coding, .study, .school, .ai, .media, .utility]
  }
}

private struct RiskBadge: View {
  let risk: CommandRiskLevel

  var body: some View {
    Text(risk.displayName)
      .font(.caption.weight(.semibold))
      .foregroundStyle(color)
      .padding(.horizontal, 8)
      .padding(.vertical, 3)
      .background(color.opacity(0.14), in: Capsule())
  }

  private var color: Color {
    switch risk {
    case .safe: .green
    case .needsConfirmation: .yellow
    case .blocked: .red
    }
  }
}
