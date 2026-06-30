import Foundation

@MainActor
enum DevPilotRuntime {
  static let appState = AppState()
  static var statusItemController: StatusItemController?
}
