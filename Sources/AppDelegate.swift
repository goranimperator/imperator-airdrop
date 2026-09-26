import Cocoa
import SwiftUI
import ServiceManagement

enum AppColors {
    static let brand = Color(red: 0xa0/255.0, green: 0x18/255.0, blue: 0x18/255.0)
    static let brandFaded = brand.opacity(0.25)
    static let accent = Color(red: 0.43, green: 0.05, blue: 0.05)
    static let brandNS = NSColor(red: 0xa0/255.0, green: 0x18/255.0, blue: 0x18/255.0, alpha: 1.0)
}

extension View {
    func expandTapTarget() -> some View {
        contentShape(Rectangle())
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var statusItem: NSStatusItem!
    private var panel: MenuBarPanel!
    private var aboutPanel: NSPanel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        NSApp.appearance = NSAppearance(named: .darkAqua)
        UserDefaults.standard.set(0, forKey: "AppleAccentColor")
        ProcessInfo.processInfo.setValue("Imperator AirDrop", forKey: "processName")

        setupPopover()
        setupStatusItem()
        setupEventMonitor()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        guard let button = statusItem.button else { return }
        let image = Bundle.main.image(forResource: "AirDropIcon")
        image?.isTemplate = true
        image?.size = NSSize(width: 14, height: 14)
        button.image = image
        button.toolTip = "Drop a file here to send via AirDrop"

        let dropTarget = DropTargetView(frame: button.bounds)
        dropTarget.autoresizingMask = [.width, .height]
        dropTarget.button = button
        dropTarget.statusItem = statusItem
        dropTarget.onTogglePopover = { [weak self] in self?.togglePopover() }
        dropTarget.onClosePopover = { [weak self] in self?.closePopover() }
        button.addSubview(dropTarget)
    }

    private func setupPopover() {
        let contentView = PopoverContentView(
            openAirDropAction: { [weak self] in self?.openAirDrop() },
            aboutAction: { [weak self] in self?.showAbout() },
            quitAction: { NSApp.terminate(nil) }
        )
        // A MenuBarPanel rather than an NSPopover. macOS 27 draws its own menu
        // bar panels as plain rounded rectangles: a 17.50 pt corner, no arrow
        // and no animation, measured off Control Centre's Wi-Fi panel. An
        // NSPopover draws none of that and exposes none of it for adjustment.
        panel = MenuBarPanel(content: contentView, width: 340)
        panel.contentHeight = { 86 }
    }

    private func setupEventMonitor() {
        // The click-outside dismissal lives in MenuBarPanel, which owns the
        // same monitor plus the exception for the status item's own click.
    }

    @objc private func togglePopover() {
        if panel.isShown {
            closePopover()
        } else {
            guard let button = statusItem.button else { return }
            panel.show(from: button)
            NSApp.activate(ignoringOtherApps: true)
            panel.makeKey()
        }
    }

    private func closePopover() {
        panel.close()
    }

    @objc private func showAbout() {
        if let existing = aboutPanel, existing.isVisible {
            NSApp.activate(ignoringOtherApps: true)
            existing.makeKeyAndOrderFront(nil)
            return
        }
        let created = AboutPanel.make()
        created.center()
        // Ordering front is not enough from an LSUIElement app: without the
        // activation the panel is created behind whatever the user was in.
        NSApp.activate(ignoringOtherApps: true)
        created.makeKeyAndOrderFront(nil)
        aboutPanel = created
    }


    @objc private func openAirDrop() {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app/Contents/Applications/AirDrop.app"))
    }
}

struct PopoverContentView: View {
    let openAirDropAction: () -> Void
    let aboutAction: () -> Void
    let quitAction: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if let icon = Bundle.main.image(forResource: "AirDropIcon") {
                    Image(nsImage: icon)
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 14, height: 14)
                        .foregroundStyle(.white)
                }
                Text("Imperator AirDrop")
                    .font(.headline)
                Spacer()
                HoverButton(action: openAirDropAction) {
                    Text("Open AirDrop")
                        .font(.caption)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            HStack {
                LaunchAtLoginToggle()
                Spacer()
                HoverButton(action: aboutAction) {
                    Text("About")
                        .font(.caption)
                }
                HoverButton(action: quitAction) {
                    Text("Quit")
                        .font(.caption)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(width: 340)
        // Brandbook 6.1: the tint over the panel's material, which is what
        // every Imperator menu bar app paints. This was left bare while the app
        // used an NSPopover, because that control paints its own chrome and a
        // second fill on top read as a panel inside a panel. MenuBarPanel puts
        // the system's `.popover` material down and nothing else, so the tint
        // belongs here again.
        .background(Color.black.opacity(0.15))
    }
}

struct LaunchAtLoginToggle: View {
    @State private var isEnabled = SMAppService.mainApp.status == .enabled
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 6) {
            Text("Open at Login")
                .font(.caption)
            Toggle("", isOn: $isEnabled)
                .toggleStyle(.switch)
                .scaleEffect(0.55)
                .tint(AppColors.brand)
                .labelsHidden()
                .onChange(of: isEnabled) { _, newValue in
                    do {
                        if newValue { try SMAppService.mainApp.register() }
                        else { try SMAppService.mainApp.unregister() }
                    } catch {
                        isEnabled = SMAppService.mainApp.status == .enabled
                    }
                }
        }
        .opacity(isHovered ? 1.0 : 0.45)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { isHovered = $0 }
    }
}

