import DevPilotCore
import SwiftUI

struct HomeView: View {
  @EnvironmentObject private var appState: AppState

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
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        header
        quickWorkflows
        utilityActions
        environmentOverview
        latestWorkflow
        latestOrganizerResult
      }
      .padding(24)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("DevPilot")
        .font(.largeTitle.bold())
      Text("把开发、学习、环境检查和常用命令收进一个主窗口。")
        .foregroundStyle(.secondary)
    }
  }

  private var quickWorkflows: some View {
    GroupBox("快捷工作流") {
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 12)], spacing: 12) {
        let workflows = appState.workflows.filter { $0.showInHome && $0.isEnabled }
        if workflows.isEmpty {
          ContentUnavailableView("还没有快捷工作流", systemImage: "paperplane", description: Text("到工作流页面勾选“显示在首页”。"))
            .frame(maxWidth: .infinity)
        } else {
          ForEach(workflows) { workflow in
            HomeActionButton(title: workflow.name, systemImage: workflow.icon) {
              Task { await appState.runWorkflow(workflow) }
            }
          }
        }
      }
      .padding(4)

      if appState.workflows.allSatisfy(\.isBuiltIn) {
        Text("还没有自定义工作流，可以在工作流页面创建你的第一个工作流。")
          .font(.callout)
          .foregroundStyle(.secondary)
          .padding(.top, 8)
      }
    }
  }

  private var utilityActions: some View {
    GroupBox("常用工具") {
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 12)], spacing: 12) {
        HomeActionButton(title: "查看环境检测", systemImage: "terminal") {
          appState.switchToPage(.environment)
        }

        HomeActionButton(title: "打开常用命令", systemImage: "command") {
          appState.switchToPage(.commands)
        }

        HomeActionButton(title: "整理下载目录", systemImage: "folder.badge.gearshape") {
          Task {
            await appState.organizeDownloads()
            appState.switchToPage(.fileOrganizer)
          }
        }
      }
      .padding(4)
    }
  }

  private var environmentOverview: some View {
    GroupBox("当前 Mac 开发环境摘要") {
      VStack(alignment: .leading, spacing: 12) {
        HStack(spacing: 12) {
          HomeMetricCard(title: "已安装", value: installedCount, tint: .green)
          HomeMetricCard(title: "未安装", value: missingCount, tint: .secondary)
          HomeMetricCard(title: "检测失败", value: failedCount, tint: .orange)
        }

        if appState.environmentStatuses.isEmpty {
          Text("还没有环境检测结果。可以打开环境检测页或启用启动自动检测。")
            .font(.callout)
            .foregroundStyle(.secondary)
        } else {
          Text("最近检测覆盖 \(appState.environmentStatuses.count) 个工具。")
            .font(.callout)
            .foregroundStyle(.secondary)
        }
      }
      .padding(4)
    }
  }

  private var latestWorkflow: some View {
    GroupBox("最近执行") {
      if let result = appState.lastWorkflowResult {
        VStack(alignment: .leading, spacing: 10) {
          Label(result.workflowName, systemImage: result.succeeded ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
            .foregroundStyle(result.succeeded ? .green : .orange)

          ForEach(result.actionResults) { actionResult in
            VStack(alignment: .leading, spacing: 4) {
              Text(actionResult.error ?? actionResult.message)
                .font(.callout)
                .foregroundStyle(actionResult.success ? Color.primary : Color.red)
              if let output = actionResult.output, !output.isEmpty {
                Text(output)
                  .font(.system(.caption, design: .monospaced))
                  .foregroundStyle(.secondary)
                  .lineLimit(4)
              }
            }
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(4)
      } else {
        ContentUnavailableView("还没有执行工作流", systemImage: "paperplane", description: Text("从快捷操作或工作流页面开始。"))
          .frame(maxWidth: .infinity)
      }
    }
  }

  private var latestOrganizerResult: some View {
    GroupBox("最近一次下载整理结果") {
      if let result = appState.organizeResult {
        HStack(spacing: 12) {
          HomeMetricCard(title: "扫描", value: result.scannedCount, tint: .blue)
          HomeMetricCard(title: "移动", value: result.movedCount, tint: .green)
          HomeMetricCard(title: "跳过", value: result.skippedCount, tint: .secondary)
          HomeMetricCard(title: "错误", value: result.errors.count, tint: result.errors.isEmpty ? .secondary : .orange)
        }
        .padding(4)
      } else {
        ContentUnavailableView("暂无整理记录", systemImage: "tray", description: Text("点击整理下载目录后会显示最新结果。"))
          .frame(maxWidth: .infinity)
      }
    }
  }
}

private struct HomeActionButton: View {
  let title: String
  let systemImage: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Label(title, systemImage: systemImage)
        .frame(maxWidth: .infinity, minHeight: 36)
    }
    .buttonStyle(.bordered)
  }
}

private struct HomeMetricCard: View {
  let title: String
  let value: Int
  let tint: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      HStack(spacing: 6) {
        Circle()
          .fill(tint)
          .frame(width: 7, height: 7)
        Text(title)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Text("\(value)")
        .font(.title2.bold())
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
  }
}
