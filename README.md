<p align="center">
  <img src="Resources/AppIcon.png" width="128" height="128" alt="Imperator AirDrop app icon">
</p>

<h1 align="center">Imperator AirDrop</h1>

<p align="center">
  A macOS menu bar app that turns AirDrop into a drop target. Drag a file onto
  the menu bar icon and it goes straight to the AirDrop share sheet.
</p>

## Install

Download the latest zip from [Releases](https://github.com/goranimperator/imperator-airdrop/releases),
unzip, and move `Imperator AirDrop.app` to `/Applications`.

The app is ad-hoc signed, so Gatekeeper blocks the first launch. Right-click the
app and choose **Open**, or clear the quarantine flag:

```bash
xattr -dr com.apple.quarantine "/Applications/Imperator AirDrop.app"
```

Requires macOS 14 or later, Apple silicon. Built and tested on macOS 27 only --
older versions are expected to work but have not been verified.

Install at your own risk. The app is not notarized and carries no Apple
Developer signature, so macOS cannot vouch for it. It is provided as is, with no
warranty, under the [MIT license](LICENSE).

## Use

Everything happens on the AirDrop icon in the menu bar.

**Single click** opens the panel -- Open AirDrop, Open at Login, About, and
Quit. It waits half a second before appearing, because the app has to know you
are not on your way to a double click. That pause is deliberate, not a hang.

**Double click** (two clicks within half a second) skips the panel and opens the
AirDrop window in Finder.

**Drag files onto the icon** to send them. Hold the drag still over the icon and
after one second AirDrop fires on its own -- a red badge follows the cursor while
that timer runs. Drop the files instead of waiting and the share sheet opens
immediately.

**Right click** opens the same panel as a single click, with no delay.

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
publishes a GitHub release with the zip attached:

```bash
make release VERSION=1.0.0
```

Requires the [GitHub CLI](https://cli.github.com) (`brew install gh`, then
`gh auth login`). The working tree must be clean. Tags are plain semver
(`v1.0.0`); the release title carries the app name.

### Deployment target

`MIN_MACOS` in the Makefile sets the oldest macOS the app runs on. It is separate
from the SDK the app is built against, which the `PLATFORM_VERSION` linker flags
stamp from whatever Xcode is installed. AppKit reads that SDK stamp to decide
which generation of controls to draw, so the app keeps a macOS 14 minimum while
still drawing current controls on macOS 27.

Check both after a build:

```bash
otool -l "build/Imperator AirDrop.app/Contents/MacOS/ImperatorAirdrop" | awk '/LC_BUILD_VERSION/,/^$/' | grep -E "minos|sdk"
```

## Layout

| Path | Role |
|------|------|
| `Sources/ImperatorAirdropApp.swift` | SwiftUI entry point |
| `Sources/AppDelegate.swift` | Status bar, menu bar panel, About panel |
| `Sources/MenuBarPanel.swift` | The menu bar panel the app draws itself |
| `Sources/DragStatusView.swift` | Drag-and-drop and click handling |
| `Resources/` | Icons and `Info.plist` |

Hybrid SwiftUI + AppKit: SwiftUI owns the app lifecycle and the panel's content,
AppKit owns everything else.

The menu bar panel is an `NSPanel` the app draws rather than an `NSPopover`, so it
matches what macOS 27 draws for its own menu bar panels: a plain rounded rectangle
with no arrow and no open or close animation. The measurements behind that live in
`Sources/MenuBarPanel.swift`.

## License

[MIT](LICENSE) &copy; Goran Imperator
