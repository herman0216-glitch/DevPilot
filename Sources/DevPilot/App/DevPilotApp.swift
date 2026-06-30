import AppKit
import DevPilotCore
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.regular)
    statusItemController.openMainWindow(page: .home)
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if flag {
      statusItemController.focusMainWindow()
    } else {
      statusItemController.openMainWindow(page: .home)
    }
    return true
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    false
  }

  private var statusItemController: StatusItemController {
    if let controller = DevPilotRuntime.statusItemController {
      return controller
    }

    let controller = StatusItemController(appState: DevPilotRuntime.appState)
    DevPilotRuntime.statusItemController = controller
    return controller
  }
}

@main
struct DevPilotApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
  @StateObject private var appState = DevPilotRuntime.appState

  init() {
    if DevPilotRuntime.statusItemController == nil {
      DevPilotRuntime.statusItemController = StatusItemController(appState: DevPilotRuntime.appState)
    }
  }

  var body: some Scene {
    Settings {
      EmptyView()
    }
    .commands {
      CommandGroup(replacing: .appTermination) {
        Button("退出 DevPilot") {
          NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
      }
    }
  }
}
