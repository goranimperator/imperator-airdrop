import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var statusItem: NSStatusItem!
    private var aboutWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        NSApp.appearance = NSAppearance(named: .darkAqua)
        UserDefaults.standard.set(0, forKey: "AppleAccentColor")
        ProcessInfo.processInfo.setValue("Imperator AirDrop", forKey: "processName")

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        guard let button = statusItem.button else { return }
        let bundle = Bundle.main
        let image = bundle.image(forResource: "AirDropIcon")
        image?.isTemplate = true
        image?.size = NSSize(width: 14, height: 14)
        button.image = image
        button.toolTip = "Drop a file here to send via AirDrop"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "About Imperator AirDrop", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Open AirDrop", action: #selector(openAirDrop), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        let dropTarget = DropTargetView(frame: button.bounds)
        dropTarget.autoresizingMask = [.width, .height]
        dropTarget.button = button
        dropTarget.statusItem = statusItem
        dropTarget.clickMenu = menu
        button.addSubview(dropTarget)
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
        websiteButton.contentTintColor = NSColor(red: 0xa0/255.0, green: 0x18/255.0, blue: 0x18/255.0, alpha: 1)
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

    @objc private func openWebsite() {
        NSWorkspace.shared.open(URL(string: "https://www.goranimperator.com")!)
    }

    @objc private func openAirDrop() {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app/Contents/Applications/AirDrop.app"))
    }
}
