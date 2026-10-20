import Cocoa
import FinderSync

@objc(FinderSync)
final class FinderSync: FIFinderSync {

    override init() {
        super.init()
        // Watch the entire filesystem root and mounted volumes so the context menu appears everywhere
        let rootURL = URL(fileURLWithPath: "/")
        let volumesURL = URL(fileURLWithPath: "/Volumes")
        FIFinderSyncController.default().directoryURLs = [rootURL, volumesURL]
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        switch menuKind {
        case .contextualMenuForItems, .contextualMenuForContainer, .toolbarItemMenu:
            let menu = NSMenu(title: "")

            let copyPathItem = NSMenuItem(
                title: "Copy Path",
                action: #selector(copyPathAction(_:)),
                keyEquivalent: ""
            )
            copyPathItem.target = self
            if let copyIcon = NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: "Copy Path") {
                copyIcon.isTemplate = true
                copyPathItem.image = copyIcon
            }
            menu.addItem(copyPathItem)

            let openITermItem = NSMenuItem(
                title: "Open in iTerm2",
                action: #selector(openInITermAction(_:)),
                keyEquivalent: ""
            )
            openITermItem.target = self
            if let iTermIcon = NSImage(systemSymbolName: "terminal.fill", accessibilityDescription: "Open in iTerm2") {
                iTermIcon.isTemplate = true
                openITermItem.image = iTermIcon
            }
            menu.addItem(openITermItem)

            let openTerminalItem = NSMenuItem(
                title: "Open in Terminal",
                action: #selector(openInTerminalAction(_:)),
                keyEquivalent: ""
            )
            openTerminalItem.target = self
            if let terminalIcon = NSImage(systemSymbolName: "apple.terminal", accessibilityDescription: "Open in Terminal") {
                terminalIcon.isTemplate = true
                openTerminalItem.image = terminalIcon
            }
            menu.addItem(openTerminalItem)

            return menu
        case .contextualMenuForSidebar:
            return nil
        @unknown default:
            return nil
        }
    }

    /// Resolves the target URLs from the current Finder selection or the active container directory.
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

    /// Resolves a URL to its directory path (returns the path itself if it is a directory, or its parent directory if it is a file).
    private func resolveDirectoryPath(for url: URL) -> String {
        let rawPath = url.path(percentEncoded: false)
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: rawPath, isDirectory: &isDirectory) {
            return isDirectory.boolValue
                ? rawPath
                : url.deletingLastPathComponent().path(percentEncoded: false)
        }
        return url.hasDirectoryPath
            ? rawPath
            : url.deletingLastPathComponent().path(percentEncoded: false)
    }

    /// Collects unique target directory paths in selection order.
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

    /// Delegates opening directories to the unsandboxed Host App via custom URL scheme (`findermenutools://open?...`)
    /// so LaunchServices (`CoreServicesUIAgent`) never blocks the sandboxed FinderSync extension with error -54 (`permErr`).
    private func openDirectoriesViaHostApp(appType: String) {
        let directoryPaths = resolveUniqueDirectoryPaths()
        guard !directoryPaths.isEmpty else { return }

        var components = URLComponents()
        components.scheme = "findermenutools"
        components.host = "open"
        var queryItems = [URLQueryItem(name: "app", value: appType)]
        for path in directoryPaths {
            queryItems.append(URLQueryItem(name: "path", value: path))
        }
        components.queryItems = queryItems

        guard let actionURL = components.url else { return }
        NSWorkspace.shared.open(actionURL)
    }

    @objc private func copyPathAction(_ sender: AnyObject?) {
        let urls = resolveTargetURLs()
        guard !urls.isEmpty else { return }

        let paths = urls
            .map { $0.path(percentEncoded: false) }
            .joined(separator: "\n")

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(paths, forType: .string)
    }

    @objc private func openInITermAction(_ sender: AnyObject?) {
        openDirectoriesViaHostApp(appType: "iterm")
    }

    @objc private func openInTerminalAction(_ sender: AnyObject?) {
        openDirectoriesViaHostApp(appType: "terminal")
    }
}
