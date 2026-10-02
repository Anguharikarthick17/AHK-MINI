import AppKit

/// Borderless, non-activating floating panel configured to reliably accept keyboard focus.
final class MiniPanel: NSPanel {
    
    var onKeyDown: ((NSEvent) -> Void)?
    
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        isFloatingPanel = true
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
    }
    
    // Critical overrides so a borderless window receives keyboard events (Space, Arrows)
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
    
    override func keyDown(with event: NSEvent) {
        if let onKeyDown = onKeyDown {
            onKeyDown(event)
        } else {
            super.keyDown(with: event)
        }
    }
}
