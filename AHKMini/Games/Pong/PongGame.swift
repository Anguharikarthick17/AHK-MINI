import SpriteKit
import AppKit

/// AHK Pong — Retro head-to-head table tennis.
/// Player battles a CPU paddle across a minimal vector court with accelerating rallies.
final class PongGame: MiniGame {
    let gameType: GameType = .pong
    let rootNode: SKNode = SKNode()
    
    private(set) var state: GameState = .idle
    private(set) var currentScore: Int = 0
    private(set) var highScore: Int = 0
    
    var onScoreChanged: ((Int) -> Void)?
    var onHighScoreChanged: ((Int) -> Void)?
    var onStateChanged: ((GameState) -> Void)?
    
    private let sceneSize: CGSize
    private var playerPaddle: SKShapeNode!
    private var cpuPaddle: SKShapeNode!
    private var ballNode: SKShapeNode!
    private var netLine: SKShapeNode!
    
    private let paddleWidth: CGFloat = 6.0
    private let paddleHeight: CGFloat = 34.0
    private var playerY: CGFloat = 70.0
    private var targetPlayerY: CGFloat = 70.0
    private var cpuY: CGFloat = 70.0
    
    private var ballPos: CGPoint = .zero
    private var ballVel: CGVector = .zero
    private let ballRadius: CGFloat = 3.5
    private var ballSpeed: CGFloat = 220.0
    private var rallyCount: Int = 0
    
    init(size: CGSize) {
        self.sceneSize = size
        self.highScore = ScoreStore.shared.highScore(for: .pong)
        setupCourt()
    }
    
    private func setupCourt() {
        // Center dashed net
        let netPath = CGMutablePath()
        var y: CGFloat = 8.0
        while y < sceneSize.height - 8.0 {
            netPath.addRect(CGRect(x: sceneSize.width / 2.0 - 0.5, y: y, width: 1.0, height: 6.0))
            y += 12.0
        }
        netLine = SKShapeNode(path: netPath)
        netLine.fillColor = NSColor(white: 0.25, alpha: 0.7)
        netLine.strokeColor = .clear
        rootNode.addChild(netLine)
        
        // Player Paddle (Left, x = 20) with AHK gold edge
        let pPath = CGPath(roundedRect: CGRect(x: -paddleWidth/2, y: -paddleHeight/2, width: paddleWidth, height: paddleHeight), cornerWidth: 2, cornerHeight: 2, transform: nil)
        playerPaddle = SKShapeNode(path: pPath)
        playerPaddle.fillColor = NSColor(red: 1.0, green: 0.81, blue: 0.0, alpha: 1.0)
        playerPaddle.strokeColor = .clear
        playerPaddle.position = CGPoint(x: 20.0, y: playerY)
        playerPaddle.zPosition = 8
        rootNode.addChild(playerPaddle)
        
        // CPU Paddle (Right, x = width - 20)
        cpuPaddle = SKShapeNode(path: pPath)
        cpuPaddle.fillColor = NSColor(white: 0.82, alpha: 1.0)
        cpuPaddle.strokeColor = .clear
        cpuPaddle.position = CGPoint(x: sceneSize.width - 20.0, y: cpuY)
        cpuPaddle.zPosition = 8
        rootNode.addChild(cpuPaddle)
        
        // Ball
        ballNode = SKShapeNode(circleOfRadius: ballRadius)
        ballNode.fillColor = NSColor(white: 0.96, alpha: 1.0)
        ballNode.strokeColor = .clear
        ballNode.zPosition = 10
        rootNode.addChild(ballNode)
    }
    
    func start() {
        restart()
    }
    
    func restart() {
        state = .running
        currentScore = 0
        rallyCount = 0
        ballSpeed = 220.0
        playerY = sceneSize.height / 2.0
        targetPlayerY = playerY
        cpuY = sceneSize.height / 2.0
        highScore = ScoreStore.shared.highScore(for: .pong)
        
        resetBall(towardPlayer: false)
        
        onStateChanged?(.running)
        onScoreChanged?(0)
        onHighScoreChanged?(highScore)
    }
    
    private func resetBall(towardPlayer: Bool) {
        ballPos = CGPoint(x: sceneSize.width / 2.0, y: sceneSize.height / 2.0)
        let angle = CGFloat.random(in: -0.4...0.4)
        let dirX: CGFloat = towardPlayer ? -1.0 : 1.0
        ballVel = CGVector(dx: cos(angle) * ballSpeed * dirX, dy: sin(angle) * ballSpeed)
        ballNode.position = ballPos
    }
    
