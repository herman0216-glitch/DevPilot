import Foundation

public struct FileOrganizeResult: Equatable {
  public let scannedCount: Int
  public let movedCount: Int
  public let skippedCount: Int
  public let errors: [FileOrganizeError]

  public init(scannedCount: Int, movedCount: Int, skippedCount: Int, errors: [FileOrganizeError]) {
    self.scannedCount = scannedCount
    self.movedCount = movedCount
    self.skippedCount = skippedCount
    self.errors = errors
  }
}

public struct FileOrganizeError: Identifiable, Equatable {
  public let id: UUID
  public let fileName: String
  public let message: String

  public init(id: UUID = UUID(), fileName: String, message: String) {
    self.id = id
    self.fileName = fileName
    self.message = message
  }
}

public enum FileCategory: String, CaseIterable {
  case installers = "Installers"
  case archives = "Archives"
  case documents = "Documents"
  case images = "Images"
  case models3D = "3D Models"
  case code = "Code"
  case data = "Data"
  case others = "Others"

  public static func category(forPathExtension pathExtension: String) -> FileCategory {
    switch pathExtension.lowercased() {
    case "dmg", "pkg":
      return .installers
    case "zip", "rar", "7z":
      return .archives
    case "pdf", "docx", "pptx":
      return .documents
    case "png", "jpg", "jpeg", "webp":
      return .images
    case "stl", "obj", "blend":
      return .models3D
    case "js", "ts", "tsx", "vue", "py", "java":
      return .code
    case "csv", "xlsx":
      return .data
    default:
      return .others
    }
  }
}
