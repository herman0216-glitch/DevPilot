import Foundation

public final class FileOrganizer {
  private let fileManager: FileManager

  public init(fileManager: FileManager = .default) {
    self.fileManager = fileManager
  }

  public func organizeDownloads() throws -> FileOrganizeResult {
    try organize(directory: FilePathHelper.downloadsDirectory)
  }

  public func organize(directory: URL) throws -> FileOrganizeResult {
    let urls = try fileManager.contentsOfDirectory(
      at: directory,
      includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey, .isHiddenKey],
      options: []
    )

    var scannedCount = 0
    var movedCount = 0
    var skippedCount = 0
    var errors: [FileOrganizeError] = []

    for sourceURL in urls {
      scannedCount += 1

      do {
        let values = try sourceURL.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey, .isHiddenKey])
        guard values.isDirectory != true, values.isHidden != true, !sourceURL.lastPathComponent.hasPrefix(".") else {
          skippedCount += 1
          continue
        }

        let category = FileCategory.category(forPathExtension: sourceURL.pathExtension)
        let targetDirectory = directory.appendingPathComponent(category.rawValue, isDirectory: true)
        try fileManager.createDirectory(at: targetDirectory, withIntermediateDirectories: true)

        let destinationURL = uniqueDestination(for: sourceURL, in: targetDirectory)
        try fileManager.moveItem(at: sourceURL, to: destinationURL)
        movedCount += 1
      } catch {
        errors.append(FileOrganizeError(fileName: sourceURL.lastPathComponent, message: error.localizedDescription))
      }
    }

    return FileOrganizeResult(
      scannedCount: scannedCount,
      movedCount: movedCount,
      skippedCount: skippedCount,
      errors: errors
    )
  }

  private func uniqueDestination(for sourceURL: URL, in directory: URL) -> URL {
    let baseName = sourceURL.deletingPathExtension().lastPathComponent
    let pathExtension = sourceURL.pathExtension
    var candidate = directory.appendingPathComponent(sourceURL.lastPathComponent)
    var suffix = 1

    while fileManager.fileExists(atPath: candidate.path) {
      let fileName: String
      if pathExtension.isEmpty {
        fileName = "\(baseName)-\(suffix)"
      } else {
        fileName = "\(baseName)-\(suffix).\(pathExtension)"
      }
      candidate = directory.appendingPathComponent(fileName)
      suffix += 1
    }

    return candidate
  }
}