struct HoverButton<Label: View>: View {
    let action: () -> Void
    @ViewBuilder let label: () -> Label
    @State private var isHovered = false

    var body: some View {
        Button(action: action) { label() }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
            .opacity(isHovered ? 1.0 : 0.45)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .onHover { isHovered = $0 }
    }
}

/// Brandbook 10: a standalone panel, not a sheet and not a second popover.
///
/// Ported from imperator-widget-clock, which worked out both traps this app used
/// to fall into: a panel that vanishes on the first outside click, and an icon
/// that silently resolves to nothing.
enum AboutPanel {
    /// Brandbook 10.2: 300 x 260. The panel grows if the content needs more, and
    /// never carries an explicit height on the view: a frame is a proposal that
    /// children are free to overflow, and the window would size itself to the
    /// overflow instead.
    static let width: CGFloat = 300
    static let specifiedHeight: CGFloat = 260

    static func make() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: width, height: specifiedHeight),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false
        // An NSPanel hides itself when its app deactivates, and this app is an
        // LSUIElement that goes inactive the moment anything else is clicked.
        // Left at the default the panel disappears behind the first click
        // outside it.
        panel.hidesOnDeactivate = false
        panel.appearance = NSAppearance(named: .darkAqua)
        panel.contentViewController = NSHostingController(rootView: AboutView())
        // Setting contentViewController resizes the window to the hosted view's
        // fitting size, and a SwiftUI view that has not laid out yet reports
        // zero. Without this the panel comes up 0x0 and the contentRect above is
        // thrown away.
        if let hosted = panel.contentViewController?.view {
            hosted.layoutSubtreeIfNeeded()
            panel.setContentSize(NSSize(width: width,
                                        height: max(specifiedHeight, hosted.fittingSize.height)))
        } else {
            panel.setContentSize(NSSize(width: width, height: specifiedHeight))
        }
        return panel
    }

}

/// Brandbook 10.3, in its order: icon, name, version, copyright, website.
struct AboutView: View {
    @State private var isLinkHovered = false

    /// Both read from the bundle, so the panel cannot claim a version the build
    /// does not carry.
    static func versionText(from bundle: Bundle = .main) -> String {
        let short = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "Version \(short) (Build \(build))"
    }

    /// Brandbook 10.4: the end year is stamped at launch, because a plist cannot
    /// hold a value that moves.
    static func copyrightText(year: Int = Calendar.current.component(.year, from: Date())) -> String {
        "\u{00A9} 1986-\(year) Goran Imperator"
    }

    static let websiteURL = URL(string: "https://www.goranimperator.com")!

    /// Loaded by name rather than through `NSApp.applicationIconImage`, which
    /// returns an empty image in an LSUIElement app. An empty image in SwiftUI
    /// is not a 64pt blank: the view takes no space at all, so the panel lays
    /// out short with no icon and no gap where one should be.
    static var iconImage: NSImage {
        if let named = NSImage(named: "AppIcon") { return named }
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let fromFile = NSImage(contentsOf: url) {
            return fromFile
        }
        return NSApp.applicationIconImage ?? NSImage()
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: AboutView.iconImage)
                .resizable()
                .interpolation(.high)
                .frame(width: 64, height: 64)

            Text("Imperator AirDrop")
                .font(.headline)

            Text(AboutView.versionText())
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(AboutView.copyrightText())
                .font(.caption)
                .foregroundStyle(.tertiary)

            // A Button rather than a Text with a tap gesture: a tap gesture is
            // reachable by the mouse alone, and this is the one link in the app.
            Button {
                NSWorkspace.shared.open(AboutView.websiteURL)
            } label: {
                Text("goranimperator.com")
                    .font(.caption)
                    .foregroundStyle(AppColors.brand)
                    .underline(isLinkHovered)
            }
            .buttonStyle(.plain)
            .onHover { isLinkHovered = $0 }
            .help("Open goranimperator.com")
        }
        .padding(24)
        .frame(width: AboutPanel.width)
        .fixedSize(horizontal: false, vertical: true)
    }
}
