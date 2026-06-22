import AppKit
import SwiftData

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var modelContainer: ModelContainer?
    private var settings: AppSettings?
    private var viewModel: ClipboardViewModel?
    private var clipboardMonitor: ClipboardMonitor?
    private var statusBarController: StatusBarController?
    private var settingsWindowController: SettingsWindowController?
    private var globalShortcutManager: GlobalShortcutManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else {
            return
        }

        NSApp.setActivationPolicy(.accessory)

        do {
            let container = try ModelContainer(for: ClipboardItem.self)
            let appSettings = AppSettings()
            let mainViewModel = ClipboardViewModel(modelContext: container.mainContext, settings: appSettings)
            let monitor = ClipboardMonitor { [weak mainViewModel] content in
                mainViewModel?.recordClipboardContent(content)
            }
            mainViewModel.onSystemClipboardWritten = { [weak monitor] in
                monitor?.synchronizeChangeCount()
            }

            let settingsWindow = SettingsWindowController(settings: appSettings, viewModel: mainViewModel)
            let statusBar = StatusBarController(
                viewModel: mainViewModel,
                settings: appSettings,
                onOpenSettings: { [weak settingsWindow] in
                    settingsWindow?.show()
                }
            )
            let shortcutManager = GlobalShortcutManager {
                statusBar.showPopover()
            }

            self.modelContainer = container
            self.settings = appSettings
            self.viewModel = mainViewModel
            self.clipboardMonitor = monitor
            self.settingsWindowController = settingsWindow
            self.statusBarController = statusBar
            self.globalShortcutManager = shortcutManager

            mainViewModel.reload()
            monitor.start()
            switch shortcutManager.register() {
            case .success:
                mainViewModel.shortcutWarningMessage = nil
            case .failure(let error):
                mainViewModel.shortcutWarningMessage = error.localizedDescription
            }
            appSettings.applyLaunchAtLoginPreference()
        } catch {
            presentStartupError(error)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardMonitor?.stop()
        globalShortcutManager?.unregister()
    }

    private func presentStartupError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "ClipLedger could not start"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .critical
        alert.runModal()
        NSApp.terminate(nil)
    }
}
