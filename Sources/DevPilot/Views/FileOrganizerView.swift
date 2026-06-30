import DevPilotCore
import SwiftUI

struct FileOrganizerView: View {
  @EnvironmentObject private var appState: AppState

  private var downloadsPath: String {
    FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?.path ?? "\(NSHomeDirectory())/Downloads"
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        header
        pathSection
        rulesSection
        resultSection
      }
      .padding(24)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private var header: some View {
    HStack(alignment: .top) {
      VStack(alignment: .leading, spacing: 8) {
        Text("下载整理")
          .font(.title.bold())
        Text("按文件类型把 Downloads 中的常见文件移动到分类文件夹。")
          .foregroundStyle(.secondary)
      }

      Spacer()

      Button {
        Task { await appState.organizeDownloads() }
      } label: {
        Label("开始整理", systemImage: "folder.badge.gearshape")
      }
      .buttonStyle(.borderedProminent)
    }
  }

  private var pathSection: some View {
    GroupBox("Downloads 路径") {
      Text(downloadsPath)
        .font(.system(.body, design: .monospaced))
        .textSelection(.enabled)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(4)
    }
  }

  private var rulesSection: some View {
    GroupBox("整理规则") {
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 10)], spacing: 10) {
        RuleView(title: "Installers", examples: "dmg, pkg")
        RuleView(title: "Archives", examples: "zip, rar, 7z")
        RuleView(title: "Documents", examples: "pdf, docx, pptx")
        RuleView(title: "Images", examples: "png, jpg, webp")
        RuleView(title: "3D Models", examples: "stl, obj, blend")
        RuleView(title: "Code", examples: "js, ts, vue, py, java")
        RuleView(title: "Data", examples: "csv, xlsx")
        RuleView(title: "Others", examples: "其他扩展名")
      }
      .padding(4)
    }
  }

  private var resultSection: some View {
    GroupBox("整理结果") {
      if let result = appState.organizeResult {
        VStack(alignment: .leading, spacing: 14) {
          HStack(spacing: 12) {
            OrganizerMetricView(title: "扫描", value: result.scannedCount)
            OrganizerMetricView(title: "移动", value: result.movedCount)
            OrganizerMetricView(title: "跳过", value: result.skippedCount)
            OrganizerMetricView(title: "错误", value: result.errors.count)
          }

          VStack(alignment: .leading, spacing: 8) {
            Text("错误列表")
              .font(.headline)

            if result.errors.isEmpty {
              Label("没有错误", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
            } else {
              ForEach(result.errors) { error in
                VStack(alignment: .leading, spacing: 4) {
                  Text(error.fileName)
                    .font(.headline)
                  Text(error.message)
                    .foregroundStyle(.secondary)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
              }
            }
          }
        }
        .padding(4)
      } else {
        ContentUnavailableView("暂无整理结果", systemImage: "tray", description: Text("点击开始整理后会在这里显示扫描、移动、跳过和错误数量。"))
          .frame(maxWidth: .infinity)
      }
    }
  }
}

private struct RuleView: View {
  let title: String
  let examples: String

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .font(.headline)
      Text(examples)
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(2)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(10)
    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
  }
}

private struct OrganizerMetricView: View {
  let title: String
  let value: Int

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .font(.caption)
        .foregroundStyle(.secondary)
      Text("\(value)")
        .font(.title.bold())
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
  }
}
