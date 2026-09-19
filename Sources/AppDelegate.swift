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
    func cursor(_ cursor: NSCursor) -> some View {
        onHover { inside in
            if inside { cursor.push() } else { NSCursor.pop() }
        }
    }

    func expandTapTarget() -> some View {
        contentShape(Rectangle())
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var aboutWindow: NSWindow?
    private var eventMonitor: Any?

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
        popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true

        let contentView = PopoverContentView(
            openAirDropAction: { [weak self] in self?.openAirDrop() },
            aboutAction: { [weak self] in self?.showAbout() },
            quitAction: { NSApp.terminate(nil) }
        )
        let hostingController = NSHostingController(rootView: contentView)
        hostingController.preferredContentSize = NSSize(width: 340, height: 86)
        popover.contentSize = hostingController.preferredContentSize
        popover.contentViewController = hostingController
    }

    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
    }

    @objc private func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            guard let button = statusItem.button else { return }
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func closePopover() {
        popover.performClose(nil)
    }

    @objc private func showAbout() {
        if let existing = aboutWindow, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let width: CGFloat = 300
        let height: CGFloat = 320
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.center()
        window.isReleasedWhenClosed = false

        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))

        let iconView = NSImageView(frame: NSRect(x: (width - 64) / 2, y: height - 100, width: 64, height: 64))
        iconView.image = NSApp.applicationIconImage
        iconView.imageScaling = .scaleProportionallyUpOrDown
        contentView.addSubview(iconView)

        let title = NSTextField(labelWithString: "Imperator AirDrop")
        title.font = .boldSystemFont(ofSize: 16)
        title.alignment = .center
        title.frame = NSRect(x: 20, y: height - 140, width: width - 40, height: 24)
        contentView.addSubview(title)

        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        let versionLabel = NSTextField(labelWithString: "Version \(version) (\(build))")
        versionLabel.font = .systemFont(ofSize: 11)
        versionLabel.textColor = .secondaryLabelColor
        versionLabel.alignment = .center
        versionLabel.frame = NSRect(x: 20, y: height - 160, width: width - 40, height: 16)
        contentView.addSubview(versionLabel)

        let year = Calendar.current.component(.year, from: Date())
        let copyrightLabel = NSTextField(labelWithString: "\u{00A9} 1986-\(year) Goran Imperator")
        copyrightLabel.font = .systemFont(ofSize: 11)
        copyrightLabel.textColor = .tertiaryLabelColor
        copyrightLabel.alignment = .center
        copyrightLabel.frame = NSRect(x: 20, y: height - 180, width: width - 40, height: 16)
        contentView.addSubview(copyrightLabel)

        let websiteButton = NSButton(frame: NSRect(x: 20, y: height - 202, width: width - 40, height: 18))
        websiteButton.title = "goranimperator.com"
        websiteButton.bezelStyle = .inline
        websiteButton.isBordered = false
        websiteButton.font = .systemFont(ofSize: 11)
        websiteButton.contentTintColor = AppColors.brandNS
        websiteButton.alignment = .center
        websiteButton.target = self
        websiteButton.action = #selector(openWebsite)
        contentView.addSubview(websiteButton)

        let desc = NSTextField(wrappingLabelWithString: "Drop a file on the menu bar icon to send via AirDrop.")
        desc.font = .systemFont(ofSize: 13)
        desc.alignment = .center
        desc.frame = NSRect(x: 30, y: height - 250, width: width - 60, height: 40)
        contentView.addSubview(desc)

        let button = NSButton(frame: NSRect(x: 30, y: 20, width: width - 60, height: 36))
        button.title = "OK"
        button.bezelStyle = .rounded
        button.font = .systemFont(ofSize: 14, weight: .medium)
        button.isBordered = false
        button.wantsLayer = true
        button.layer?.backgroundColor = AppColors.brandNS.cgColor
        button.layer?.cornerRadius = 8
        button.contentTintColor = .white
        button.target = self
        button.action = #selector(closeAbout)
        contentView.addSubview(button)

        window.contentView = contentView
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        aboutWindow = window
    }

    @objc private func closeAbout() {
        aboutWindow?.close()
    }

    @objc private func openWebsite() {
        NSWorkspace.shared.open(URL(string: "https://www.goranimperator.com")!)
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
        .background(.black.opacity(0.15))
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
