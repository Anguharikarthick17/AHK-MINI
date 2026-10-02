import SpriteKit
import AppKit

/// AHK Space — Lightweight space dodging game.
/// Player maneuvers a vector star-skiff vertically through incoming asteroid fields.
final class SpaceGame: MiniGame {
    let gameType: GameType = .space
    let rootNode: SKNode = SKNode()
    
    private(set) var state: GameState = .idle
    private(set) var currentScore: Int = 0
    private(set) var highScore: Int = 0
    
    var onScoreChanged: ((Int) -> Void)?
    var onHighScoreChanged: ((Int) -> Void)?
    var onStateChanged: ((GameState) -> Void)?
    
    private let sceneSize: CGSize
    private var shipNode: SKShapeNode!
    private var thrusterNode: SKShapeNode!
    private var asteroids: [SKShapeNode] = []
    private var starNodes: [SKShapeNode] = []
    
    private var shipY: CGFloat = 70.0
    private var targetShipY: CGFloat = 70.0
    private var shipVelocityY: CGFloat = 0.0
    
    private var survivalTime: TimeInterval = 0.0
    private var spawnTimer: TimeInterval = 0.0
    private var baseSpeed: CGFloat = 200.0
    private var currentSpeed: CGFloat = 200.0
    
    init(size: CGSize) {
        self.sceneSize = size
        self.highScore = ScoreStore.shared.highScore(for: .space)
        setupWorld()
    }
    