    func update(deltaTime: TimeInterval) {
        guard state == .running else { return }
        let dt = CGFloat(deltaTime)
        
        // Smooth player paddle tracking
        playerY += (targetPlayerY - playerY) * min(1.0, dt * 18.0)
        playerY = max(paddleHeight / 2.0 + 6.0, min(sceneSize.height - paddleHeight / 2.0 - 6.0, playerY))
        playerPaddle.position.y = playerY
        
        // CPU AI tracking ball with slight reaction latency
        let cpuTrackingSpeed: CGFloat = min(170.0 + CGFloat(rallyCount) * 12.0, 310.0)
        let cpuTarget = ballPos.y
        let cpuDiff = cpuTarget - cpuY
        if abs(cpuDiff) > 4.0 {
            cpuY += (cpuDiff > 0 ? 1 : -1) * cpuTrackingSpeed * dt
        }
        cpuY = max(paddleHeight / 2.0 + 6.0, min(sceneSize.height - paddleHeight / 2.0 - 6.0, cpuY))
        cpuPaddle.position.y = cpuY
        
        // Ball movement
        ballPos.x += ballVel.dx * dt
        ballPos.y += ballVel.dy * dt
        
        // Top/Bottom bounce
        if ballPos.y + ballRadius >= sceneSize.height - 4.0 {
            ballPos.y = sceneSize.height - 4.0 - ballRadius
            ballVel.dy = -abs(ballVel.dy)
        } else if ballPos.y - ballRadius <= 4.0 {
            ballPos.y = 4.0 + ballRadius
            ballVel.dy = abs(ballVel.dy)
        }
        
        // Player paddle bounce (Left)
        if ballPos.x - ballRadius <= 20.0 + paddleWidth/2.0 && ballPos.x + ballRadius >= 20.0 - paddleWidth/2.0 {
            if abs(ballPos.y - playerY) <= paddleHeight / 2.0 + 4.0 {
                ballPos.x = 20.0 + paddleWidth/2.0 + ballRadius
                let hitOffset = (ballPos.y - playerY) / (paddleHeight / 2.0)
                let currentSpeed = min(ballSpeed + CGFloat(rallyCount) * 8.0, 520.0)
                let newAngle = hitOffset * (CGFloat.pi * 0.35)
                ballVel.dx = abs(cos(newAngle) * currentSpeed)
                ballVel.dy = sin(newAngle) * currentSpeed
                
                rallyCount += 1
                currentScore += 1
                onScoreChanged?(currentScore)
                if currentScore > highScore {
                    highScore = currentScore
                    onHighScoreChanged?(highScore)
                }
            }
        }
        
        // CPU paddle bounce (Right)
        if ballPos.x + ballRadius >= sceneSize.width - 20.0 - paddleWidth/2.0 && ballPos.x - ballRadius <= sceneSize.width - 20.0 + paddleWidth/2.0 {
            if abs(ballPos.y - cpuY) <= paddleHeight / 2.0 + 4.0 {
                ballPos.x = sceneSize.width - 20.0 - paddleWidth/2.0 - ballRadius
                let hitOffset = (ballPos.y - cpuY) / (paddleHeight / 2.0)
                let currentSpeed = min(ballSpeed + CGFloat(rallyCount) * 8.0, 520.0)
                let newAngle = hitOffset * (CGFloat.pi * 0.35)
                ballVel.dx = -abs(cos(newAngle) * currentSpeed)
                ballVel.dy = sin(newAngle) * currentSpeed
            }
        }
        
        // Point scoring
        if ballPos.x > sceneSize.width + 15.0 {
            // CPU missed: Player scores bonus!
            currentScore += 5
            onScoreChanged?(currentScore)
            if currentScore > highScore {
                highScore = currentScore
                onHighScoreChanged?(highScore)
            }
            resetBall(towardPlayer: true)
        } else if ballPos.x < -15.0 {
            // Player missed: Game Over
            triggerGameOver()
        }
        
        ballNode.position = ballPos
    }
    
    private func triggerGameOver() {
        guard state == .running else { return }
        state = .gameOver
        ScoreStore.shared.record(score: currentScore, for: .pong)
        highScore = ScoreStore.shared.highScore(for: .pong)
        onStateChanged?(.gameOver)
    }
    
    func handleKeyDown(event: NSEvent) -> Bool {
        let keyCode = event.keyCode
        // Up (126, W: 13), Down (125, S: 1), Space (49)
        if keyCode == 126 || keyCode == 13 {
            if state != .running { restart(); return true }
            targetPlayerY = min(sceneSize.height - paddleHeight / 2.0 - 6.0, targetPlayerY + 28.0)
            return true
        } else if keyCode == 125 || keyCode == 1 {
            if state != .running { restart(); return true }
            targetPlayerY = max(paddleHeight / 2.0 + 6.0, targetPlayerY - 28.0)
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
        targetPlayerY = point.y
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
        rootNode.removeAllChildren()
    }
}
