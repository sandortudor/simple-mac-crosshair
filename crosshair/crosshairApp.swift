import Cocoa

class CrosshairView: NSView {
    var crosshairColor = NSColor.red
    var crosshairSize: CGFloat = 10
    private var isDrawing = false
    
    // Only draw once when initialized
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        setNeedsDisplay(bounds)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        // Prevent recursive or unnecessary drawing
        if isDrawing { return }
        isDrawing = true
        
        crosshairColor.set()
        let path = NSBezierPath()
        let center = NSPoint(x: bounds.midX, y: bounds.midY)
        
        // Draw horizontal line
        path.move(to: NSPoint(x: center.x - crosshairSize, y: center.y))
        path.line(to: NSPoint(x: center.x + crosshairSize, y: center.y))
        
        // Draw vertical line
        path.move(to: NSPoint(x: center.x, y: center.y - crosshairSize))
        path.line(to: NSPoint(x: center.x, y: center.y + crosshairSize))
        
        path.lineWidth = 2
        path.stroke()
        
        isDrawing = false
    }
    
    // Force redraw only when settings change
    func updateCrosshair() {
        setNeedsDisplay(bounds)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var view: CrosshairView!
    var statusItem: NSStatusItem!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create window
        let screenSize = NSScreen.main?.frame ?? NSRect.zero
        window = NSWindow(
            contentRect: screenSize,
            styleMask: .borderless,
            backing: .buffered,
            defer: true
        )
        
        // Basic window settings
        window.level = .screenSaver
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Create and add view
        view = CrosshairView(frame: screenSize)
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        window.contentView = view
        
        // Setup menu
        setupMenuBarIcon()
        
        // Show settings (once at startup)
        DispatchQueue.main.async {
            self.showSettings()
            self.window.makeKeyAndOrderFront(nil)
        }
        
        // Monitor screen changes with low frequency
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(updateWindowForScreen),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )
    }
    
    @objc private func updateWindowForScreen() {
        if let screen = NSScreen.main {
            window.setFrame(screen.frame, display: false)
            view.frame = NSRect(origin: .zero, size: screen.frame.size)
            view.updateCrosshair()
        }
    }
    
    private func setupMenuBarIcon() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        // Simple menu with minimal items
        let menu = NSMenu()
        let settingsItem = NSMenuItem(title: "Settings", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        if let button = statusItem.button {
            button.title = "+"
        }
        statusItem.menu = menu
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
    
    @objc private func showSettings() {
        let alert = NSAlert()
        alert.messageText = "Crosshair Settings"
        alert.informativeText = "Choose your crosshair color and size."
        
        // Simple accessory view
        let accessoryView = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 80))
        
        // Color popup
        let colorPopUp = NSPopUpButton(frame: NSRect(x: 10, y: 45, width: 180, height: 25))
        colorPopUp.addItems(withTitles: ["Red", "Green", "White", "Yellow"])
        accessoryView.addSubview(colorPopUp)
        
        // Size popup
        let sizePopUp = NSPopUpButton(frame: NSRect(x: 10, y: 10, width: 180, height: 25))
        sizePopUp.addItems(withTitles: ["Small", "Medium", "Large"])
        accessoryView.addSubview(sizePopUp)
        
        alert.accessoryView = accessoryView
        alert.addButton(withTitle: "OK")
        
        alert.runModal()
        
        // Apply settings
        var newColor: NSColor
        switch colorPopUp.selectedItem?.title {
        case "Green": newColor = .green
        case "White": newColor = .white
        case "Yellow": newColor = .yellow
        default: newColor = .red
        }
        
        var newSize: CGFloat
        switch sizePopUp.selectedItem?.title {
        case "Small": newSize = 5
        case "Large": newSize = 20
        default: newSize = 10
        }
        
        // Update only if necessary
        if view.crosshairColor != newColor || view.crosshairSize != newSize {
            view.crosshairColor = newColor
            view.crosshairSize = newSize
            view.updateCrosshair()
        }
    }
}

@main
class CrosshairApp: NSObject, NSApplicationDelegate {
    private var appDelegate: AppDelegate!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        appDelegate = AppDelegate()
        appDelegate.applicationDidFinishLaunching(notification)
    }
    
    static func main() {
        let app = NSApplication.shared
        let delegate = CrosshairApp()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}
