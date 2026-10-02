import SpriteKit
import AppKit

/// Unified SpriteKit container scene for AHK Mini Arcade.
/// Hosts the ArcadeManager, enforces 60 FPS cap, and halts calculations when idle or hidden.
final class MiniGameScene: SKScene {
    
    static let sceneSize = CGSize(width: 420.0, height: 140.0)
    private(set) var arcadeManager: ArcadeManager!
    private var lastUpdateTime: TimeInterval = 0.0
    
    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = NSColor(red: 0.055, green: 0.055, blue: 0.063, alpha: 1.0) // #0E0E10
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        removeAllChildren()
        arcadeManager = ArcadeManager(scene: self, size: size)
    }
    
    override func keyDown(with event: NSEvent) {
        _ = arcadeManager.handleKeyDown(event: event)
    }
    
    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        _ = arcadeManager.handleMouseDown(at: location)
    }
    
    func pauseGame() {
        arcadeManager.pause()
        isPaused = true
    }
    
    func resumeGame() {
        isPaused = false
        lastUpdateTime = 0.0
        arcadeManager.resume()
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Extreme battery conservation: if paused or in selector mode, abort immediately
        guard !isPaused, arcadeManager.mode == .inGame else { return }
        
        if lastUpdateTime == 0.0 {
            lastUpdateTime = currentTime
            return
        }
        
        var dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        // Clamp deltaTime
        if dt > 0.033 { dt = 0.033 }
        
        arcadeManager.update(deltaTime: dt)
    }
}
