import DevPilotCore
import SwiftUI

struct SidebarView: View {
  @Binding var selectedPage: AppPage

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      VStack(alignment: .leading, spacing: 6) {
        Label("DevPilot", systemImage: "paperplane.circle.fill")
          .font(.title3.bold())
        Text("Mac 开发工作台")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .padding(.horizontal, 16)
      .padding(.top, 18)
      .padding(.bottom, 12)

      VStack(spacing: 4) {
        ForEach(AppPage.allCases) { page in
          sidebarItem(page)
        }
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 8)

      Spacer(minLength: 0)

      VStack(alignment: .leading, spacing: 4) {
        Text("DevPilot")
          .font(.caption.weight(.semibold))
        Text("v0.1")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
      .padding(16)
    }
    .frame(width: DevPilotLayout.mainSidebarWidth)
    .frame(minWidth: DevPilotLayout.mainSidebarWidth, maxWidth: DevPilotLayout.mainSidebarWidth)
    .background(.regularMaterial)
  }

  private func sidebarItem(_ page: AppPage) -> some View {
    Button {
      selectedPage = page
    } label: {
      HStack(spacing: 12) {
        Image(systemName: page.systemImage)
          .frame(width: 22, alignment: .center)

        Text(page.title)
          .font(.system(size: 15, weight: .semibold))
          .lineLimit(1)

        Spacer(minLength: 0)
      }
      .foregroundStyle(selectedPage == page ? Color.white : Color.primary)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 14)
      .padding(.vertical, 10)
      .background(selectedPage == page ? Color.accentColor : Color.clear, in: RoundedRectangle(cornerRadius: 10))
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}
