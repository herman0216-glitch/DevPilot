import AppKit
import DevPilotCore
import SwiftUI

struct SettingsView: View {
  @EnvironmentObject private var appState: AppState

  var body: some View {
    Form {
      Section("开发模式") {
        directoryField("默认项目文件夹", path: $appState.defaultProjectFolder)
        TextField("默认 localhost URL", text: $appState.defaultBrowserURL)

        Picker("默认代码编辑器", selection: $appState.selectedEditor) {
          ForEach(CodeEditor.allCases) { editor in
            Text(editor.rawValue)
              .tag(editor)
          }
        }

        Toggle("运行 npm run dev", isOn: $appState.shouldRunNpmDev)
      }

      Section("命令执行") {
        directoryField("默认工作目录", path: $appState.commandWorkingDirectory)
      }

      Section("环境检测") {
        Toggle("启动时自动检测环境", isOn: $appState.autoCheckEnvironmentOnLaunch)
        VStack(alignment: .leading, spacing: 6) {
          Text("PATH")
            .foregroundStyle(.secondary)
          Text(appState.environmentPathSummary)
            .font(.system(.caption, design: .monospaced))
            .textSelection(.enabled)
          .lineLimit(4)
        }
      }

      Section("工作流") {
        Button {
          appState.resetDefaultWorkflowTemplates()
        } label: {
          Label("恢复默认工作流模板", systemImage: "arrow.counterclockwise")
        }

        LabeledContent("导入 / 导出") {
          Text("v0.2 计划支持")
            .foregroundStyle(.secondary)
        }
      }
    }
    .formStyle(.grouped)
    .padding(20)
  }

  private func directoryField(_ title: String, path: Binding<String>) -> some View {
    HStack {
      TextField(title, text: path)
      Button {
        chooseDirectory(path: path)
      } label: {
        Label("选择", systemImage: "folder.badge.plus")
      }
    }
  }

  private func chooseDirectory(path: Binding<String>) {
    let panel = NSOpenPanel()
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = false
    panel.directoryURL = URL(fileURLWithPath: path.wrappedValue.isEmpty ? NSHomeDirectory() : path.wrappedValue)
    if panel.runModal() == .OK, let url = panel.url {
      path.wrappedValue = url.path
    }
  }
}
