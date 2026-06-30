import AppKit
import DevPilotCore
import SwiftUI

struct EnvironmentView: View {
  @EnvironmentObject private var appState: AppState
  @State private var searchText = ""
  @State private var statusFilter: EnvironmentStatusFilter = .all
  @State private var expandedCategories = Set(DevToolCategory.allCases)

  private var filteredStatuses: [DevToolStatus] {
    appState.environmentStatuses.filter { status in
      let matchesSearch = searchText.isEmpty
        || status.name.localizedCaseInsensitiveContains(searchText)
        || status.category.rawValue.localizedCaseInsensitiveContains(searchText)
      return matchesSearch && statusFilter.matches(status)
    }
  }

  private var installedCount: Int {
    appState.environmentStatuses.filter(\.installed).count
  }

  private var failedCount: Int {
    appState.environmentStatuses.filter { $0.installed && $0.errorMessage != nil }.count
  }

  private var missingCount: Int {
    appState.environmentStatuses.filter { !$0.installed }.count
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      header
      summaryBar
      controls

      if appState.environmentStatuses.isEmpty {
        ContentUnavailableView("暂无检测结果", systemImage: "stethoscope", description: Text("点击重新检测，检查常见 Mac 开发环境。"))
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 12) {
            ForEach(DevToolCategory.allCases) { category in
              let statuses = filteredStatuses.filter { $0.category == category }
              if !statuses.isEmpty {
                categorySection(category, statuses: statuses)
              }
            }
          }
          .padding(.vertical, 4)
        }
      }
    }
    .padding(20)
    .task {
      if appState.environmentStatuses.isEmpty {
        await appState.refreshEnvironment()
      }
    }
  }

  private var header: some View {
    HStack {
      Text("开发环境检测")
        .font(.title2.bold())

      Spacer()

      Button {
        Task { await appState.refreshEnvironment() }
      } label: {
        Label(appState.isCheckingEnvironment ? "检测中" : "重新检测", systemImage: "arrow.clockwise")
      }
      .disabled(appState.isCheckingEnvironment)
    }
  }

  private var summaryBar: some View {
    HStack(spacing: 10) {
      SummaryPill(title: "已安装", value: installedCount, color: .green)
      SummaryPill(title: "未安装", value: missingCount, color: .secondary)
      SummaryPill(title: "检测失败", value: failedCount, color: .orange)
      Spacer()
    }
  }

  private var controls: some View {
    HStack(spacing: 12) {
      TextField("搜索工具或分类", text: $searchText)
        .textFieldStyle(.roundedBorder)
        .frame(maxWidth: 280)

      Picker("筛选", selection: $statusFilter) {
        ForEach(EnvironmentStatusFilter.allCases) { filter in
          Text(filter.title).tag(filter)
        }
      }
      .pickerStyle(.segmented)
      .frame(width: 300)

      Spacer()
    }
  }

  private func categorySection(_ category: DevToolCategory, statuses: [DevToolStatus]) -> some View {
    DisclosureGroup(isExpanded: Binding(
      get: { expandedCategories.contains(category) },
      set: { isExpanded in
        if isExpanded {
          expandedCategories.insert(category)
        } else {
          expandedCategories.remove(category)
        }
      }
    )) {
      LazyVStack(alignment: .leading, spacing: 8) {
        ForEach(statuses) { status in
          ToolStatusRow(status: status)
        }
      }
      .padding(.top, 8)
    } label: {
      HStack {
        Text(category.rawValue)
          .font(.headline)
        Text("\(statuses.count)")
          .font(.caption)
          .foregroundStyle(.secondary)
        Spacer()
      }
      .contentShape(Rectangle())
    }
    .padding(12)
    .background(.regularMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 8))
  }
}

private struct ToolStatusRow: View {
  let status: DevToolStatus

  var body: some View {
    Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
      GridRow {
        VStack(alignment: .leading, spacing: 3) {
          Text(status.name)
            .font(.headline)
          if let description = status.description {
            Text(description)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(2)
          }
        }
        .frame(minWidth: 150, maxWidth: .infinity, alignment: .leading)

        Label(statusTitle, systemImage: statusIcon)
          .foregroundStyle(statusColor)
          .frame(width: 110, alignment: .leading)

        Text(status.version ?? status.errorMessage ?? "-")
          .lineLimit(1)
          .help(status.version ?? status.errorMessage ?? "")
          .frame(minWidth: 160, maxWidth: .infinity, alignment: .leading)

        pathView
          .frame(minWidth: 180, maxWidth: .infinity, alignment: .leading)
      }

      if let installHint = status.installHint, !status.installed {
        GridRow {
          Text("")
          Text("安装建议")
            .font(.caption)
            .foregroundStyle(.secondary)
          Text(installHint)
            .font(.system(.caption, design: .monospaced))
            .textSelection(.enabled)
            .lineLimit(1)
            .help(installHint)
          Button {
            copy(installHint)
          } label: {
            Label("复制", systemImage: "doc.on.doc")
          }
          .buttonStyle(.borderless)
        }
      }
    }
    .padding(10)
    .background(Color.secondary.opacity(0.08))
    .clipShape(RoundedRectangle(cornerRadius: 8))
  }

  private var pathView: some View {
    HStack(spacing: 6) {
      Text(status.path ?? "-")
        .font(.system(.caption, design: .monospaced))
        .lineLimit(1)
        .truncationMode(.middle)
        .help(status.path ?? "")

      if let path = status.path {
        Button {
          copy(path)
        } label: {
          Image(systemName: "doc.on.doc")
        }
        .buttonStyle(.borderless)
        .help("复制完整路径")
      }
    }
  }

  private var statusTitle: String {
    if status.installed, status.errorMessage != nil { return "检测失败" }
    return status.installed ? "已安装" : "未安装"
  }

  private var statusIcon: String {
    if status.installed, status.errorMessage != nil { return "exclamationmark.triangle.fill" }
    return status.installed ? "checkmark.circle.fill" : "xmark.circle"
  }

  private var statusColor: Color {
    if status.installed, status.errorMessage != nil { return .orange }
    return status.installed ? .green : .secondary
  }

  private func copy(_ text: String) {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)
  }
}

private struct SummaryPill: View {
  let title: String
  let value: Int
  let color: Color

  var body: some View {
    HStack(spacing: 6) {
      Circle()
        .fill(color)
        .frame(width: 7, height: 7)
      Text(title)
        .foregroundStyle(.secondary)
      Text("\(value)")
        .fontWeight(.semibold)
    }
    .font(.caption)
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .background(Color.secondary.opacity(0.10))
    .clipShape(RoundedRectangle(cornerRadius: 8))
  }
}

private enum EnvironmentStatusFilter: String, CaseIterable, Identifiable {
  case all
  case missing
  case installed

  var id: String { rawValue }

  var title: String {
    switch self {
    case .all: "全部"
    case .missing: "仅未安装"
    case .installed: "仅已安装"
    }
  }

  func matches(_ status: DevToolStatus) -> Bool {
    switch self {
    case .all:
      true
    case .missing:
      !status.installed
    case .installed:
      status.installed
    }
  }
}
