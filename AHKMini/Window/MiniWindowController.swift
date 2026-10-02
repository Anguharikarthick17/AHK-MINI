import AppKit
import SpriteKit

/// Controls the floating arcade game panel, positioning beneath the menu bar,
/// smooth animated open/close, click-outside dismissal, and game lifecycle pausing/resuming.
final class MiniWindowController: NSObject, NSWindowDelegate {
    
    let panelSize = CGSize(width: 420.0, height: 140.0)
    
    private(set) var panel: MiniPanel!
    private var skView: SKView!
    private(set) var gameScene: MiniGameScene!
    private var globalEventMonitor: Any?
    private var isAnimating: Bool = false
    
    var onVisibilityChanged: ((Bool) -> Void)?
    
    var isVisible: Bool {
        return panel.isVisible && panel.alphaValue > 0.01
    }
    
    override init() {
        super.init()
        setupPanel()
    }
    
    deinit {
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    private func setupPanel() {
        let initialRect = NSRect(origin: .zero, size: panelSize)
        panel = MiniPanel(contentRect: initialRect)
        panel.delegate = self
        
        // Premium rounded container
        let containerView = NSView(frame: NSRect(origin: .zero, size: panelSize))
        containerView.wantsLayer = true
        containerView.layer?.cornerRadius = 14.0
        containerView.layer?.cornerCurve = .continuous
        containerView.layer?.masksToBounds = true
        containerView.layer?.borderWidth = 1.0
        containerView.layer?.borderColor = NSColor(white: 1.0, alpha: 0.14).cgColor
        containerView.layer?.backgroundColor = NSColor(red: 0.055, green: 0.055, blue: 0.063, alpha: 1.0).cgColor
        
        // SpriteKit view setup
        skView = SKView(frame: NSRect(origin: .zero, size: panelSize))
        skView.autoresizingMask = [.width, .height]
        skView.allowsTransparency = true
        skView.ignoresSiblingOrder = true
        skView.showsFPS = false
        skView.showsNodeCount = false
        skView.preferredFramesPerSecond = 60 // Strict 60 FPS cap (never 120 FPS ProMotion)
        skView.isPaused = true               // Paused by default until opened
        
        gameScene = MiniGameScene(size: panelSize)
        skView.presentScene(gameScene)
        
        containerView.addSubview(skView)
        panel.contentView = containerView
        
        // Key routing guarantee
        panel.onKeyDown = { [weak self] event in
            self?.gameScene.keyDown(with: event)
        }
    }
    
    /// Toggles the panel state relative to the given menu bar status button.
    func toggle(relativeTo button: NSStatusBarButton?) {
        if isVisible {
            closePanel(animated: true)
        } else {
            openPanel(relativeTo: button)
        }
    }
    
    /// Opens the panel anchored directly beneath the menu bar button.
    func openPanel(relativeTo button: NSStatusBarButton?) {
        guard !isAnimating else { return }
        
        // Calculate target screen frame strictly below the menu bar
        let targetFrame = calculateTargetFrame(relativeTo: button)
        let animOffset: CGFloat = 2.0 // Starts 2pt higher, still strictly 4pt below menu bar
        let startFrame = NSRect(
            x: targetFrame.origin.x,
            y: targetFrame.origin.y + animOffset,
            width: targetFrame.width,
            height: targetFrame.height
        )
        
        panel.setFrame(startFrame, display: false)
        panel.alphaValue = 0.0
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        panel.makeFirstResponder(gameScene)
        onVisibilityChanged?(true)
        
        // Resume SpriteKit rendering and game loop
        skView.isPaused = false
        gameScene.resumeGame()
        
        // Animate appearance smoothly
        isAnimating = true
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.14
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrame(targetFrame, display: true)
            panel.animator().alphaValue = 1.0
        }, completionHandler: { [weak self] in
            guard let self = self else { return }
            // Ensure exact final target frame
            self.panel.setFrame(targetFrame, display: true)
            self.panel.alphaValue = 1.0
            self.isAnimating = false
            self.panel.makeFirstResponder(self.gameScene)
            self.startClickOutsideMonitor(ignoring: button)
        })
    }
    
    /// Closes the panel with a smooth fade/slide and pauses the game scene.
    func closePanel(animated: Bool = true) {
        guard isVisible || panel.isVisible else { return }
        guard !isAnimating else { return }
        
        stopClickOutsideMonitor()
        onVisibilityChanged?(false)
        
        // Pause game and halt SpriteKit rendering completely to conserve battery and CPU
        gameScene.pauseGame()
        skView.isPaused = true
        
        if animated {
            isAnimating = true
            let exitFrame = NSRect(
                x: panel.frame.origin.x,
                y: panel.frame.origin.y + 2.0,
                width: panel.frame.width,
                height: panel.frame.height
            )
            
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.12
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                panel.animator().setFrame(exitFrame, display: true)
                panel.animator().alphaValue = 0.0
            }, completionHandler: { [weak self] in
                guard let self = self else { return }
                self.panel.orderOut(nil)
                self.isAnimating = false
            })
        } else {
            panel.alphaValue = 0.0
            panel.orderOut(nil)
        }
    }
    
    func calculateTargetFrame(relativeTo button: NSStatusBarButton?) -> NSRect {
        // Visually comfortable gap of 12pt (10-14 pt target) strictly beneath the macOS menu bar / status item
        let visualGap: CGFloat = 12.0
        
        guard let button = button, let buttonWindow = button.window else {
            // Safe fallback if button is unavailable: top right of main screen below menu bar
            let screen = NSScreen.main ?? NSScreen.screens.first!
            let menuBarBottomY = screen.visibleFrame.maxY
            let panelTopY = menuBarBottomY - visualGap
            let targetY = panelTopY - panelSize.height
            let targetX = screen.visibleFrame.maxX - panelSize.width - 24.0
            return NSRect(origin: CGPoint(x: targetX, y: targetY), size: panelSize)
        }
        
        // 1. Get the screen hosting the status item window
        let screen = buttonWindow.screen ?? button.window?.screen ?? NSScreen.main ?? NSScreen.screens.first!
        
        // 2. Convert button bounds to window coordinates, then to global screen coordinates
        let buttonBoundsInWindow = button.convert(button.bounds, to: nil)
        let buttonScreenRect = buttonWindow.convertToScreen(buttonBoundsInWindow)
        
        // 3. Determine the true bottom edge of the menu-bar / status-item region.
        // In AppKit screen coordinates:
        // - screen.visibleFrame.maxY is the bottom edge of the standard menu bar on this display.
        // - buttonScreenRect.minY is the bottom edge of the actual status-item button on this display.
        // Taking min(...) guarantees that the panel's top is strictly at or below both the button and the menu bar:
        let menuBarBottomY = min(buttonScreenRect.minY, screen.visibleFrame.maxY)
        
        // 4. Position the panel's top edge strictly below the menu bar with the specified gap
        let panelTopY = menuBarBottomY - visualGap
        let targetY = panelTopY - panelSize.height
        
        // 5. Align panel's right edge directly with the status-item button's right edge
        var targetX = buttonScreenRect.maxX - panelSize.width
        
        // 6. Clamp horizontally to the screen's visible frame so it never bleeds off-screen
        let minX = screen.visibleFrame.minX + 8.0
        let maxX = screen.visibleFrame.maxX - panelSize.width - 8.0
        targetX = max(minX, min(targetX, maxX))
        
        return NSRect(origin: CGPoint(x: targetX, y: targetY), size: panelSize)
    }
    
    // MARK: - Passive Click-Outside Dismissal
    
    private func startClickOutsideMonitor(ignoring button: NSStatusBarButton?) {
        stopClickOutsideMonitor()
        
        // Global monitor passively observes clicks without intercepting them
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] event in
            guard let self = self, self.isVisible else { return }
            
            let clickLocation = NSEvent.mouseLocation
            
            // If click is on the menu bar button itself, the button's action handler handles it
            if let button = button, let buttonWindow = button.window {
                if buttonWindow.frame.contains(clickLocation) {
                    return
                }
            }
            
            // If clicked outside the game panel, dismiss immediately
            if !self.panel.frame.contains(clickLocation) {
                DispatchQueue.main.async {
                    self.closePanel(animated: true)
                }
            }
        }
    }
    
    private func stopClickOutsideMonitor() {
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
        }
    }
    
    // MARK: - NSWindowDelegate
    
    func windowDidResignKey(_ notification: Notification) {
        // If lost focus to another app, smoothly close
        if isVisible && !isAnimating {
            closePanel(animated: true)
        }
    }
}
