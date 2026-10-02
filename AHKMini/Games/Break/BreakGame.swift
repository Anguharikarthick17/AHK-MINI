import SpriteKit
import AppKit

/// AHK Break — Minimal vector breakout game.
/// Player controls a bottom paddle deflecting a ball into destructible data blocks.
final class BreakGame: MiniGame {
    let gameType: GameType = .breakOut
    let rootNode: SKNode = SKNode()
    
    private(set) var state: GameState = .idle
    private(set) var currentScore: Int = 0
    private(set) var highScore: Int = 0
    
    var onScoreChanged: ((Int) -> Void)?
    var onHighScoreChanged: ((Int) -> Void)?
    var onStateChanged: ((GameState) -> Void)?
    
    private let sceneSize: CGSize
    private var paddleNode: SKShapeNode!
    private var ballNode: SKShapeNode!
    private var blockNodes: [SKShapeNode] = []
    
    private var paddleX: CGFloat = 210.0
    private let paddleY: CGFloat = 16.0
    private let paddleWidth: CGFloat = 58.0
    private let paddleHeight: CGFloat = 8.0
    
    private var ballPos: CGPoint = .zero
    private var ballVel: CGVector = .zero
    private let ballRadius: CGFloat = 4.0
    private var baseBallSpeed: CGFloat = 210.0
    private var currentLevel: Int = 1
    
    init(size: CGSize) {
        self.sceneSize = size
        self.highScore = ScoreStore.shared.highScore(for: .breakOut)
        setupElements()
    }
    
    private func setupElements() {
        // Paddle with AHK gold center pip
        let paddlePath = CGPath(roundedRect: CGRect(x: -paddleWidth/2, y: -paddleHeight/2, width: paddleWidth, height: paddleHeight), cornerWidth: 3, cornerHeight: 3, transform: nil)
        paddleNode = SKShapeNode(path: paddlePath)
        paddleNode.fillColor = NSColor(white: 0.95, alpha: 1.0)
        paddleNode.strokeColor = .clear
        paddleNode.position = CGPoint(x: paddleX, y: paddleY)
        paddleNode.zPosition = 10
        rootNode.addChild(paddleNode)
        
        let pip = SKShapeNode(circleOfRadius: 2.0)
        pip.fillColor = NSColor(red: 1.0, green: 0.81, blue: 0.0, alpha: 1.0)
        pip.strokeColor = .clear
        paddleNode.addChild(pip)
        
        // Ball
        ballNode = SKShapeNode(circleOfRadius: ballRadius)
        ballNode.fillColor = NSColor(red: 1.0, green: 0.81, blue: 0.0, alpha: 1.0)
        ballNode.strokeColor = .clear
        ballNode.zPosition = 10
        rootNode.addChild(ballNode)
    }
    
    func start() {
        restart()
    }
    
    func restart() {
        currentLevel = 1
        currentScore = 0
        state = .running
        highScore = ScoreStore.shared.highScore(for: .breakOut)
        
        paddleX = sceneSize.width / 2.0
        paddleNode.position.x = paddleX
        
        buildBlockGrid()
        resetBall()
        
        onStateChanged?(.running)
        onScoreChanged?(0)
        onHighScoreChanged?(highScore)
    }
    
    private func buildBlockGrid() {
        for b in blockNodes { b.removeFromParent() }
        blockNodes.removeAll()
        
        let cols = 10
        let rows = 3
        let blockW: CGFloat = 34.0
        let blockH: CGFloat = 10.0
        let spacingX: CGFloat = 6.0
        let spacingY: CGFloat = 5.0
        
        let totalW = CGFloat(cols) * blockW + CGFloat(cols - 1) * spacingX
        let startX = (sceneSize.width - totalW) / 2.0 + blockW / 2.0
        let startY = sceneSize.height - 24.0
        
        for r in 0..<rows {
            let y = startY - CGFloat(r) * (blockH + spacingY)
            for c in 0..<cols {
                let x = startX + CGFloat(c) * (blockW + spacingX)
                let bPath = CGPath(roundedRect: CGRect(x: -blockW/2, y: -blockH/2, width: blockW, height: blockH), cornerWidth: 2, cornerHeight: 2, transform: nil)
                let block = SKShapeNode(path: bPath)
                if r == 0 {
                    block.fillColor = NSColor(red: 1.0, green: 0.81, blue: 0.0, alpha: 0.9) // Top row AHK gold
                } else if r == 1 {
                    block.fillColor = NSColor(white: 0.85, alpha: 1.0)
                } else {
                    block.fillColor = NSColor(white: 0.65, alpha: 1.0)
                }
                block.strokeColor = NSColor(white: 0.2, alpha: 0.5)
                block.lineWidth = 1.0
                block.position = CGPoint(x: x, y: y)
                block.zPosition = 5
                rootNode.addChild(block)
                blockNodes.append(block)
            }
        }
    }
    
