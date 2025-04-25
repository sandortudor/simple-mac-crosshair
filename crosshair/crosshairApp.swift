import Cocoa

class CrosshairView: NSView {
    var crosshairColor = NSColor.red
    var crosshairSize: CGFloat = 5  // Changed default from 10 to 5 (small)
    var verticalOffset: CGFloat = -19  // Changed default from -20 to -19
    private var isDrawing = false
    
    // Only draw once when initialized
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        setNeedsDisplay(bounds)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        if isDrawing { return }
        isDrawing = true
        
        crosshairColor.set()
        let path = NSBezierPath()
        let center = NSPoint(x: bounds.midX, y: bounds.midY + verticalOffset)
        
        path.move(to: NSPoint(x: center.x - crosshairSize, y: center.y))
        path.line(to: NSPoint(x: center.x + crosshairSize, y: center.y))
        
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
    
    // Store original settings for potential reset
    private var originalColor: NSColor = .red
    private var originalSize: CGFloat = 5  // Changed default from 10 to 5 (small)
    private var originalOffset: CGFloat = -19  // Changed default from -20 to -19
    
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
        // Store original values in case user cancels
        originalColor = view.crosshairColor
        originalSize = view.crosshairSize
        originalOffset = view.verticalOffset
        
        let alert = NSAlert()
        alert.messageText = "Crosshair Settings"
        alert.informativeText = "Choose your crosshair color, size, and vertical position."
        
        // Simple accessory view
        let accessoryView = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 120))
        
        // Color popup
        let colorPopUp = NSPopUpButton(frame: NSRect(x: 10, y: 85, width: 180, height: 25))
        colorPopUp.addItems(withTitles: ["Red", "Green", "White", "Yellow"])
        accessoryView.addSubview(colorPopUp)
        
        // Size popup
        let sizePopUp = NSPopUpButton(frame: NSRect(x: 10, y: 50, width: 180, height: 25))
        sizePopUp.addItems(withTitles: ["Small", "Medium", "Large"])
        accessoryView.addSubview(sizePopUp)
        
        // Offset label
        let offsetLabel = NSTextField(frame: NSRect(x: 10, y: 25, width: 110, height: 20))
        offsetLabel.stringValue = "Vertical Offset:"
        offsetLabel.isEditable = false
        offsetLabel.isBordered = false
        offsetLabel.isSelectable = false
        offsetLabel.drawsBackground = false
        accessoryView.addSubview(offsetLabel)
        
        // Offset value label
        let offsetValueLabel = NSTextField(frame: NSRect(x: 130, y: 25, width: 60, height: 20))
        offsetValueLabel.stringValue = "\(Int(view.verticalOffset))"
        offsetValueLabel.isEditable = false
        offsetValueLabel.isBordered = false
        offsetValueLabel.isSelectable = false
        offsetValueLabel.drawsBackground = false
        offsetValueLabel.alignment = .right
        accessoryView.addSubview(offsetValueLabel)
        
        // Offset slider with action
        let offsetSlider = NSSlider(frame: NSRect(x: 10, y: 10, width: 180, height: 20))
        offsetSlider.minValue = -100
        offsetSlider.maxValue = 100
        offsetSlider.intValue = Int32(view.verticalOffset)
        offsetSlider.isContinuous = true  // Enable continuous updates while dragging
        
        // Create a custom action that will update both the label and crosshair
        class SliderAction: NSObject {
            weak var slider: NSSlider?
            weak var label: NSTextField?
            weak var crosshairView: CrosshairView?
            
            @objc func valueChanged(_ sender: NSSlider) {
                let value = Int(sender.intValue)
                label?.stringValue = "\(value)"
                crosshairView?.verticalOffset = CGFloat(value)
                crosshairView?.updateCrosshair()
            }
        }
        
        let sliderAction = SliderAction()
        sliderAction.slider = offsetSlider
        sliderAction.label = offsetValueLabel
        sliderAction.crosshairView = view
        
        // Set target and action for real-time updates
        offsetSlider.target = sliderAction
        offsetSlider.action = #selector(SliderAction.valueChanged(_:))
        
        // Store the action object to prevent it from being deallocated
        objc_setAssociatedObject(offsetSlider, "actionObject", sliderAction, .OBJC_ASSOCIATION_RETAIN)
        
        accessoryView.addSubview(offsetSlider)
        
        alert.accessoryView = accessoryView
        
        // Select current values
        switch view.crosshairColor {
        case NSColor.green: colorPopUp.selectItem(withTitle: "Green")
        case NSColor.white: colorPopUp.selectItem(withTitle: "White")
        case NSColor.yellow: colorPopUp.selectItem(withTitle: "Yellow")
        default: colorPopUp.selectItem(withTitle: "Red")
        }
        
        // Always select "Small" by default
        sizePopUp.selectItem(withTitle: "Small")
        
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        
        // Apply settings only if OK was pressed
        if response == .alertFirstButtonReturn {
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
            
            let newOffset = CGFloat(offsetSlider.doubleValue)
            
            // Update only if necessary (already updated in real-time, but this ensures final state is correct)
            view.crosshairColor = newColor
            view.crosshairSize = newSize
            view.verticalOffset = newOffset
            view.updateCrosshair()
        } else {
            // Restore original values if canceled
            view.crosshairColor = originalColor
            view.crosshairSize = originalSize
            view.verticalOffset = originalOffset
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
