import Cocoa
import FinderSync

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?
    private let statusLabel = NSTextField(labelWithString: "")

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupWindow()
        refreshExtensionStatus()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        refreshExtensionStatus()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    private func setupWindow() {
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 210),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        win.center()
        win.title = "FinderMenuTools"

        let contentView = NSView(frame: win.contentRect(forFrameRect: win.frame))

        let titleLabel = NSTextField(labelWithString: "Finder Context Menu Tools")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 16)
        titleLabel.frame = NSRect(x: 24, y: 155, width: 372, height: 24)

        let descLabel = NSTextField(wrappingLabelWithString: "Adds 'Copy Path' and 'Open in iTerm2' directly to the Finder right-click context menu.")
        descLabel.font = NSFont.systemFont(ofSize: 13)
        descLabel.textColor = .secondaryLabelColor
        descLabel.frame = NSRect(x: 24, y: 110, width: 372, height: 38)

        statusLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        statusLabel.frame = NSRect(x: 24, y: 72, width: 372, height: 22)

        let openSettingsButton = NSButton(
            title: "Open System Extension Settings",
            target: self,
            action: #selector(openExtensionSettings)
        )
        openSettingsButton.bezelStyle = .rounded
        openSettingsButton.frame = NSRect(x: 24, y: 24, width: 230, height: 32)

        let refreshButton = NSButton(
            title: "Refresh Status",
            target: self,
            action: #selector(refreshExtensionStatus)
        )
        refreshButton.bezelStyle = .rounded
        refreshButton.frame = NSRect(x: 264, y: 24, width: 132, height: 32)

        contentView.addSubview(titleLabel)
        contentView.addSubview(descLabel)
        contentView.addSubview(statusLabel)
        contentView.addSubview(openSettingsButton)
        contentView.addSubview(refreshButton)

        win.contentView = contentView
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = win
    }

    @objc private func refreshExtensionStatus() {
        let enabled = FIFinderSyncController.isExtensionEnabled
        if enabled {
            statusLabel.stringValue = "Status: Active (Extension is enabled in Finder)"
            statusLabel.textColor = .systemGreen
        } else {
            statusLabel.stringValue = "Status: Inactive (Enable in System Settings > Extensions)"
            statusLabel.textColor = .systemOrange
        }
    }

    @objc private func openExtensionSettings() {
        FIFinderSyncController.showExtensionManagementInterface()
    }
}
