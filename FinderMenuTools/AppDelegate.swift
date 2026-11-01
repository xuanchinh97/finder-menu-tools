import Cocoa
import FinderSync

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static var sharedDelegate: AppDelegate?

    private var window: NSWindow?
    private let statusLabel = NSTextField(labelWithString: "")

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
        sharedDelegate = delegate // Retain strongly to prevent memory deallocation / SIGSEGV
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls where url.scheme?.lowercased() == "findermenutools" {
            handleActionURL(url)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerDefaultPreferences()

        let args = CommandLine.arguments
        if args.contains("--toggle-hidden") || (args.firstIndex(of: "--action").map { $0 + 1 < args.count && args[$0 + 1] == "toggle-hidden" } ?? false) {
            handleToggleHiddenFiles()
            return
        }

        if let urlIndex = args.firstIndex(of: "--url"), urlIndex + 1 < args.count,
           let url = URL(string: args[urlIndex + 1]), url.scheme?.lowercased() == "findermenutools" {
            handleActionURL(url)
            return
        }

        // Only show settings window if user launched FinderMenuTools manually without action arguments
        if args.count <= 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.showStatusWindow()
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // If user manually clicks app icon in Applications / Dock, show settings window
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
        let action = components.host ?? url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        switch action {
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
        NSLog("[FinderMenuTools] handleToggleHiddenFiles start")

        // 1. Read current Finder preference
        let readProcess = Process()
        readProcess.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        readProcess.arguments = ["read", "com.apple.finder", "AppleShowAllFiles"]
        let pipe = Pipe()
        readProcess.standardOutput = pipe
        readProcess.standardError = Pipe()
        try? readProcess.run()
        readProcess.waitUntilExit()

        let currentStr = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? "0"
        let isCurrentlyShown = (currentStr == "true" || currentStr == "yes" || currentStr == "1")
        let newValueStr = isCurrentlyShown ? "false" : "true"

        // 2. Write new state using defaults command
        let writeProcess = Process()
        writeProcess.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        writeProcess.arguments = ["write", "com.apple.finder", "AppleShowAllFiles", "-bool", newValueStr]
        try? writeProcess.run()
        writeProcess.waitUntilExit()

        // 3. Restart Finder to apply changes cleanly and immediately
        let killFinder = Process()
        killFinder.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        killFinder.arguments = ["Finder"]
        try? killFinder.run()
        killFinder.waitUntilExit()

        NSLog("[FinderMenuTools] handleToggleHiddenFiles finished: toggled to %@", newValueStr)
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

        let settingsBtn = NSButton(title: "Open Extension Settings...", target: self, action: #selector(openSystemExtensionSettings(_:)))
        settingsBtn.bezelStyle = .rounded
        settingsBtn.frame = NSRect(x: 20, y: 24, width: 220, height: 32)

        let quitBtn = NSButton(title: "Quit", target: self, action: #selector(quitApp(_:)))
        quitBtn.bezelStyle = .rounded
        quitBtn.frame = NSRect(x: 370, y: 24, width: 85, height: 32)

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
        contentView.addSubview(settingsBtn)
        contentView.addSubview(quitBtn)

        win.contentView = contentView
        self.window = win

        refreshExtensionStatus()
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func createCheckbox(_ title: String, key: String, y: CGFloat, defs: UserDefaults) -> NSButton {
        let btn = NSButton(checkboxWithTitle: title, target: self, action: #selector(checkboxToggled(_:)))
        btn.frame = NSRect(x: 24, y: y, width: 280, height: 22)
        btn.identifier = NSUserInterfaceItemIdentifier(key)
        btn.state = (defs.object(forKey: key) == nil || defs.bool(forKey: key)) ? .on : .off
        return btn
    }

    @objc private func checkboxToggled(_ sender: NSButton) {
        guard let key = sender.identifier?.rawValue else { return }
        let isEnabled = (sender.state == .on)
        AppDelegate.sharedDefaults.set(isEnabled, forKey: key)
    }

    private func refreshExtensionStatus() {
        let isEnabled = FIFinderSyncController.isExtensionEnabled
        if isEnabled {
            statusLabel.stringValue = "Status: Finder Extension is ENABLED"
            statusLabel.textColor = .systemGreen
        } else {
            statusLabel.stringValue = "Status: Finder Extension is DISABLED (enable in System Settings)"
            statusLabel.textColor = .systemOrange
        }
    }

    @objc private func openSystemExtensionSettings(_ sender: AnyObject?) {
        FIFinderSyncController.showExtensionManagementInterface()
    }

    @objc private func quitApp(_ sender: AnyObject?) {
        NSApp.terminate(nil)
    }
}
