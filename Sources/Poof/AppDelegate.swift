import AppKit
import Foundation

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
  private let preferences = Preferences()
  private lazy var appModel = AppModel(preferences: preferences)
  private lazy var snippetEngine = SnippetEngine(triggerMode: preferences.triggerMode)
  private lazy var configStore = SnippetConfigStore(preferences: preferences)
  private lazy var statusItemController = StatusItemController()
  private lazy var settingsWindowController = SettingsWindowController(model: appModel)
  private lazy var updaterController = UpdaterController()

  func applicationDidFinishLaunching(_ notification: Notification) {
    setupMainMenu()
    NSApp.setActivationPolicy(.accessory)
    configureCallbacks()

    configStore.ensureBootstrapFilesExist()
    configStore.reload()
    configStore.startWatching()

    snippetEngine.start()
    statusItemController.updateConfigDirectory(path: configStore.configDirectoryURL.path)
  }

  func applicationWillTerminate(_ notification: Notification) {
    snippetEngine.stop()
    configStore.stopWatching()
  }

  private func configureCallbacks() {
    statusItemController.onOpenSettings = { [weak self] in
      self?.showSettingsWindow()
    }
    statusItemController.onCheckForUpdates = { [weak self] in
      self?.updaterController.checkForUpdates()
    }
    statusItemController.onReloadSnippets = { [weak self] in
      self?.configStore.reload()
    }
    statusItemController.onRevealConfigDirectory = { [weak self] in
      guard let self else { return }
      NSWorkspace.shared.activateFileViewerSelecting([self.configStore.configDirectoryURL])
    }
    statusItemController.onShowAbout = {
      NSApp.orderFrontStandardAboutPanel(nil)
      NSApp.activate(ignoringOtherApps: true)
    }

    appModel.onTriggerModeChange = { [weak self] mode in
      guard let self else { return }
      self.preferences.triggerMode = mode
      self.snippetEngine.updateTriggerMode(mode)
    }
    appModel.onConfigDirectoryChange = { [weak self] directoryURL in
      guard let self else { return }
      self.configStore.updateConfigDirectory(directoryURL)
      self.statusItemController.updateConfigDirectory(path: directoryURL.path)
    }
    appModel.onReloadRequest = { [weak self] in
      self?.configStore.reload()
    }

    configStore.onUpdate = { [weak self] snippets, errors in
      guard let self else { return }
      self.snippetEngine.updateSnippets(snippets)
      self.statusItemController.updateSnippetCount(snippets.count)
      self.appModel.updateSnippetCount(snippets.count)
      self.appModel.updateErrors(errors)
    }
  }

  private func showSettingsWindow() {
    NSApp.setActivationPolicy(.regular)
    settingsWindowController.window?.delegate = self
    settingsWindowController.show()
  }

  func windowWillClose(_ notification: Notification) {
    guard let window = notification.object as? NSWindow else { return }
    if window == settingsWindowController.window {
      NSApp.setActivationPolicy(.accessory)
    }
  }

  private func setupMainMenu() {
    let mainMenu = NSMenu()

    let appMenuItem = NSMenuItem()
    mainMenu.addItem(appMenuItem)

    let appMenu = NSMenu()
    appMenuItem.submenu = appMenu

    let appName = ProcessInfo.processInfo.processName

    appMenu.addItem(
      withTitle: "About \(appName)",
      action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
      keyEquivalent: ""
    )
    appMenu.addItem(.separator())

    let settingsItem = NSMenuItem(
      title: "Settings…",
      action: #selector(openSettingsFromMainMenu),
      keyEquivalent: ","
    )
    settingsItem.target = self
    let checkForUpdatesItem = NSMenuItem(
      title: "Check for Updates…",
      action: #selector(checkForUpdatesFromMainMenu),
      keyEquivalent: ""
    )
    checkForUpdatesItem.target = self
    appMenu.addItem(checkForUpdatesItem)
    appMenu.addItem(settingsItem)
    appMenu.addItem(.separator())

    appMenu.addItem(
      withTitle: "Hide \(appName)",
      action: #selector(NSApplication.hide(_:)),
      keyEquivalent: "h"
    )

    let hideOthers = NSMenuItem(
      title: "Hide Others",
      action: #selector(NSApplication.hideOtherApplications(_:)),
      keyEquivalent: "h"
    )
    hideOthers.keyEquivalentModifierMask = [.command, .option]
    appMenu.addItem(hideOthers)

    appMenu.addItem(
      withTitle: "Show All",
      action: #selector(NSApplication.unhideAllApplications(_:)),
      keyEquivalent: ""
    )

    appMenu.addItem(.separator())
    appMenu.addItem(
      withTitle: "Quit \(appName)",
      action: #selector(NSApplication.terminate(_:)),
      keyEquivalent: "q"
    )

    let windowMenuItem = NSMenuItem()
    mainMenu.addItem(windowMenuItem)

    let windowMenu = NSMenu(title: "Window")
    windowMenuItem.submenu = windowMenu

    windowMenu.addItem(
      withTitle: "Minimize",
      action: #selector(NSWindow.performMiniaturize(_:)),
      keyEquivalent: "m"
    )
    windowMenu.addItem(
      withTitle: "Close Window",
      action: #selector(NSWindow.performClose(_:)),
      keyEquivalent: "w"
    )
    windowMenu.addItem(
      withTitle: "Zoom",
      action: #selector(NSWindow.performZoom(_:)),
      keyEquivalent: ""
    )
    windowMenu.addItem(.separator())
    windowMenu.addItem(
      withTitle: "Bring All to Front",
      action: #selector(NSApplication.arrangeInFront(_:)),
      keyEquivalent: ""
    )

    NSApp.mainMenu = mainMenu
    NSApp.windowsMenu = windowMenu
  }

  @objc private func openSettingsFromMainMenu() {
    showSettingsWindow()
  }

  @objc private func checkForUpdatesFromMainMenu() {
    updaterController.checkForUpdates()
  }
}
