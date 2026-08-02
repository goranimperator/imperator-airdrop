# Imperator AirDrop

A macOS menu bar app that turns AirDrop into a drop target. Drag a file onto the
menu bar icon and it goes straight to the AirDrop share sheet.

## Install

Download the latest zip from [Releases](https://github.com/goranimperator/imperator-airdrop/releases),
unzip, and move `Imperator AirDrop.app` to `/Applications`.

The app is ad-hoc signed, so Gatekeeper blocks the first launch. Right-click the
app and choose **Open**, or clear the quarantine flag:

```bash
xattr -dr com.apple.quarantine "/Applications/Imperator AirDrop.app"
```

Requires macOS 13 or later.

## Use

Everything happens on the AirDrop icon in the menu bar.

**Single click** opens the dropdown -- Open AirDrop, Open at Login, About, and
Quit. It waits half a second before appearing, because the app has to know you
are not on your way to a double click. That pause is deliberate, not a hang.

**Double click** skips the menu and opens the AirDrop window in Finder.

**Drag files onto the icon** to send them. Hold the drag still over the icon and
after one second AirDrop fires on its own -- a red badge follows the cursor while
that timer runs. Drop the files instead of waiting and the share sheet opens
immediately.

**Right click** opens the same dropdown as a single click, with no delay.

## Build from source

```bash
make install
```

Cleans, builds, codesigns, installs to `/Applications`, and launches. Other targets:

```bash
make run
```

```bash
make clean
```

## Release

Build a zip without touching git or the remote:

```bash
make dist VERSION=1.0.0
```

Cut a full release -- bumps `Info.plist`, commits, tags `v1.0.0`, pushes, and
publishes a GitLab release with the zip attached:

```bash
make release VERSION=1.0.0
```

Requires the [GitHub CLI](https://cli.github.com) (`brew install gh`, then
`gh auth login`). The working tree must be clean. Tags are plain semver
(`v1.0.0`); the release title carries the app name.

## Layout

| Path | Role |
|------|------|
| `Sources/ImperatorAirdropApp.swift` | SwiftUI entry point |
| `Sources/AppDelegate.swift` | Status bar, popover, About panel |
| `Sources/DragStatusView.swift` | Drag-and-drop and click handling |
| `Resources/` | Icons and `Info.plist` |

Hybrid SwiftUI + AppKit: SwiftUI owns the app lifecycle and popover content,
AppKit owns everything else.

## License

[MIT](LICENSE) &copy; Goran Imperator
