import AppKit
import DevPilotCore
import SwiftUI

@MainActor
final class StatusItemController: NSObject, NSMenuDelegate, NSWindowDelegate {
  private let appState: AppState
  private let statusItem: NSStatusItem
  private var mainWindow: NSWindow?

  init(appState: AppState) {
    self.appState = appState
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    super.init()
    configureStatusItem()
  }

  func menuNeedsUpdate(_ menu: NSMenu) {
    rebuildMenu(menu)
  }

  private func configureStatusItem() {
    statusItem.length = DevPilotMenuBarItem.statusItemLength
    if let button = statusItem.button {
      button.title = ""
      button.attributedTitle = NSAttributedString(string: "")
      button.image = loadStatusImage()
      button.imagePosition = .imageOnly
      button.toolTip = DevPilotMenuBarItem.accessibilityLabel
      button.setAccessibilityLabel(DevPilotMenuBarItem.accessibilityLabel)
      button.setAccessibilityTitle(DevPilotMenuBarItem.accessibilityLabel)
    }

    let menu = NSMenu()
    menu.delegate = self
    rebuildMenu(menu)
    statusItem.menu = menu
  }

  private func rebuildMenu(_ menu: NSMenu) {
    menu.removeAllItems()

    addItem("打开 DevPilot", to: menu, action: #selector(openHome))
    menu.addItem(.separator())

    let workflows = appState.workflows.filter { $0.showInMenuBar && $0.isEnabled }
    if workflows.isEmpty {
      let item = NSMenuItem(title: "暂无快捷工作流", action: nil, keyEquivalent: "")
      item.isEnabled = false
      menu.addItem(item)
    } else {
      for workflow in workflows {
        let item = addItem(menuTitle(for: workflow), to: menu, action: #selector(runWorkflow(_:)))
        item.representedObject = workflow.id
      }
    }

    addItem("整理下载目录", to: menu, action: #selector(organizeDownloads))
    menu.addItem(.separator())
    addItem("设置", to: menu, action: #selector(openSettings))
    addItem("退出", to: menu, action: #selector(quit))
  }

  @discardableResult
  private func addItem(_ title: String, to menu: NSMenu, action: Selector) -> NSMenuItem {
    let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
    item.target = self
    menu.addItem(item)
    return item
  }

  @objc private func openHome() {
    openMainWindow(page: .home)
  }

  @objc private func openSettings() {
    openMainWindow(page: .settings)
  }

  @objc private func organizeDownloads() {
    Task {
      await appState.organizeDownloads()
      openMainWindow(page: .fileOrganizer)
    }
  }

  @objc private func runWorkflow(_ sender: NSMenuItem) {
    guard
      let workflowId = sender.representedObject as? UUID,
      let workflow = appState.workflows.first(where: { $0.id == workflowId })
    else {
      return
    }

    Task {
      await appState.runWorkflow(workflow)
      openMainWindow(page: .home)
    }
  }

  @objc private func quit() {
    NSApplication.shared.terminate(nil)
  }

  func openMainWindow(page: AppPage) {
    appState.openMainWindow(page: page)
    focusMainWindow()
  }

  func focusMainWindow() {
    let window = existingOrCreatedMainWindow()
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  func windowWillClose(_ notification: Notification) {
    guard notification.object as? NSWindow === mainWindow else {
      return
    }
    mainWindow = nil
  }

  private func existingOrCreatedMainWindow() -> NSWindow {
    if let mainWindow {
      return mainWindow
    }

    let rootView = MainWindowView()
      .environmentObject(appState)
      .frame(
        minWidth: DevPilotLayout.mainWindowMinWidth,
        minHeight: DevPilotLayout.mainWindowMinHeight
      )

    let window = NSWindow(contentViewController: NSHostingController(rootView: rootView))
    window.title = "DevPilot"
    window.identifier = NSUserInterfaceItemIdentifier("main")
    window.delegate = self
    window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
    window.setContentSize(NSSize(
      width: DevPilotLayout.mainWindowDefaultWidth,
      height: DevPilotLayout.mainWindowDefaultHeight
    ))
    window.minSize = NSSize(
      width: DevPilotLayout.mainWindowMinWidth,
      height: DevPilotLayout.mainWindowMinHeight
    )
    window.isReleasedWhenClosed = false
    mainWindow = window
    return window
  }

  private func menuTitle(for workflow: Workflow) -> String {
    if workflow.name.count <= 30 {
      return workflow.name
    }
    return "\(workflow.name.prefix(27))..."
  }

  private func loadStatusImage() -> NSImage {
    let image =
      loadMenuBarAsset()
      ?? NSImage(systemSymbolName: DevPilotMenuBarItem.fallbackSystemImage, accessibilityDescription: nil)
      ?? makeFallbackStatusImage()

    image.isTemplate = true
    image.size = NSSize(width: 18, height: 18)
    return image
  }

  private func loadMenuBarAsset() -> NSImage? {
    guard let url = Bundle.main.url(forResource: DevPilotMenuBarItem.assetName, withExtension: "png") else {
      return nil
    }

    let image = NSImage(contentsOf: url)
    image?.isTemplate = true
    return image
  }

  private func makeFallbackStatusImage() -> NSImage {
    let size = NSSize(width: 18, height: 18)
    let image = NSImage(size: size)
    image.lockFocus()
    defer { image.unlockFocus() }

    NSColor.black.setStroke()
    let plane = NSBezierPath()
    plane.move(to: NSPoint(x: 2.5, y: 9.5))
    plane.line(to: NSPoint(x: 15.5, y: 15))
    plane.line(to: NSPoint(x: 11.2, y: 3.2))
    plane.line(to: NSPoint(x: 8.7, y: 8))
    plane.line(to: NSPoint(x: 2.5, y: 9.5))
    plane.lineWidth = 1.8
    plane.lineJoinStyle = .round
    plane.lineCapStyle = .round
    plane.stroke()

    let trail = NSBezierPath()
    trail.move(to: NSPoint(x: 2, y: 4.5))
    trail.line(to: NSPoint(x: 6.3, y: 5.7))
    trail.move(to: NSPoint(x: 1.8, y: 13.8))
    trail.line(to: NSPoint(x: 5.5, y: 12.4))
    trail.lineWidth = 1.5
    trail.lineCapStyle = .round
    trail.stroke()
    return image
  }
}
