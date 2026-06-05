import Cocoa

class DropTargetView: NSView {
    weak var button: NSStatusBarButton?
    private var hoverTimer: Timer?
    private var hasFiredAirDrop = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func mouseDown(with event: NSEvent) {
        superview?.mouseDown(with: event)
    }

    override func rightMouseDown(with event: NSEvent) {
        superview?.rightMouseDown(with: event)
    }

    // MARK: - Drag and Drop

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard sender.draggingPasteboard.canReadObject(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) else {
            return []
        }
        button?.highlight(true)
        hasFiredAirDrop = false

        let pasteboard = sender.draggingPasteboard
        hoverTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            self?.triggerAirDrop(from: pasteboard)
        }

        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        cancelTimer()
        button?.highlight(false)
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        true
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        cancelTimer()
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
