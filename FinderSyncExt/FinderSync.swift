import Cocoa
import FinderSync

@objc(FinderSync)
final class FinderSync: FIFinderSync {

    private static let defaultsSuite = "group.com.chinh.FinderMenuTools"
    private var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: FinderSync.defaultsSuite) ?? .standard
    }

    override init() {
        super.init()
        let rootURL = URL(fileURLWithPath: "/")
        let volumesURL = URL(fileURLWithPath: "/Volumes")
        FIFinderSyncController.default().directoryURLs = [rootURL, volumesURL]
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        switch menuKind {
        case .contextualMenuForItems, .contextualMenuForContainer, .toolbarItemMenu:
            let defs = sharedDefaults
            let menu = NSMenu(title: "")

            // 1. Copy Path / Copy Name
            if defs.object(forKey: "pref_copy_path") == nil || defs.bool(forKey: "pref_copy_path") {
                let copyPathItem = NSMenuItem(title: "Copy Path", action: #selector(copyPathAction(_:)), keyEquivalent: "")
                copyPathItem.target = self
                if let icon = NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: nil) {
                    icon.isTemplate = true
                    copyPathItem.image = icon
                }
                menu.addItem(copyPathItem)
            }

            if defs.object(forKey: "pref_copy_name") == nil || defs.bool(forKey: "pref_copy_name") {
                let copyNameItem = NSMenuItem(title: "Copy Name", action: #selector(copyNameAction(_:)), keyEquivalent: "")
                copyNameItem.target = self
                if let icon = NSImage(systemSymbolName: "text.quote", accessibilityDescription: nil) {
                    icon.isTemplate = true
                    copyNameItem.image = icon
                }
                menu.addItem(copyNameItem)
            }

            if menu.items.count > 0 {
                menu.addItem(NSMenuItem.separator())
            }

            // 2. Open in Terminals / Editors
            var addedAppItem = false

            if defs.object(forKey: "pref_open_terminal") == nil || defs.bool(forKey: "pref_open_terminal") {
                let terminalItem = NSMenuItem(title: "Open in Terminal", action: #selector(openTerminalAction(_:)), keyEquivalent: "")
                terminalItem.target = self
                if let icon = NSImage(systemSymbolName: "apple.terminal", accessibilityDescription: nil) {
                    icon.isTemplate = true
                    terminalItem.image = icon
                }
                menu.addItem(terminalItem)
                addedAppItem = true
            }

            let hasITerm = FileManager.default.fileExists(atPath: "/Applications/iTerm.app")
            if hasITerm && (defs.object(forKey: "pref_open_iterm") == nil || defs.bool(forKey: "pref_open_iterm")) {
                let iTermItem = NSMenuItem(title: "Open in iTerm2", action: #selector(openITermAction(_:)), keyEquivalent: "")
                iTermItem.target = self
                if let icon = NSImage(systemSymbolName: "terminal.fill", accessibilityDescription: nil) {
                    icon.isTemplate = true
                    iTermItem.image = icon
                }
                menu.addItem(iTermItem)
                addedAppItem = true
            }

            let hasVSCode = FileManager.default.fileExists(atPath: "/Applications/Visual Studio Code.app")
            if hasVSCode && (defs.object(forKey: "pref_open_vscode") == nil || defs.bool(forKey: "pref_open_vscode")) {
                let vsCodeItem = NSMenuItem(title: "Open in VS Code", action: #selector(openVSCodeAction(_:)), keyEquivalent: "")
                vsCodeItem.target = self
                if let icon = NSImage(systemSymbolName: "curlybraces", accessibilityDescription: nil) {
                    icon.isTemplate = true
                    vsCodeItem.image = icon
                }
                menu.addItem(vsCodeItem)
                addedAppItem = true
            }

            if addedAppItem {
                menu.addItem(NSMenuItem.separator())
            }

            // 3. New File Here...
            if defs.object(forKey: "pref_new_file") == nil || defs.bool(forKey: "pref_new_file") {
                let newFileItem = NSMenuItem(title: "New File Here...", action: #selector(newFileAction(_:)), keyEquivalent: "")
                newFileItem.target = self
                if let icon = NSImage(systemSymbolName: "plus.rectangle.on.folder", accessibilityDescription: nil) {
                    icon.isTemplate = true
                    newFileItem.image = icon
                }
                menu.addItem(newFileItem)
            }

            // 4. Toggle Hidden Files
            if defs.object(forKey: "pref_toggle_hidden") == nil || defs.bool(forKey: "pref_toggle_hidden") {
                let toggleHiddenItem = NSMenuItem(title: "Toggle Hidden Files", action: #selector(toggleHiddenFilesAction(_:)), keyEquivalent: "")
                toggleHiddenItem.target = self
                if let icon = NSImage(systemSymbolName: "eye.slash", accessibilityDescription: nil) {
                    icon.isTemplate = true
                    toggleHiddenItem.image = icon
                }
                menu.addItem(toggleHiddenItem)
            }

            return menu
        case .contextualMenuForSidebar:
            return nil
        @unknown default:
            return nil
        }
    }

    private func resolveTargetURLs() -> [URL] {
        let controller = FIFinderSyncController.default()
        if let selectedURLs = controller.selectedItemURLs(), !selectedURLs.isEmpty {
            return selectedURLs
        }
        if let targetedURL = controller.targetedURL() {
            return [targetedURL]
        }
        return []
    }

    private func resolveDirectoryPath(for url: URL) -> String {
        let rawPath = url.path(percentEncoded: false)
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: rawPath, isDirectory: &isDirectory) {
            return isDirectory.boolValue ? rawPath : url.deletingLastPathComponent().path(percentEncoded: false)
        }
        return url.hasDirectoryPath ? rawPath : url.deletingLastPathComponent().path(percentEncoded: false)
    }

    private func resolveUniqueDirectoryPaths() -> [String] {
        let urls = resolveTargetURLs()
        guard !urls.isEmpty else { return [] }

        var seenPaths = Set<String>()
        var directoryPaths: [String] = []
        for url in urls {
            let dirPath = resolveDirectoryPath(for: url)
            if !seenPaths.contains(dirPath) {
                seenPaths.insert(dirPath)
                directoryPaths.append(dirPath)
            }
        }
        return directoryPaths
    }

    private func dispatchToHostApp(action: String, queryItems: [URLQueryItem] = []) {
        var components = URLComponents()
        components.scheme = "findermenutools"
        components.host = action
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let actionURL = components.url else { return }

        // 1. Locate host app bundle URL directly
        let extBundle = Bundle(for: type(of: self))
        let hostAppURL = extBundle.bundleURL
            .deletingLastPathComponent() // PlugIns
            .deletingLastPathComponent() // Contents
            .deletingLastPathComponent() // FinderMenuTools.app

        let config = NSWorkspace.OpenConfiguration()
        config.arguments = ["--action", action, "--url", actionURL.absoluteString]
        config.promptsUserIfNeeded = false
        config.activates = false

        NSLog("[FinderSyncExt] Dispatching action: %@ to hostAppURL: %@", action, hostAppURL.path)
        NSWorkspace.shared.openApplication(at: hostAppURL, configuration: config) { _, error in
            if let error = error {
                NSLog("[FinderSyncExt] openApplication failed (%@), trying fallback URL scheme: %@", error.localizedDescription, actionURL.absoluteString)
                NSWorkspace.shared.open(actionURL)
            }
        }
    }

    private func openDirectoriesViaHostApp(appType: String) {
        let directoryPaths = resolveUniqueDirectoryPaths()
        guard !directoryPaths.isEmpty else { return }

        var queryItems = [URLQueryItem(name: "app", value: appType)]
        for path in directoryPaths {
            queryItems.append(URLQueryItem(name: "path", value: path))
        }
        dispatchToHostApp(action: "open", queryItems: queryItems)
    }

    @objc func copyPathAction(_ sender: AnyObject?) {
        let urls = resolveTargetURLs()
        guard !urls.isEmpty else { return }
        let paths = urls.map { $0.path(percentEncoded: false) }.joined(separator: "\n")
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(paths, forType: .string)
    }

    @objc func copyNameAction(_ sender: AnyObject?) {
        let urls = resolveTargetURLs()
        guard !urls.isEmpty else { return }
        let names = urls.map { $0.lastPathComponent }.joined(separator: "\n")
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(names, forType: .string)
    }

    @objc func openTerminalAction(_ sender: AnyObject?) {
        openDirectoriesViaHostApp(appType: "terminal")
    }

    @objc func openITermAction(_ sender: AnyObject?) {
        openDirectoriesViaHostApp(appType: "iterm")
    }

    @objc func openVSCodeAction(_ sender: AnyObject?) {
        openDirectoriesViaHostApp(appType: "vscode")
    }

    @objc func newFileAction(_ sender: AnyObject?) {
        let directoryPaths = resolveUniqueDirectoryPaths()
        guard let firstDir = directoryPaths.first else { return }

        let queryItems = [URLQueryItem(name: "dir", value: firstDir)]
        dispatchToHostApp(action: "newfile", queryItems: queryItems)
    }

    @objc func toggleHiddenFilesAction(_ sender: AnyObject?) {
        NSLog("[FinderSyncExt] toggleHiddenFilesAction clicked by user")
        dispatchToHostApp(action: "toggle-hidden")
    }
}
