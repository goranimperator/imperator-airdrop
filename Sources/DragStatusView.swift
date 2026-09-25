import Cocoa

class DropTargetView: NSView {
    weak var button: NSStatusBarButton?
    weak var statusItem: NSStatusItem?
    var onTogglePopover: (() -> Void)?
    var onClosePopover: (() -> Void)?
    private var hoverTimer: Timer?
    private var hasFiredAirDrop = false
    private var badgeWindow: NSWindow?
    private var clickTimer: Timer?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // The app's own double-click window. Deliberately not
    // NSEvent.doubleClickInterval: that is a user setting (1.8s on the
    // author's machine), and a single click has to wait out the whole window
    // before the panel may open.
    private static let doubleClickWindow: TimeInterval = 0.5
    private var lastClickTime: TimeInterval?

    override func mouseDown(with event: NSEvent) {
        // Double click is detected from the timestamps, never from
        // event.clickCount. On macOS 27 a status item receives every click with
        // a clickCount of 1, so a check for 2 never matches and double click
        // silently degrades into two single clicks.
        if let last = lastClickTime,
           event.timestamp - last <= Self.doubleClickWindow {
            lastClickTime = nil
            clickTimer?.invalidate()
            clickTimer = nil
            openAirDropInFinder()
            return
        }

        lastClickTime = event.timestamp
        // Cancel any pending timer first. Assigning over the property drops the
        // old timer without invalidating it, so two slow clicks used to fire
        // two timers and toggle the panel open and straight back shut.
        clickTimer?.invalidate()
        clickTimer = Timer.scheduledTimer(withTimeInterval: Self.doubleClickWindow,
                                          repeats: false) { [weak self] _ in
            self?.showMenu()
        }
    }

    private func openAirDropInFinder() {
        onClosePopover?()
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app/Contents/Applications/AirDrop.app"))
    }

    override func rightMouseDown(with event: NSEvent) {
        showMenu()
    }

    private func showMenu() {
        onTogglePopover?()
    }

    // MARK: - Badge Window

    private func showBadge(near sender: NSDraggingInfo) {
        if badgeWindow == nil {
            let size: CGFloat = 18
            let win = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: size, height: size),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            win.isOpaque = false
            win.backgroundColor = .clear
            win.level = .statusBar + 1
            win.ignoresMouseEvents = true
            win.hasShadow = false

            let imageView = NSImageView(frame: NSRect(x: 0, y: 0, width: size, height: size))
            let badge = Bundle.main.image(forResource: "DragBadge")
            badge?.isTemplate = false
            imageView.image = badge
            imageView.imageScaling = .scaleProportionallyUpOrDown
            win.contentView = imageView

            badgeWindow = win
        }

        updateBadgePosition(sender)
        badgeWindow?.orderFront(nil)
    }

    private func updateBadgePosition(_ sender: NSDraggingInfo) {
        guard let win = badgeWindow, let sourceWindow = self.window else { return }
        let localPoint = sender.draggingLocation
        let screenPoint = sourceWindow.convertPoint(toScreen: localPoint)
        win.setFrameOrigin(NSPoint(x: screenPoint.x + 14, y: screenPoint.y - 22))
    }

    private func hideBadge() {
        badgeWindow?.orderOut(nil)
    }

    // MARK: - Drag and Drop

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard sender.draggingPasteboard.canReadObject(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) else {
            return []
        }

        onClosePopover?()
        button?.highlight(true)
        showBadge(near: sender)
        hasFiredAirDrop = false

        let pasteboard = sender.draggingPasteboard
        hoverTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            self?.triggerAirDrop(from: pasteboard)
        }

        return .generic
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        updateBadgePosition(sender)
        return .generic
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        cancelTimer()
        hideBadge()
        button?.highlight(false)
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        true
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        cancelTimer()
        hideBadge()
        button?.highlight(false)

        if hasFiredAirDrop { return true }

        guard let urls = sender.draggingPasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL], !urls.isEmpty else {
            return false
        }

        return sendViaAirDrop(urls: urls)
    }

    // MARK: - AirDrop

    private func triggerAirDrop(from pasteboard: NSPasteboard) {
        guard let urls = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL], !urls.isEmpty else {
            return
        }

        hasFiredAirDrop = true
        hideBadge()
        button?.highlight(false)
        sendViaAirDrop(urls: urls)
    }

    @discardableResult
    private func sendViaAirDrop(urls: [URL]) -> Bool {
        guard let airdrop = NSSharingService(named: .sendViaAirDrop) else {
            showAlert(
                title: "AirDrop Unavailable",
                message: "Make sure Bluetooth and Wi-Fi are enabled."
            )
            return false
        }

        guard airdrop.canPerform(withItems: urls) else {
            showAlert(
                title: "Cannot Send via AirDrop",
                message: "Make sure AirDrop is enabled in System Settings."
            )
            return false
        }

        airdrop.perform(withItems: urls)
        return true
    }

    private func cancelTimer() {
        hoverTimer?.invalidate()
        hoverTimer = nil
    }

    private func showAlert(title: String, message: String) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }
}
