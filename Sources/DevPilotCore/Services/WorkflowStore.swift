import Combine
import Foundation

public final class WorkflowStore: ObservableObject {
  @Published public private(set) var workflows: [Workflow] = []

  private let fileURL: URL
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder

  public init(fileURL: URL = WorkflowStore.defaultFileURL()) {
    self.fileURL = fileURL
    encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .iso8601
    decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
  }

  public func load() {
    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      workflows = Workflow.defaultTemplates()
      save()
      return
    }

    do {
      let data = try Data(contentsOf: fileURL)
      workflows = try decoder.decode([Workflow].self, from: data)
    } catch {
      backupCorruptFile()
      workflows = Workflow.defaultTemplates()
      save()
    }
  }

  public func save() {
    do {
      try FileManager.default.createDirectory(
        at: fileURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
      )
      let data = try encoder.encode(workflows)
      try data.write(to: fileURL, options: .atomic)
    } catch {
      assertionFailure("Failed to save workflows: \(error.localizedDescription)")
    }
  }

  public func create(_ workflow: Workflow) {
    var copy = workflow
    copy.name = uniqueName(for: copy.name)
    copy.updatedAt = Date()
    workflows.append(copy)
    save()
  }

  public func update(_ workflow: Workflow) {
    guard let index = workflows.firstIndex(where: { $0.id == workflow.id }) else {
      return
    }
    var copy = workflow
    copy.updatedAt = Date()
    workflows[index] = copy
    save()
  }

  public func delete(_ workflow: Workflow) {
    workflows.removeAll { $0.id == workflow.id }
    save()
  }

  public func duplicate(_ workflow: Workflow) {
    var copy = workflow
    copy.id = UUID()
    copy.name = uniqueName(for: "\(workflow.name) 副本")
    copy.isBuiltIn = false
    copy.createdAt = Date()
    copy.updatedAt = copy.createdAt
    workflows.append(copy)
    save()
  }

  public func resetBuiltInTemplates() {
    for template in Workflow.defaultTemplates() {
      var copy = template
      copy.name = uniqueName(for: template.name)
      workflows.append(copy)
    }
    save()
  }

  public static func defaultFileURL() -> URL {
    FileManager.default
      .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("DevPilot", isDirectory: true)
      .appendingPathComponent("workflows.json")
  }

  private func uniqueName(for baseName: String) -> String {
    let trimmedName = baseName.trimmingCharacters(in: .whitespacesAndNewlines)
    let fallback = trimmedName.isEmpty ? "新的工作流" : trimmedName
    let existingNames = Set(workflows.map(\.name))
    guard existingNames.contains(fallback) else {
      return fallback
    }

    var suffix = 2
    while existingNames.contains("\(fallback) \(suffix)") {
      suffix += 1
    }
    return "\(fallback) \(suffix)"
  }

  private func backupCorruptFile() {
    let backupURL = fileURL.deletingLastPathComponent().appendingPathComponent("workflows.corrupt.json")
    try? FileManager.default.removeItem(at: backupURL)
    try? FileManager.default.moveItem(at: fileURL, to: backupURL)
  }
}
