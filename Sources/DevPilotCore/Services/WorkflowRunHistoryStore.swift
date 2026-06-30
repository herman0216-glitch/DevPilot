import Combine
import Foundation

public final class WorkflowRunHistoryStore: ObservableObject {
  @Published public private(set) var results: [WorkflowRunResult] = []

  private let fileURL: URL
  private let limit: Int
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder

  public init(fileURL: URL = WorkflowRunHistoryStore.defaultFileURL(), limit: Int = 10) {
    self.fileURL = fileURL
    self.limit = limit
    encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .iso8601
    decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    load()
  }

  public func load() {
    guard FileManager.default.fileExists(atPath: fileURL.path),
          let data = try? Data(contentsOf: fileURL),
          let decoded = try? decoder.decode([WorkflowRunResult].self, from: data) else {
      results = []
      return
    }
    results = Array(decoded.sorted { $0.startedAt > $1.startedAt }.prefix(limit))
  }

  public func record(_ result: WorkflowRunResult) {
    results.insert(result, at: 0)
    results = Array(results.prefix(limit))
    save()
  }

  public func recentResults(for workflowId: UUID, limit resultLimit: Int = 3) -> [WorkflowRunResult] {
    Array(results.filter { $0.workflowId == workflowId }.prefix(resultLimit))
  }

  public static func defaultFileURL() -> URL {
    FileManager.default
      .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("DevPilot", isDirectory: true)
      .appendingPathComponent("workflow-history.json")
  }

  private func save() {
    do {
      try FileManager.default.createDirectory(
        at: fileURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
      )
      let data = try encoder.encode(results)
      try data.write(to: fileURL, options: .atomic)
    } catch {
      assertionFailure("Failed to save workflow history: \(error.localizedDescription)")
    }
  }
}
