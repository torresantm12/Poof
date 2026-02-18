import AppKit
import Foundation

@MainActor
final class AppModel: ObservableObject {
  @Published private(set) var configDirectoryPath: String
  @Published private(set) var triggerMode: ExpansionTriggerMode
  @Published private(set) var snippetCount: Int = 0
  @Published private(set) var errors: [String] = []

  var onTriggerModeChange: ((ExpansionTriggerMode) -> Void)?
  var onConfigDirectoryChange: ((URL) -> Void)?
  var onReloadRequest: (() -> Void)?

  init(preferences: Preferences) {
    configDirectoryPath = preferences.configDirectoryURL.path
    triggerMode = preferences.triggerMode
  }

  func updateSnippetCount(_ count: Int) {
    snippetCount = count
  }

  func updateErrors(_ errors: [String]) {
    self.errors = errors
  }

  func setTriggerMode(_ mode: ExpansionTriggerMode) {
    triggerMode = mode
    onTriggerModeChange?(mode)
  }

  func setConfigDirectory(_ url: URL) {
    configDirectoryPath = url.standardizedFileURL.path
    onConfigDirectoryChange?(url.standardizedFileURL)
  }

  func reload() {
    onReloadRequest?()
  }

  func chooseConfigDirectory() {
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    panel.prompt = "Choose"

    guard panel.runModal() == .OK, let url = panel.url else { return }
    setConfigDirectory(url)
  }

  func revealConfigDirectory() {
    let url = URL(fileURLWithPath: configDirectoryPath, isDirectory: true)
    NSWorkspace.shared.activateFileViewerSelecting([url])
  }

  func resetConfigDirectory() {
    setConfigDirectory(Preferences.defaultConfigDirectoryURL())
  }
}
