# Finder Menu Tools

<p>
  <img src="https://img.shields.io/badge/macOS-14%2B-111111?logo=apple&logoColor=white" alt="Requires macOS 14 or later" />
</p>

A small native Finder extension for copying paths and names, opening locations in Terminal, iTerm2, or Visual Studio Code, creating an empty file, and toggling hidden files.

[English](README.md) · [Tiếng Việt](README.vi.md)

## Features

Finder Menu Tools adds these actions to Finder’s contextual menu:

- **Copy Path** — copies the full POSIX path. Multiple selections are separated by new lines.
- **Copy Name** — copies selected file or folder names, including file extensions. Multiple names are separated by new lines.
- **Open in Terminal** — opens the selected folder, or the containing folder when a file is selected.
- **Open in iTerm2** — shown when iTerm2 is installed at `/Applications/iTerm.app`.
- **Open in VS Code** — shown when Visual Studio Code is installed at `/Applications/Visual Studio Code.app`.
- **New File Here…** — creates an empty file in the current folder or the first selected item’s folder. An existing file is never overwritten.
- **Toggle Hidden Files** — toggles Finder’s hidden-file setting and restarts Finder to apply it.

The menu works on selected items and on the background of a Finder folder. When multiple items in different folders are selected, open actions open each distinct containing folder. New File uses the first resolved folder.

## Requirements

- macOS 14 or later
- Xcode and its macOS command-line build tools
- Terminal is included with macOS. iTerm2 and Visual Studio Code are optional; their menu actions appear only when they are found at the paths above.

## Install

From Terminal:

```bash
git clone https://github.com/xuanchinh97/finder-menu-tools.git
cd finder-menu-tools
./scripts/install.sh
```

The installer builds the Release app, copies it to `/Applications/FinderMenuTools.app`, signs it locally, registers and enables the Finder Sync extension, and restarts Finder. It must be able to write to `/Applications`. Save open Finder work before installing because Finder will restart.

After installation, if the menu does not appear, enable **FinderMenuTools** in **System Settings → General → Login Items & Extensions → Finder Extensions**. The exact labels can vary slightly by macOS version.

## Build from Xcode

Open `FinderMenuTools.xcodeproj`, select the **FinderMenuTools** scheme, choose the **Release** configuration, then build. To install and register the extension, use the script above.

You can also build the host app and its embedded extension from Terminal:

```bash
xcodebuild \
  -project FinderMenuTools.xcodeproj \
  -target FinderMenuTools \
  -configuration Release \
  SYMROOT=build \
  CODE_SIGN_IDENTITY=- \
  CODE_SIGNING_REQUIRED=YES \
  CODE_SIGNING_ALLOWED=YES \
  clean build
```

## Troubleshooting

- **Menu items are missing:** check that FinderMenuTools is enabled under **System Settings → General → Login Items & Extensions → Finder Extensions**, then relaunch Finder.
- **iTerm2 or VS Code is missing from the menu:** the app checks the standard paths listed above. Install or move the app there, then relaunch Finder.
- **Check extension registration:**

  ```bash
  pluginkit -m -v -i com.chinh.FinderMenuTools.FinderSyncExt
  ```

- **Reload Finder manually:**

  ```bash
  killall Finder
  ```

## Uninstall

1. Disable **FinderMenuTools** in **System Settings → General → Login Items & Extensions → Finder Extensions**.
2. Move `/Applications/FinderMenuTools.app` to the Trash.

Alternatively, disable the extension from Terminal before removing the app:

```bash
pluginkit -e ignore -i com.chinh.FinderMenuTools.FinderSyncExt
```

## Project layout

```text
FinderMenuTools/       Host app that handles menu actions
FinderSyncExt/         Finder Sync extension that builds the menu
FinderMenuTools.xcodeproj
scripts/install.sh     Build, install, sign, and enable the extension
docs/                  Architecture and setup notes
```

More detail: [architecture](docs/architecture.md) · [setup notes](docs/usage-and-setup.md) · [development log](docs/tracking-log.md)
