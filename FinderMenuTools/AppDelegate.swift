import Cocoa
import FinderSync

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?
    private let statusLabel = NSTextField(labelWithString: "")
    private var handledURLActionOnLaunch = false

    // Preference Checkboxes
    private var chkCopyPath: NSButton!
    private var chkCopyName: NSButton!
    private var chkOpenTerminal: NSButton!
    private var chkOpenITerm: NSButton!
    private var chkOpenVSCode: NSButton!
    private var chkNewFile: NSButton!
    private var chkToggleHidden: NSButton!

    static let defaultsSuite = "group.com.chinh.FinderMenuTools"
    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: defaultsSuite) ?? .standard
    }

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
        if window == nil || !(window?.isVisible ?? false) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                if self.window == nil || !(self.window?.isVisible ?? false) {
                    NSApp.terminate(nil)
                }
            }
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerDefaultPreferences()
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

    private func registerDefaultPreferences() {
        let defs = AppDelegate.sharedDefaults
        let defaults: [String: Any] = [
            "pref_copy_path": true,
            "pref_copy_name": true,
            "pref_open_terminal": true,
            "pref_open_iterm": true,
            "pref_open_vscode": true,
            "pref_new_file": true,
            "pref_toggle_hidden": true
        ]
        defs.register(defaults: defaults)
    }

    private func handleActionURL(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }

        switch components.host {
        case "open":
            handleOpenApp(components: components)
        case "newfile":
            handleNewFile(components: components)
        case "toggle-hidden":
            handleToggleHiddenFiles()
        default:
            break
        }
    }

    private func handleOpenApp(components: URLComponents) {
        let queryItems = components.queryItems ?? []
        let appType = queryItems.first(where: { $0.name == "app" })?.value ?? "terminal"
        let paths = queryItems.filter { $0.name == "path" }.compactMap { $0.value }

        guard !paths.isEmpty else { return }

        let targetAppName: String
        switch appType {
        case "vscode":
            targetAppName = "Visual Studio Code"
        case "cursor":
            targetAppName = "Cursor"
        case "iterm":
            targetAppName = FileManager.default.fileExists(atPath: "/Applications/iTerm.app") ? "iTerm" : "Terminal"
        default:
            targetAppName = "Terminal"
        }

        for dirPath in paths {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            process.arguments = ["-a", targetAppName, dirPath]
            try? process.run()
            process.waitUntilExit()
        }
    }

    private func handleNewFile(components: URLComponents) {
        let queryItems = components.queryItems ?? []
        guard let dirPath = queryItems.first(where: { $0.name == "dir" })?.value else { return }

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = "Create New File"
        alert.informativeText = "Enter the filename to create in:\n\(dirPath)"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Create")
        alert.addButton(withTitle: "Cancel")

        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        input.stringValue = "untitled.txt"
        alert.accessoryView = input

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            var fileName = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if fileName.isEmpty { fileName = "untitled.txt" }

            let destinationURL = URL(fileURLWithPath: dirPath).appendingPathComponent(fileName)
            if !FileManager.default.fileExists(atPath: destinationURL.path) {
                FileManager.default.createFile(atPath: destinationURL.path, contents: Data(), attributes: nil)
            }
        }

        if window == nil || !(window?.isVisible ?? false) {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    private func handleToggleHiddenFiles() {
        // Run native AppleScript to trigger Finder shortcut Cmd+Shift+. smoothly without quitting Finder
        let script = """
        tell application "Finder" to activate
        tell application "System Events"
            key code 47 using {command down, shift down}
        end tell
        """
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        try? process.run()
        process.waitUntilExit()
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
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 420),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        win.center()
        win.title = "FinderMenuTools Settings"

        let contentView = NSView(frame: win.contentRect(forFrameRect: win.frame))

        let titleLabel = NSTextField(labelWithString: "Finder Context Menu Tools")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 17)
        titleLabel.frame = NSRect(x: 24, y: 370, width: 432, height: 26)

        statusLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        statusLabel.frame = NSRect(x: 24, y: 338, width: 432, height: 22)

        let divider = NSBox(frame: NSRect(x: 24, y: 326, width: 432, height: 1))
        divider.boxType = .separator

        let sectionLabel = NSTextField(labelWithString: "Enabled Context Menu Items:")
        sectionLabel.font = NSFont.boldSystemFont(ofSize: 13)
        sectionLabel.frame = NSRect(x: 24, y: 295, width: 432, height: 20)

        let defs = AppDelegate.sharedDefaults
        chkCopyPath = createCheckbox("Copy Path", key: "pref_copy_path", y: 265, defs: defs)
        chkCopyName = createCheckbox("Copy Name", key: "pref_copy_name", y: 235, defs: defs)
        chkOpenTerminal = createCheckbox("Open in Terminal", key: "pref_open_terminal", y: 205, defs: defs)
        chkOpenITerm = createCheckbox("Open in iTerm2", key: "pref_open_iterm", y: 175, defs: defs)
        chkOpenVSCode = createCheckbox("Open in VS Code", key: "pref_open_vscode", y: 145, defs: defs)
        chkNewFile = createCheckbox("New File Here...", key: "pref_new_file", y: 115, defs: defs)
        chkToggleHidden = createCheckbox("Toggle Hidden Files", key: "pref_toggle_hidden", y: 85, defs: defs)

        let openSettingsButton = NSButton(
            title: "Extension Settings...",
            target: self,
            action: #selector(openExtensionSettings)
        )
        openSettingsButton.bezelStyle = .rounded
        openSettingsButton.frame = NSRect(x: 24, y: 24, width: 160, height: 32)

        let refreshButton = NSButton(
            title: "Refresh Finder",
            target: self,
            action: #selector(reloadFinder)
        )
        refreshButton.bezelStyle = .rounded
        refreshButton.frame = NSRect(x: 326, y: 24, width: 130, height: 32)

        contentView.addSubview(titleLabel)
        contentView.addSubview(statusLabel)
        contentView.addSubview(divider)
        contentView.addSubview(sectionLabel)
        contentView.addSubview(chkCopyPath)
        contentView.addSubview(chkCopyName)
        contentView.addSubview(chkOpenTerminal)
        contentView.addSubview(chkOpenITerm)
        contentView.addSubview(chkOpenVSCode)
        contentView.addSubview(chkNewFile)
        contentView.addSubview(chkToggleHidden)
        contentView.addSubview(openSettingsButton)
        contentView.addSubview(refreshButton)

        win.contentView = contentView
        refreshExtensionStatus()
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = win
    }

    private func createCheckbox(_ title: String, key: String, y: CGFloat, defs: UserDefaults) -> NSButton {
        let btn = NSButton(checkboxWithTitle: title, target: self, action: #selector(checkboxChanged(_:)))
        btn.frame = NSRect(x: 28, y: y, width: 300, height: 22)
        btn.identifier = NSUserInterfaceItemIdentifier(key)
        btn.state = defs.bool(forKey: key) ? .on : .off
        return btn
    }

    @objc private func checkboxChanged(_ sender: NSButton) {
        guard let key = sender.identifier?.rawValue else { return }
        AppDelegate.sharedDefaults.set(sender.state == .on, forKey: key)
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

    @objc private func reloadFinder() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        process.arguments = ["Finder"]
        try? process.run()
    }

    @objc private func openExtensionSettings() {
        FIFinderSyncController.showExtensionManagementInterface()
    }
}
