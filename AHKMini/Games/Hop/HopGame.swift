import SpriteKit
import AppKit

/// AHK Hop — Platform jumping mini-game.
/// Player hops across scrolling platforms of varying heights. Falling causes Game Over.
final class HopGame: MiniGame {
    let gameType: GameType = .hop
    let rootNode: SKNode = SKNode()
    
    private(set) var state: GameState = .idle
    private(set) var currentScore: Int = 0
    private(set) var highScore: Int = 0
    
    var onScoreChanged: ((Int) -> Void)?
    var onHighScoreChanged: ((Int) -> Void)?
    var onStateChanged: ((GameState) -> Void)?
    
    private let sceneSize: CGSize
    private var jumperNode: SKShapeNode!
    private var eyeNode: SKShapeNode!
    private var platforms: [SKShapeNode] = []
    
    private var playerPos: CGPoint = .zero
    private var velocityY: CGFloat = 0.0
    private let gravity: CGFloat = -1100.0
    private let jumpStrength: CGFloat = 380.0
    private var isGrounded: Bool = false
    
    private var scrollSpeed: CGFloat = 180.0
    private var lastPlatformX: CGFloat = 0.0
    private var platformsCleared: Int = 0
    
    init(size: CGSize) {
        self.sceneSize = size
        self.highScore = ScoreStore.shared.highScore(for: .hop)
        setupWorld()
    }
    
    private func setupWorld() {
        // Player: Kinetic jumping cube with AHK yellow visor
        let jumperPath = CGPath(roundedRect: CGRect(x: -9, y: 0, width: 18, height: 20), cornerWidth: 3, cornerHeight: 3, transform: nil)
        jumperNode = SKShapeNode(path: jumperPath)
        jumperNode.fillColor = NSColor(white: 0.95, alpha: 1.0)
        jumperNode.strokeColor = .clear
        jumperNode.zPosition = 10
        rootNode.addChild(jumperNode)
        
        let eyePath = CGPath(rect: CGRect(x: 1, y: 11, width: 6, height: 4), transform: nil)
        eyeNode = SKShapeNode(path: eyePath)
        eyeNode.fillColor = NSColor(red: 1.0, green: 0.81, blue: 0.0, alpha: 1.0)
        eyeNode.strokeColor = .clear
        jumperNode.addChild(eyeNode)
    }
    
    func start() {
        restart()
    }
    
    func restart() {
        for p in platforms { p.removeFromParent() }
        platforms.removeAll()
        
        state = .running
        currentScore = 0
        platformsCleared = 0
        scrollSpeed = 180.0
        highScore = ScoreStore.shared.highScore(for: .hop)
        
        // Spawn initial safe starting platform
        let startPlatform = makePlatform(x: 30, y: 35, width: 140)
        platforms.append(startPlatform)
        lastPlatformX = 170
        
        // Spawn next platforms across the screen
        while lastPlatformX < sceneSize.width + 100 {
            spawnNextPlatform()
        }
        
        playerPos = CGPoint(x: 70, y: 36)
        velocityY = 0.0
        isGrounded = true
        jumperNode.position = playerPos
        jumperNode.zRotation = 0.0
        jumperNode.fillColor = NSColor(white: 0.95, alpha: 1.0)
        
        onStateChanged?(.running)
        onScoreChanged?(0)
        onHighScoreChanged?(highScore)
    }
    
    private func makePlatform(x: CGFloat, y: CGFloat, width: CGFloat) -> SKShapeNode {
        let path = CGPath(roundedRect: CGRect(x: 0, y: 0, width: width, height: 12), cornerWidth: 2, cornerHeight: 2, transform: nil)
        let node = SKShapeNode(path: path)
        node.fillColor = NSColor(white: 0.8, alpha: 1.0)
        node.strokeColor = NSColor(white: 0.35, alpha: 0.7)
        node.lineWidth = 1.0
        node.position = CGPoint(x: x, y: y)
        node.name = "\(width)"
        node.zPosition = 5
        rootNode.addChild(node)
        return node
    }
    
