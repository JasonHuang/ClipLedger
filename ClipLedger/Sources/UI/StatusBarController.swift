import AppKit
import SwiftUI

@MainActor
final class StatusBarController: NSObject, NSPopoverDelegate {
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private let viewModel: ClipboardViewModel
    private var keyboardMonitor: Any?

    init(
        viewModel: ClipboardViewModel,
        settings: AppSettings,
        onOpenSettings: @escaping () -> Void
    ) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.popover = NSPopover()
        self.viewModel = viewModel
        super.init()

        configureStatusItem()
        configurePopover(settings: settings, onOpenSettings: onOpenSettings)
    }

    func showPopover() {
        guard let button = statusItem.button else { return }

        if !popover.isShown {
            viewModel.reload()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            installKeyboardMonitor()
        }

        NSApp.activate(ignoringOtherApps: true)
    }

    func closePopover() {
        popover.performClose(nil)
        removeKeyboardMonitor()
    }

    func popoverDidClose(_ notification: Notification) {
        removeKeyboardMonitor()
    }

    @objc private func togglePopover(_ sender: Any?) {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }

        if let image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "ClipLedger") {
            image.isTemplate = true
            button.image = image
        } else {
            button.title = "CL"
        }

        button.target = self
        button.action = #selector(togglePopover(_:))
    }

    private func configurePopover(settings: AppSettings, onOpenSettings: @escaping () -> Void) {
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 468, height: 640)
        popover.delegate = self
        popover.contentViewController = NSHostingController(
            rootView: MainView(
                viewModel: viewModel,
                settings: settings,
                onOpenSettings: onOpenSettings
            )
        )
    }

    private func installKeyboardMonitor() {
        guard keyboardMonitor == nil else { return }

        keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.popover.isShown else { return event }

            switch event.keyCode {
            case 126:
                self.viewModel.selectPreviousItem()
                return nil
            case 125:
                self.viewModel.selectNextItem()
                return nil
            case 36:
                self.viewModel.restoreSelectedItem()
                return nil
            case 53:
                self.closePopover()
                return nil
            default:
                return event
            }
        }
    }

    private func removeKeyboardMonitor() {
        if let keyboardMonitor {
            NSEvent.removeMonitor(keyboardMonitor)
            self.keyboardMonitor = nil
        }
    }
}
