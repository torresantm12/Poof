import Foundation

enum ExpansionTriggerMode: String, CaseIterable, Identifiable {
  case delimiter
  case immediate

  var id: Self { self }

  var title: String {
    switch self {
    case .delimiter:
      return "After delimiter (space, return, tab)"
    case .immediate:
      return "Immediate when trigger is fully typed"
    }
  }
}

final class Preferences {
  private enum Keys {
    static let configDirectoryPath = "Poof.configDirectoryPath"
    static let triggerMode = "Poof.triggerMode"
  }

  private let userDefaults: UserDefaults

  init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
  }

  var configDirectoryURL: URL {
    get {
      if let path = userDefaults.string(forKey: Keys.configDirectoryPath), !path.isEmpty {
        return URL(fileURLWithPath: path, isDirectory: true).standardizedFileURL
      }
      return Self.defaultConfigDirectoryURL()
    }
    set {
      userDefaults.set(newValue.standardizedFileURL.path, forKey: Keys.configDirectoryPath)
    }
  }

  var triggerMode: ExpansionTriggerMode {
    get {
      guard
        let rawValue = userDefaults.string(forKey: Keys.triggerMode),
        let mode = ExpansionTriggerMode(rawValue: rawValue)
      else {
        return .delimiter
      }
      return mode
    }
    set {
      userDefaults.set(newValue.rawValue, forKey: Keys.triggerMode)
    }
  }

  static func defaultConfigDirectoryURL(fileManager: FileManager = .default) -> URL {
    let libraryURL = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first
      ?? fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library", isDirectory: true)
    return libraryURL
      .appendingPathComponent("Application Support", isDirectory: true)
      .appendingPathComponent("Poof", isDirectory: true)
  }
}
