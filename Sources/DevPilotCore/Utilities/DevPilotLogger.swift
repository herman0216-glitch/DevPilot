import Foundation
import os

public enum DevPilotLogger {
  public static let workflow = Logger(subsystem: "com.herman.DevPilot", category: "workflow")
  public static let shell = Logger(subsystem: "com.herman.DevPilot", category: "shell")
  public static let files = Logger(subsystem: "com.herman.DevPilot", category: "files")
}