    private func spawnNextPlatform() {
        let gap = CGFloat.random(in: 45...85)
        let platWidth = CGFloat.random(in: 55...95)
        let platY = CGFloat.random(in: 22...65)
        
        let p = makePlatform(x: lastPlatformX + gap, y: platY, width: platWidth)
        platforms.append(p)
        lastPlatformX = p.position.x + platWidth
    }
    
    func update(deltaTime: TimeInterval) {
        guard state == .running else { return }
        
        let dt = CGFloat(deltaTime)
        scrollSpeed = min(180.0 + CGFloat(platformsCleared) * 3.5, 340.0)
        
        // Move platforms left
        let moveX = scrollSpeed * dt
        var remaining: [SKShapeNode] = []
        for p in platforms {
            p.position.x -= moveX
            let pWidth = CGFloat(Double(p.name ?? "60") ?? 60.0)
            if p.position.x + pWidth < -20 {
                p.removeFromParent()
                platformsCleared += 1
                currentScore = platformsCleared
                onScoreChanged?(currentScore)
                if currentScore > highScore {
                    highScore = currentScore
                    onHighScoreChanged?(highScore)
                }
            } else {
                remaining.append(p)
            }
        }
        platforms = remaining
        lastPlatformX -= moveX
        
        // Spawn more platforms if needed
        while lastPlatformX < sceneSize.width + 120 {
            spawnNextPlatform()
        }
        
        // Player Physics
        velocityY += gravity * dt
        playerPos.y += velocityY * dt
        
        // Platform collision (landing from above)
        isGrounded = false
        let playerFootX = playerPos.x
        let playerFootY = playerPos.y
        
        if velocityY <= 0 {
            for p in platforms {
                let pWidth = CGFloat(Double(p.name ?? "60") ?? 60.0)
                let pTop = p.position.y + 12.0
                if playerFootX >= p.position.x - 4 && playerFootX <= p.position.x + pWidth + 4 {
                    if playerFootY <= pTop && playerFootY >= pTop - 12 {
                        playerPos.y = pTop
                        velocityY = 0.0
                        isGrounded = true
                        break
                    }
                }
            }
        }
        
        jumperNode.position = playerPos
        
        // Fall off bottom check
        if playerPos.y < -30 {
            triggerGameOver()
        }
    }
    
    private func triggerGameOver() {
        guard state == .running else { return }
        state = .gameOver
        ScoreStore.shared.record(score: currentScore, for: .hop)
        highScore = ScoreStore.shared.highScore(for: .hop)
        jumperNode.fillColor = NSColor(red: 0.95, green: 0.3, blue: 0.3, alpha: 1.0)
        onStateChanged?(.gameOver)
    }
    
    func handleKeyDown(event: NSEvent) -> Bool {
        let keyCode = event.keyCode
        if keyCode == 49 || keyCode == 126 || keyCode == 13 { // Space / Up / W
            handleHop()
            return true
        } else if keyCode == 53 {
            if state == .running { pause() } else if state == .paused { resume() }
            return true
        }
        return false
    }
    
    func handleMouseDown(at point: CGPoint) -> Bool {
        handleHop()
        return true
    }
    
    private func handleHop() {
        switch state {
        case .idle, .gameOver:
            restart()
        case .running:
            if isGrounded {
                velocityY = jumpStrength
                isGrounded = false
                jumperNode.run(SKAction.sequence([
                    SKAction.scaleY(to: 1.3, duration: 0.08),
                    SKAction.scaleY(to: 1.0, duration: 0.12)
                ]))
            }
        case .paused:
            resume()
        }
    }
    
    func pause() {
        guard state == .running else { return }
        state = .paused
        onStateChanged?(.paused)
    }
    
    func resume() {
        guard state == .paused else { return }
        state = .running
        onStateChanged?(.running)
    }
    
    func teardown() {
        for p in platforms { p.removeFromParent() }
        platforms.removeAll()
        rootNode.removeAllChildren()
    }
}
