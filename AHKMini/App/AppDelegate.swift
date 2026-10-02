import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var statusItem: NSStatusItem!
    private var windowController: MiniWindowController!
    private var contextMenu: NSMenu!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupContextMenu()
        windowController = MiniWindowController()
        windowController.onVisibilityChanged = { [weak self] isShowing in
            self?.statusItem.button?.image = self?.makeMenuBarIcon(showing: isShowing)
        }
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem.button else { return }
        
        button.image = makeMenuBarIcon()
        button.imagePosition = .imageOnly
        button.toolTip = "AHK Mini — Multi-Game Arcade"
        button.target = self
        button.action = #selector(statusItemClicked(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }
    
    private func setupContextMenu() {
        contextMenu = NSMenu()
        
        let titleItem = NSMenuItem(title: "AHK Mini Arcade", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        contextMenu.addItem(titleItem)
        contextMenu.addItem(NSMenuItem.separator())
        
        let resetItem = NSMenuItem(title: "Reset All High Scores", action: #selector(resetHighScore), keyEquivalent: "")
        resetItem.target = self
        contextMenu.addItem(resetItem)
        
        contextMenu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit AHK Mini", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        contextMenu.addItem(quitItem)
    }
    
    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        // If right-clicked or control-clicked, display the contextual menu
        if let currentEvent = NSApp.currentEvent,
           (currentEvent.type == .rightMouseUp || currentEvent.modifierFlags.contains(.control)) {
            statusItem.menu = contextMenu
            statusItem.button?.performClick(nil)
            // Detach immediately so future left-clicks continue to toggle the game
            DispatchQueue.main.async { [weak self] in
                self?.statusItem.menu = nil
            }
            return
        }
        
        // Default: left click (or programmatic action) toggles the AHK Mini arcade window
        windowController.toggle(relativeTo: sender)
    }
    
    @objc private func resetHighScore() {
        ScoreStore.shared.resetAll()
        windowController.gameScene.arcadeManager.returnToSelector()
    }
    
    @objc private func quitApp() {
        windowController.closePanel(animated: false)
        NSApp.terminate(nil)
    }
    
    /// Generates a crisp 18x18 Retina vector template icon of the gaming controller,
    /// balanced at medium visual weight (~15.6×10.9pt) to match neighboring macOS menu-bar symbols.
    private func makeMenuBarIcon(showing: Bool = false) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            
            ctx.clear(rect)
            
            let cx: CGFloat = 9.0
            let cy: CGFloat = 8.8
            let w: CGFloat = 15.6
            let h: CGFloat = 11.2
            
            // 1. Controller Body Silhouette (Monochrome Solid)
            let body = CGMutablePath()
            let topDipY = cy + h * 0.35
            let shoulderY = cy + h * 0.44
            let gripTipY = cy - h * 0.48
            let archY = cy - h * 0.10
            let shoulderR = cx + w * 0.32
            let shoulderL = cx - w * 0.32
            let outerGripR = cx + w * 0.49
            let outerGripL = cx - w * 0.49
            let gripTipR = cx + w * 0.30
            let gripTipL = cx - w * 0.30
            let innerGripR = cx + w * 0.17
            let innerGripL = cx - w * 0.17
            
            body.move(to: CGPoint(x: cx, y: topDipY))
            body.addQuadCurve(to: CGPoint(x: shoulderR, y: shoulderY), control: CGPoint(x: cx + w * 0.18, y: shoulderY + 0.15))
            body.addQuadCurve(to: CGPoint(x: outerGripR, y: cy - h * 0.12), control: CGPoint(x: outerGripR + 0.1, y: cy + h * 0.26))
            body.addQuadCurve(to: CGPoint(x: gripTipR, y: gripTipY), control: CGPoint(x: outerGripR - 0.2, y: gripTipY - 0.2))
            body.addQuadCurve(to: CGPoint(x: cx, y: archY), control: CGPoint(x: innerGripR, y: gripTipY + 0.4))
            body.addQuadCurve(to: CGPoint(x: gripTipL, y: gripTipY), control: CGPoint(x: innerGripL, y: gripTipY + 0.4))
            body.addQuadCurve(to: CGPoint(x: outerGripL, y: cy - h * 0.12), control: CGPoint(x: outerGripL + 0.2, y: gripTipY - 0.2))
            body.addQuadCurve(to: CGPoint(x: shoulderL, y: shoulderY), control: CGPoint(x: outerGripL - 0.1, y: cy + h * 0.26))
            body.addQuadCurve(to: CGPoint(x: cx, y: topDipY), control: CGPoint(x: cx - w * 0.18, y: shoulderY + 0.15))
            body.closeSubpath()
            
            ctx.setFillColor(NSColor.black.cgColor)
            ctx.addPath(body)
            ctx.fillPath()
            
            // 2. Cutout details using BlendMode.clear
            ctx.setBlendMode(.clear)
            
            // Left D-pad cutout
            let dpadCenter = CGPoint(x: cx - 4.4, y: cy + 0.1)
            let dpadW: CGFloat = 3.2
            let dpadThick: CGFloat = 1.3
            ctx.fill(CGRect(x: dpadCenter.x - dpadW/2, y: dpadCenter.y - dpadThick/2, width: dpadW, height: dpadThick))
            ctx.fill(CGRect(x: dpadCenter.x - dpadThick/2, y: dpadCenter.y - dpadW/2, width: dpadThick, height: dpadW))
            
            // Right 4 Action Buttons
            let btnR: CGFloat = 0.60
            let rightCenter = CGPoint(x: cx + 4.4, y: cy + 0.1)
            let delta: CGFloat = 1.45
            for btn in [
                CGPoint(x: rightCenter.x, y: rightCenter.y + delta),
                CGPoint(x: rightCenter.x, y: rightCenter.y - delta),
                CGPoint(x: rightCenter.x - delta, y: rightCenter.y),
                CGPoint(x: rightCenter.x + delta, y: rightCenter.y)
            ] {
                ctx.fillEllipse(in: CGRect(x: btn.x - btnR, y: btn.y - btnR, width: btnR * 2, height: btnR * 2))
            }
            
            // Center Detail (State support):
            // showing == false: simpler / open controller detail (clean open aperture)
            // showing == true:  slightly stronger / filled controller center detail (solid filled center dot with fine trench)
            let centerPoint = CGPoint(x: cx, y: cy + 0.2)
            if showing {
                ctx.setLineWidth(0.65)
                ctx.strokeEllipse(in: CGRect(x: centerPoint.x - 1.4, y: centerPoint.y - 1.4, width: 2.8, height: 2.8))
                ctx.setBlendMode(.normal)
                ctx.setFillColor(NSColor.black.cgColor)
                ctx.fillEllipse(in: CGRect(x: centerPoint.x - 0.8, y: centerPoint.y - 0.8, width: 1.6, height: 1.6))
            } else {
                ctx.fillEllipse(in: CGRect(x: centerPoint.x - 0.95, y: centerPoint.y - 0.95, width: 1.9, height: 1.9))
            }
            
            return true
        }
        image.isTemplate = true
        return image
    }
}
