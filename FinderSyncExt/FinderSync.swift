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
            if let terminalIcon = NSImage(systemSymbolName: "terminal", accessibilityDescription: "Open in iTerm2") {
                terminalIcon.isTemplate = true
                openITermItem.image = terminalIcon
            }
            menu.addItem(openITermItem)

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

    /// Resolves a URL to its directory URL (returns the URL itself if it is a directory, or its parent directory if it is a file).
    private func resolveDirectoryURL(for url: URL) -> URL {
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path(percentEncoded: false), isDirectory: &isDirectory) {
            return isDirectory.boolValue ? url : url.deletingLastPathComponent()
        }
        return url.hasDirectoryPath ? url : url.deletingLastPathComponent()
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
        let urls = resolveTargetURLs()
        guard !urls.isEmpty else { return }

        // Deduplicate target directories while preserving selection order
        var seenPaths = Set<String>()
        var directoryURLs: [URL] = []
        for url in urls {
            let dirURL = resolveDirectoryURL(for: url)
            let dirPath = dirURL.path(percentEncoded: false)
            if !seenPaths.contains(dirPath) {
                seenPaths.insert(dirPath)
                directoryURLs.append(dirURL)
            }
        }

        guard !directoryURLs.isEmpty else { return }

        let workspace = NSWorkspace.shared
        let iTermBundleID = "com.googlecode.iterm2"
        let terminalBundleID = "com.apple.Terminal"

        let appURL = workspace.urlForApplication(withBundleIdentifier: iTermBundleID)
            ?? (FileManager.default.fileExists(atPath: "/Applications/iTerm.app") ? URL(fileURLWithPath: "/Applications/iTerm.app") : nil)
            ?? workspace.urlForApplication(withBundleIdentifier: terminalBundleID)

        guard let targetAppURL = appURL else { return }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        workspace.open(directoryURLs, withApplicationAt: targetAppURL, configuration: configuration, completionHandler: nil)
    }
}