    private func resetBall() {
        ballPos = CGPoint(x: paddleX, y: paddleY + 14.0)
        ballNode.position = ballPos
        
        let speed = baseBallSpeed + CGFloat(currentLevel - 1) * 25.0
        let angle = CGFloat.random(in: (CGFloat.pi * 0.3)...(CGFloat.pi * 0.7))
        ballVel = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)
    }
    
    func update(deltaTime: TimeInterval) {
        guard state == .running else { return }
        let dt = CGFloat(deltaTime)
        
        ballPos.x += ballVel.dx * dt
        ballPos.y += ballVel.dy * dt
        
        // Wall collisions
        if ballPos.x - ballRadius <= 8.0 {
            ballPos.x = 8.0 + ballRadius
            ballVel.dx = abs(ballVel.dx)
        } else if ballPos.x + ballRadius >= sceneSize.width - 8.0 {
            ballPos.x = sceneSize.width - 8.0 - ballRadius
            ballVel.dx = -abs(ballVel.dx)
        }
        
        if ballPos.y + ballRadius >= sceneSize.height - 8.0 {
            ballPos.y = sceneSize.height - 8.0 - ballRadius
            ballVel.dy = -abs(ballVel.dy)
        }
        
        // Paddle collision
        let paddleTop = paddleY + paddleHeight / 2.0
        if ballPos.y - ballRadius <= paddleTop && ballPos.y + ballRadius >= paddleY - paddleHeight / 2.0 {
            if ballPos.x >= paddleX - paddleWidth / 2.0 - 4 && ballPos.x <= paddleX + paddleWidth / 2.0 + 4 {
                ballPos.y = paddleTop + ballRadius
                // Influence bounce angle by where ball hits paddle
                let hitOffset = (ballPos.x - paddleX) / (paddleWidth / 2.0)
                let currentSpeed = sqrt(ballVel.dx * ballVel.dx + ballVel.dy * ballVel.dy)
                let maxAngle: CGFloat = CGFloat.pi * 0.4
                let newAngle = (CGFloat.pi / 2.0) - (hitOffset * maxAngle)
                ballVel.dx = cos(newAngle) * currentSpeed
                ballVel.dy = abs(sin(newAngle) * currentSpeed)
            }
        }
        
        // Block collisions
        var remainingBlocks: [SKShapeNode] = []
        for block in blockNodes {
            let bBox = CGRect(x: block.position.x - 17, y: block.position.y - 5, width: 34, height: 10)
            let ballBox = CGRect(x: ballPos.x - ballRadius, y: ballPos.y - ballRadius, width: ballRadius * 2, height: ballRadius * 2)
            if bBox.intersects(ballBox) {
                block.removeFromParent()
                ballVel.dy = -ballVel.dy
                currentScore += 10
                onScoreChanged?(currentScore)
                if currentScore > highScore {
                    highScore = currentScore
                    onHighScoreChanged?(highScore)
                }
            } else {
                remainingBlocks.append(block)
            }
        }
        blockNodes = remainingBlocks
        
        // Level complete: respawn blocks with higher speed
        if blockNodes.isEmpty {
            currentLevel += 1
            buildBlockGrid()
            resetBall()
        }
        
        // Bottom boundary check
        if ballPos.y < -10 {
            triggerGameOver()
        }
        
        ballNode.position = ballPos
        paddleNode.position.x = paddleX
    }
    
    private func triggerGameOver() {
        guard state == .running else { return }
        state = .gameOver
        ScoreStore.shared.record(score: currentScore, for: .breakOut)
        highScore = ScoreStore.shared.highScore(for: .breakOut)
        onStateChanged?(.gameOver)
    }
    
    func handleKeyDown(event: NSEvent) -> Bool {
        let keyCode = event.keyCode
        // Left (123, A: 0), Right (124, D: 2), Space (49)
        if keyCode == 123 || keyCode == 0 {
            if state != .running { restart(); return true }
            paddleX = max(paddleWidth / 2.0 + 8.0, paddleX - 28.0)
            return true
        } else if keyCode == 124 || keyCode == 2 {
            if state != .running { restart(); return true }
            paddleX = min(sceneSize.width - paddleWidth / 2.0 - 8.0, paddleX + 28.0)
            return true
        } else if keyCode == 49 {
            if state == .idle || state == .gameOver {
                restart()
            }
            return true
        } else if keyCode == 53 {
            if state == .running { pause() } else if state == .paused { resume() }
            return true
        }
        return false
    }
    
    func handleMouseDown(at point: CGPoint) -> Bool {
        if state != .running {
            restart()
            return true
        }
        paddleX = max(paddleWidth / 2.0 + 8.0, min(sceneSize.width - paddleWidth / 2.0 - 8.0, point.x))
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
        for b in blockNodes { b.removeFromParent() }
        blockNodes.removeAll()
        rootNode.removeAllChildren()
    }
}
