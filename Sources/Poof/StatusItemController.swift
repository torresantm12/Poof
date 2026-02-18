import AppKit

@MainActor
final class StatusItemController: NSObject {
  private let statusItem: NSStatusItem
  private let snippetCountItem = NSMenuItem(title: "Snippets: 0", action: nil, keyEquivalent: "")
  private let configLocationItem = NSMenuItem(title: "Config: -", action: nil, keyEquivalent: "")

  var onOpenSettings: (() -> Void)?
  var onReloadSnippets: (() -> Void)?
  var onRevealConfigDirectory: (() -> Void)?
  var onShowAbout: (() -> Void)?

  override init() {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    super.init()
    setup()
  }

  func updateSnippetCount(_ count: Int) {
    snippetCountItem.title = "Snippets: \(count)"
  }

  func updateConfigDirectory(path: String) {
    configLocationItem.title = "Config: \(path)"
  }

  private func setup() {
    if let button = statusItem.button {
      if let image = Bundle.module.image(forResource: NSImage.Name("StatusItem")) {
        image.isTemplate = true
        button.image = image
      } else {
        let image = NSImage(systemSymbolName: "text.badge.plus", accessibilityDescription: "Poof")
        image?.isTemplate = true
        button.image = image
      }
    }

    snippetCountItem.isEnabled = false
    configLocationItem.isEnabled = false
    configLocationItem.toolTip = "Config directory"

    let menu = NSMenu()
    menu.addItem(snippetCountItem)
    menu.addItem(configLocationItem)
    menu.addItem(.separator())

    menu.addItem(makeMenuItem(title: "About Poof", action: #selector(showAbout), keyEquivalent: ""))
    menu.addItem(makeMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ","))
    menu.addItem(.separator())
    menu.addItem(makeMenuItem(title: "Reload snippets", action: #selector(reloadSnippets), keyEquivalent: "r"))
    menu.addItem(
      makeMenuItem(title: "Show config in Finder", action: #selector(revealConfigDirectory), keyEquivalent: ""))
    menu.addItem(.separator())
    menu.addItem(
      NSMenuItem(
        title: "Quit Poof",
        action: #selector(NSApplication.terminate(_:)),
        keyEquivalent: "q"
      ))

    statusItem.menu = menu
  }

  private func makeMenuItem(title: String, action: Selector, keyEquivalent: String) -> NSMenuItem {
    let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
    item.target = self
    return item
  }

  @objc private func openSettings() {
    onOpenSettings?()
  }

  @objc private func reloadSnippets() {
    onReloadSnippets?()
  }

  @objc private func revealConfigDirectory() {
    onRevealConfigDirectory?()
  }

  @objc private func showAbout() {
    onShowAbout?()
  }
}
