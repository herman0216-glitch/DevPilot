import DevPilotCore
import AppKit
import SwiftUI

struct MainWindowView: View {
  @EnvironmentObject private var appState: AppState

  var body: some View {
    HStack(spacing: 0) {
      SidebarView(selectedPage: $appState.selectedPage)
        .frame(width: DevPilotLayout.mainSidebarWidth)
        .frame(minWidth: DevPilotLayout.mainSidebarWidth, maxWidth: DevPilotLayout.mainSidebarWidth)

      Divider()

      detailView
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    .frame(
      minWidth: DevPilotLayout.mainWindowMinWidth,
      minHeight: DevPilotLayout.mainWindowMinHeight
    )
    .background(WindowSizeConfigurator())
    .task {
      if appState.autoCheckEnvironmentOnLaunch, appState.environmentStatuses.isEmpty {
        await appState.refreshEnvironment()
      }
    }
  }

  @ViewBuilder
  private var detailView: some View {
    switch appState.selectedPage {
    case .home:
      HomeView()
    case .workflows:
      WorkflowsView()
    case .environment:
      EnvironmentView()
    case .commands:
      CommandPanelView()
    case .fileOrganizer:
      FileOrganizerView()
    case .settings:
      SettingsView()
    }
  }
}

private struct WindowSizeConfigurator: NSViewRepresentable {
  func makeNSView(context: Context) -> NSView {
    let view = NSView()
    DispatchQueue.main.async {
      view.window?.minSize = NSSize(
        width: DevPilotLayout.mainWindowMinWidth,
        height: DevPilotLayout.mainWindowMinHeight
      )
    }
    return view
  }

  func updateNSView(_ nsView: NSView, context: Context) {
    DispatchQueue.main.async {
      nsView.window?.minSize = NSSize(
        width: DevPilotLayout.mainWindowMinWidth,
        height: DevPilotLayout.mainWindowMinHeight
      )
    }
  }
}
