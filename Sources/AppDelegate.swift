import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var statusItem: NSStatusItem!
    private var aboutWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        guard let button = statusItem.button else { return }
        let bundle = Bundle.main
        let image = bundle.image(forResource: "AirDropIcon")
        image?.isTemplate = true
        image?.size = NSSize(width: image!.size.width * 0.9, height: image!.size.height * 0.9)
        button.image = image
        button.toolTip = "Drop a file here to send via AirDrop"

        let dropTarget = DropTargetView(frame: button.bounds)
        dropTarget.autoresizingMask = [.width, .height]
        dropTarget.button = button
        button.addSubview(dropTarget)

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "About Imperator AirDrop", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc private func showAbout() {
        if let existing = aboutWindow, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let width: CGFloat = 300
        let height: CGFloat = 260
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

        let desc = NSTextField(wrappingLabelWithString: "Drop a file on the menu bar icon to send via AirDrop.")
        desc.font = .systemFont(ofSize: 13)
        desc.alignment = .center
        desc.frame = NSRect(x: 30, y: height - 185, width: width - 60, height: 40)
        contentView.addSubview(desc)

        let button = NSButton(frame: NSRect(x: 30, y: 20, width: width - 60, height: 36))
        button.title = "OK"
        button.bezelStyle = .rounded
        button.font = .systemFont(ofSize: 14, weight: .medium)
        button.isBordered = false
        button.wantsLayer = true
        button.layer?.backgroundColor = NSColor(red: 0xa0/255.0, green: 0x18/255.0, blue: 0x18/255.0, alpha: 1).cgColor
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
}
