import Foundation

public enum CommandRiskLevel: String, Codable, CaseIterable, Identifiable {
  case safe
  case needsConfirmation
  case blocked

  public var id: String { rawValue }

  public var displayName: String {
    switch self {
    case .safe: "安全"
    case .needsConfirmation: "需要确认"
    case .blocked: "已阻止"
    }
  }
}

public final class CommandSafetyValidator {
  public init() {}

  public func evaluate(_ command: String) -> CommandRiskLevel {
    let normalized = normalize(command)
    guard !normalized.isEmpty else {
      return .blocked
    }

    if blockedPatterns.contains(where: { normalized.contains($0) }) {
      return .blocked
    }

    if normalized.contains("sudo") || confirmationPatterns.contains(where: { normalized.contains($0) }) {
      return .needsConfirmation
    }

    return .safe
  }

  public func reason(for command: String) -> String? {
    switch evaluate(command) {
    case .safe:
      return nil
    case .needsConfirmation:
      return "Command can change your system or project and should be confirmed before running."
    case .blocked:
      return "Command is blocked by DevPilot safety rules."
    }
  }

  private var blockedPatterns: [String] {
    [
      "rm -rf /",
      "sudo rm",
      "diskutil erase",
      "mkfs",
      "chmod -r 777 /",
      "chown -r /",
      "dd if=",
      ":(){ :|:& };:",
      "killall finder",
      "launchctl unload"
    ]
  }

  private var confirmationPatterns: [String] {
    [
      "brew install",
      "brew upgrade",
      "npm install",
      "pnpm install",
      "yarn install",
      "bun install",
      "pip install",
      "pip3 install",
      "gem install",
      "cargo install"
    ]
  }

  private func normalize(_ command: String) -> String {
    command
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .lowercased()
      .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
  }
}
