import Cocoa
import FinderSync

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static var sharedDelegate: AppDelegate?

    static let defaultsSuite = "group.com.chinh.FinderMenuTools"
    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: defaultsSuite) ?? .standard
    }

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        sharedDelegate = delegate // Retain strongly to prevent memory deallocation
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
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Never show any popup window
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

        NSApp.setActivationPolicy(.accessory)
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

        // 3. Restart Finder to apply changes immediately and reliably
        let killFinder = Process()
        killFinder.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        killFinder.arguments = ["Finder"]
        try? killFinder.run()
        killFinder.waitUntilExit()

        NSLog("[FinderMenuTools] handleToggleHiddenFiles finished: toggled to %@", newValueStr)
    }
}
