# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```bash
make install                  # Clean build, kill old process, install to /Applications, launch
make run                      # Clean build, launch from build/
make clean                    # Remove build/
make dist VERSION=1.0.0       # Build + zip to dist/ -- no git or remote writes
make release VERSION=1.0.0    # Bump Info.plist, commit, tag, push, publish GitHub release
```

Always use `make install` after code changes -- it handles killing the old process, cleaning, rebuilding, codesigning, and launching in one step.

`make release` requires `gh` (GitHub CLI) and a clean working tree. Tags are plain semver (`v1.0.0`); the app name lives in the release title, not the tag. `CFBundleVersion` is set from the git commit count.

### Before every release

Re-read the whole README and correct anything it now gets wrong. This is a hard
requirement, not a nicety -- v1.0.0 shipped claiming "Requires macOS 13 or later"
while the binary refused to launch below macOS 26.

Verify each claim against the artifact, not against intent:

- Minimum macOS: `vtool -show-build-version` on the built binary must match
  `LSMinimumSystemVersion` and the README. `MIN_MACOS` in the Makefile is what
  actually controls it -- without `-target`, swiftc stamps the build machine's OS.
- Install steps against the real asset name, version numbers, and links.
- Signing and notarization status, and what was genuinely tested versus assumed.

After publishing, download the asset back with `gh release download` and inspect
that copy. A passing local build is not evidence about what users receive.

## Toolchain and SDK

AppKit picks which generation of a control to draw from the `sdk` field in the
binary's `LC_BUILD_VERSION`, not from the macOS it runs on. `-target` alone sets
both `minos` and `sdk` to `MIN_MACOS`, which would freeze the app on macOS 14 era
controls forever.

The Makefile therefore keeps two values apart:

- `MIN_MACOS = 14` -- the oldest macOS the app runs on, via `-target`. Matches
  `LSMinimumSystemVersion`. 14 is the real floor because SwiftUI's
  `onChange(of:initial:_:)` does not exist on 13.
- `PLATFORM_VERSION` -- `-Xlinker -platform_version` flags that stamp the
  installed SDK while leaving the minimum alone. The brandbook sanctions this
  over raising the minimum when an app has to keep running on older macOS.

Verify after any build, both numbers:

```bash
otool -l "build/Imperator AirDrop.app/Contents/MacOS/ImperatorAirdrop" | awk '/LC_BUILD_VERSION/,/^$/' | grep -E "minos|sdk"
```

Expect `minos 14.0` and `sdk 27.0`. If `sdk` equals `minos`, the linker flags did
not take and every control in the app is the old generation.

Measured on macOS 27: a SwiftUI `Toggle` in `.switch` style reports a fitting
size of 54x24pt, and `controlSize` no longer changes it. That is the view's
fitting size, not what macOS draws: the system switch in System Settings is
36x16pt. Both are 2.25:1, so `scaleEffect(0.55)` keeps the system's proportions
and lands at 30x13pt, deliberately smaller than the system control. Do not
rescale to match System Settings pixel for pixel.

## Architecture

macOS menu bar utility app. Hybrid SwiftUI + AppKit:

- **SwiftUI** -- app lifecycle only (`@main` entry point with `@NSApplicationDelegateAdaptor`)
- **AppKit** -- everything else (status bar, drag-and-drop, windows)

Three source files in `Sources/`:

| File | Role |
|------|------|
| `ImperatorAirdropApp.swift` | SwiftUI entry point, delegates to AppDelegate |
| `AppDelegate.swift` | Status bar setup, popover, About panel, dark mode/accent color |
| `DragStatusView.swift` | NSView subclass overlaid on status bar button -- handles drag-and-drop, click detection, AirDrop triggering |

Key pattern: `DropTargetView` is added as a transparent subview on `NSStatusBarButton` because status bar buttons don't natively support drag-and-drop. This subview intercepts all mouse and drag events.

## Click Handling

Click detection is manual (no `statusItem.menu` set, because that blocks double-click detection). `DropTargetView` calls back into `AppDelegate` via `onTogglePopover` / `onClosePopover`:

- **Single click** -- 0.5s timer, then toggles the `NSPopover`
- **Double click** -- cancels timer, opens Finder AirDrop
- **Right click** -- toggles the popover immediately

The popover hosts `PopoverContentView` (SwiftUI) in an `NSHostingController`. A global event monitor on `.leftMouseDown` / `.rightMouseDown` closes it on outside clicks.

## AirDrop

Uses `NSSharingService(named: .sendViaAirDrop)`. Auto-triggers after 1s hover during drag (reads URLs from drag pasteboard via timer). A red badge window (18x18 borderless `NSWindow`) follows the cursor during drag hover.

## Brand Guidelines

Follows the Imperator Apps BrandBook (`github.com/goranimperator/imperator-apps-brandbook`):

- Brand color: `#A01818` (RGB 160, 24, 24)
- Dark mode forced: `NSApp.appearance = NSAppearance(named: .darkAqua)`
- Accent override: `UserDefaults.standard.set(0, forKey: "AppleAccentColor")`
- Bundle ID: `com.goranimperator.ImperatorAirDrop`
- All UI text in English, and so are release notes, tag messages, and everything else user-facing
- Ad-hoc codesigning required (`codesign --sign - --force --deep`)

## Resources

PNG assets in `Resources/` -- menu bar icon (AirDropIcon), cursor drag badge (DragBadge), app icon (AppIcon.icns). Menu bar icon uses `isTemplate = true` for system tinting. Badge uses `isTemplate = false` (fixed red color).

## Git

- `origin` -> `git@github.com:goranimperator/imperator-airdrop.git` (private). The
  only remote; the GitLab one was removed when the repo moved.
- Commit messages in English