    private func setupWorld() {
        // Distant space dust stars
        for _ in 0..<18 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.6...1.2))
            star.fillColor = NSColor(white: 0.35, alpha: 0.6)
            star.strokeColor = .clear
            star.position = CGPoint(
                x: CGFloat.random(in: 0...sceneSize.width),
                y: CGFloat.random(in: 10...(sceneSize.height - 10))
            )
            rootNode.addChild(star)
            starNodes.append(star)
        }
        
        // Player Ship: Sleek vector arrowhead with AHK yellow thruster
        let shipPath = CGMutablePath()
        shipPath.move(to: CGPoint(x: 14, y: 0))
        shipPath.addLine(to: CGPoint(x: -10, y: 8))
        shipPath.addLine(to: CGPoint(x: -5, y: 0))
        shipPath.addLine(to: CGPoint(x: -10, y: -8))
        shipPath.closeSubpath()
        
        shipNode = SKShapeNode(path: shipPath)
        shipNode.fillColor = NSColor(white: 0.95, alpha: 1.0)
        shipNode.strokeColor = .clear
        shipNode.position = CGPoint(x: 54.0, y: shipY)
        shipNode.zPosition = 10
        rootNode.addChild(shipNode)
        
        // AHK signature yellow thruster
        let thrustPath = CGMutablePath()
        thrustPath.move(to: CGPoint(x: -6, y: 3))
        thrustPath.addLine(to: CGPoint(x: -12, y: 0))
        thrustPath.addLine(to: CGPoint(x: -6, y: -3))
        thrustPath.closeSubpath()
        
        thrusterNode = SKShapeNode(path: thrustPath)
        thrusterNode.fillColor = NSColor(red: 1.0, green: 0.81, blue: 0.0, alpha: 1.0)
        thrusterNode.strokeColor = .clear
        thrusterNode.position = .zero
        shipNode.addChild(thrusterNode)
    }
    
    func start() {
        restart()
    }
    
    func restart() {
        for a in asteroids {
            a.removeFromParent()
        }
        asteroids.removeAll()
        
        state = .running
        currentScore = 0
        survivalTime = 0.0
        spawnTimer = 0.0
        currentSpeed = baseSpeed
        shipY = sceneSize.height / 2.0
        targetShipY = shipY
        shipVelocityY = 0.0
        shipNode.position = CGPoint(x: 54.0, y: shipY)
        shipNode.zRotation = 0.0
        shipNode.fillColor = NSColor(white: 0.95, alpha: 1.0)
        highScore = ScoreStore.shared.highScore(for: .space)
        
        onStateChanged?(.running)
        onScoreChanged?(0)
        onHighScoreChanged?(highScore)
    }
    
    func update(deltaTime: TimeInterval) {
        guard state == .running else { return }
        
        survivalTime += deltaTime
        currentSpeed = min(baseSpeed + CGFloat(survivalTime) * 8.0, 500.0)
        
        let newScore = Int(survivalTime * 15.0)
        if newScore != currentScore {
            currentScore = newScore
            onScoreChanged?(currentScore)
            if currentScore > highScore {
                highScore = currentScore
                onHighScoreChanged?(highScore)
            }
        }
        
        // Smooth ship vertical movement towards target
        let dy = targetShipY - shipY
        shipY += dy * min(1.0, CGFloat(deltaTime) * 14.0)
        shipY = max(16.0, min(sceneSize.height - 16.0, shipY))
        shipNode.position.y = shipY
        shipNode.zRotation = (dy / 40.0) * 0.2
        
        // Animate thruster flicker
        thrusterNode.xScale = CGFloat.random(in: 0.7...1.3)
        
        // Parallax stars
        for star in starNodes {
            star.position.x -= (currentSpeed * 0.25) * CGFloat(deltaTime)
            if star.position.x < 0 {
                star.position.x += sceneSize.width
                star.position.y = CGFloat.random(in: 10...(sceneSize.height - 10))
            }
        }
        
        // Asteroid movement & spawning
        updateAsteroids(deltaTime: deltaTime)
        checkCollisions()
    }
    
    private func updateAsteroids(deltaTime: TimeInterval) {
        let moveDist = currentSpeed * CGFloat(deltaTime)
        var remaining: [SKShapeNode] = []
        for ast in asteroids {
            ast.position.x -= moveDist
            ast.zRotation += CGFloat(deltaTime) * 2.0
            if ast.position.x < -30 {
                ast.removeFromParent()
            } else {
                remaining.append(ast)
            }
        }
        asteroids = remaining
        
        spawnTimer += deltaTime
        let spawnInterval = max(0.45, 1.2 - (survivalTime * 0.02))
        if spawnTimer >= spawnInterval {
            spawnTimer = 0.0
            spawnAsteroid()
        }
    }
    
    private func spawnAsteroid() {
        let radius = CGFloat.random(in: 7.0...14.0)
        let path = CGMutablePath()
        let points = 7
        for i in 0..<points {
            let angle = (CGFloat(i) / CGFloat(points)) * CGFloat.pi * 2.0
            let r = radius * CGFloat.random(in: 0.75...1.15)
            let pt = CGPoint(x: cos(angle) * r, y: sin(angle) * r)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        
        let ast = SKShapeNode(path: path)
        ast.fillColor = NSColor(white: 0.78, alpha: 1.0)
        ast.strokeColor = NSColor(white: 0.4, alpha: 0.6)
        ast.lineWidth = 1.0
        ast.position = CGPoint(
            x: sceneSize.width + 25.0,
            y: CGFloat.random(in: 18...(sceneSize.height - 18))
        )
        ast.zPosition = 5
        rootNode.addChild(ast)
        asteroids.append(ast)
    }
    
    private func checkCollisions() {
        let shipRect = CGRect(x: shipNode.position.x - 8, y: shipNode.position.y - 6, width: 18, height: 12)
        for ast in asteroids {
            let astRect = CGRect(x: ast.position.x - 7, y: ast.position.y - 7, width: 14, height: 14)
            if shipRect.intersects(astRect) {
                triggerGameOver()
                break
            }
        }
    }
    
    private func triggerGameOver() {
        guard state == .running else { return }
        state = .gameOver
        ScoreStore.shared.record(score: currentScore, for: .space)
        highScore = ScoreStore.shared.highScore(for: .space)
        shipNode.fillColor = NSColor(red: 0.95, green: 0.3, blue: 0.3, alpha: 1.0)
        shipNode.run(SKAction.rotate(byAngle: 1.5, duration: 0.2))
        onStateChanged?(.gameOver)
    }
    
    func handleKeyDown(event: NSEvent) -> Bool {
        let keyCode = event.keyCode
        // Up (126, W: 13), Down (125, S: 1), Space (49)
        if keyCode == 126 || keyCode == 13 {
            targetShipY = min(sceneSize.height - 16.0, targetShipY + 28.0)
            if state != .running { restart() }
            return true
        } else if keyCode == 125 || keyCode == 1 {
            targetShipY = max(16.0, targetShipY - 28.0)
            if state != .running { restart() }
            return true
        } else if keyCode == 49 {
            if state == .idle || state == .gameOver {
                restart()
            }
            return true
        } else if keyCode == 53 { // ESC
            if state == .running { pause() } else if state == .paused { resume() }
            return true
        }
        return false
    }
    
    func handleMouseDown(at point: CGPoint) -> Bool {
        if state == .idle || state == .gameOver {
            restart()
            return true
        }
        targetShipY = point.y
        return true
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
        for a in asteroids { a.removeFromParent() }
        asteroids.removeAll()
        rootNode.removeAllChildren()
    }
}
