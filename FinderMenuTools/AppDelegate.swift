import Cocoa
import FinderSync

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?
    private let statusLabel = NSTextField(labelWithString: "")
    private var handledURLActionOnLaunch = false

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        handledURLActionOnLaunch = true
        for url in urls where url.scheme == "findermenutools" {
            handleActionURL(url)
        }
        // If the settings window isn't visible, terminate cleanly after handling the action
        if window == nil || !(window?.isVisible ?? false) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if self.window == nil || !(self.window?.isVisible ?? false) {
                    NSApp.terminate(nil)
                }
            }
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Wait briefly to see if launched via URL scheme (`findermenutools://...`)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            if !self.handledURLActionOnLaunch {
                self.showStatusWindow()
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            showStatusWindow()
        }
        return true
    }

    private func handleActionURL(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.host == "open" else {
            return
        }

        let queryItems = components.queryItems ?? []
        let appType = queryItems.first(where: { $0.name == "app" })?.value ?? "iterm"
        let paths = queryItems.filter { $0.name == "path" }.compactMap { $0.value }

        guard !paths.isEmpty else { return }

        let targetAppName: String
        switch appType {
        case "terminal":
            targetAppName = "Terminal"
        default:
            targetAppName = FileManager.default.fileExists(atPath: "/Applications/iTerm.app") ? "iTerm" : "Terminal"
        }

        for dirPath in paths {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            process.arguments = ["-a", targetAppName, dirPath]
            try? process.run()
            process.waitUntilExit()
        }
    }

    private func showStatusWindow() {
        NSApp.setActivationPolicy(.regular)
        if let existingWindow = window {
            refreshExtensionStatus()
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 220),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        win.center()
        win.title = "FinderMenuTools"

        let contentView = NSView(frame: win.contentRect(forFrameRect: win.frame))

        let titleLabel = NSTextField(labelWithString: "Finder Context Menu Tools")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 16)
        titleLabel.frame = NSRect(x: 24, y: 165, width: 392, height: 24)

        let descLabel = NSTextField(
            wrappingLabelWithString: "Adds 'Copy Path', 'Open in iTerm2', and 'Open in Terminal' directly to the Finder right-click context menu."
        )
        descLabel.font = NSFont.systemFont(ofSize: 13)
        descLabel.textColor = .secondaryLabelColor
        descLabel.frame = NSRect(x: 24, y: 118, width: 392, height: 40)

        statusLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        statusLabel.frame = NSRect(x: 24, y: 78, width: 392, height: 22)

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
        refreshExtensionStatus()
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
