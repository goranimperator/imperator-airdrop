# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```bash
make install   # Clean build, kill old process, install to /Applications, launch
make run       # Clean build, launch from build/
make clean     # Remove build/
```

Always use `make install` after code changes -- it handles killing the old process, cleaning, rebuilding, codesigning, and launching in one step.

## Architecture

macOS menu bar utility app. Hybrid SwiftUI + AppKit:

- **SwiftUI** -- app lifecycle only (`@main` entry point with `@NSApplicationDelegateAdaptor`)
- **AppKit** -- everything else (status bar, drag-and-drop, windows)

Three source files in `Sources/`:

| File | Role |
|------|------|
| `ImperatorAirdropApp.swift` | SwiftUI entry point, delegates to AppDelegate |
| `AppDelegate.swift` | Status bar setup, menu, About panel, dark mode/accent color |
| `DragStatusView.swift` | NSView subclass overlaid on status bar button -- handles drag-and-drop, click detection, AirDrop triggering |

Key pattern: `DropTargetView` is added as a transparent subview on `NSStatusBarButton` because status bar buttons don't natively support drag-and-drop. This subview intercepts all mouse and drag events.

## Click Handling

Click detection is manual (no `statusItem.menu` set, because that blocks double-click detection):

- **Single click** -- 0.5s timer, then shows context menu via temporary `statusItem.menu` trick
- **Double click** -- cancels timer, opens Finder AirDrop
- **Right click** -- shows context menu immediately

## AirDrop

Uses `NSSharingService(named: .sendViaAirDrop)`. Auto-triggers after 1s hover during drag (reads URLs from drag pasteboard via timer). A red badge window (18x18 borderless `NSWindow`) follows the cursor during drag hover.

## Brand Guidelines

Follows the Imperator Apps BrandBook (`gitlab.com/goranimperator/imperator-mac-apps-brandbook`):

- Brand color: `#A01818` (RGB 160, 24, 24)
- Dark mode forced: `NSApp.appearance = NSAppearance(named: .darkAqua)`
- Accent override: `UserDefaults.standard.set(0, forKey: "AppleAccentColor")`
- Bundle ID: `com.goranimperator.ImperatorAirDrop`
- All UI text in English
- Ad-hoc codesigning required (`codesign --sign - --force --deep`)

## Resources

PNG assets in `Resources/` -- menu bar icon (AirDropIcon), cursor drag badge (DragBadge), app icon (AppIcon.icns). Menu bar icon uses `isTemplate = true` for system tinting. Badge uses `isTemplate = false` (fixed red color).

## Git

- Remote: `git@gitlab.com:goranimperator/imperator-airdrop.git`
- Commit messages in English
