import SpriteKit
import AppKit

/// AHK Runner — Original endless runner mini-game.
/// Faithfully preserves the existing jump mechanics, procedural animations, and obstacle collisions.
final class RunnerGame: MiniGame {
    let gameType: GameType = .runner
    let rootNode: SKNode = SKNode()
    
    private(set) var state: GameState = .idle
    private(set) var currentScore: Int = 0
    private(set) var highScore: Int = 0
    
    var onScoreChanged: ((Int) -> Void)?
    var onHighScoreChanged: ((Int) -> Void)?
    var onStateChanged: ((GameState) -> Void)?
    
    private let sceneSize: CGSize
    private let groundY: CGFloat = 24.0
    private let playerStartX: CGFloat = 56.0
    
    private var groundNode: GroundNode!
    private var playerNode: PlayerNode!
    private var obstacles: [ObstacleNode] = []
    
    // Speed progression configuration
    let baseSpeed: CGFloat = 240.0
    let maxSpeed: CGFloat = 540.0
    let speedRampRate: CGFloat = 4.0
    
    private var currentSpeed: CGFloat = 240.0
    private var distanceTraveled: CGFloat = 0.0
    private var timeInRun: TimeInterval = 0.0
    private var nextObstacleDistance: CGFloat = 260.0
    private var distanceSinceLastObstacle: CGFloat = 0.0
    
    init(size: CGSize) {
        self.sceneSize = size
        self.highScore = ScoreStore.shared.highScore(for: .runner)
        setupNodes()
    }
    
    private func setupNodes() {
        groundNode = GroundNode(sceneWidth: sceneSize.width, groundY: groundY)
        rootNode.addChild(groundNode)
        
        playerNode = PlayerNode()
        playerNode.position = CGPoint(x: playerStartX, y: groundY)
        rootNode.addChild(playerNode)
    }
    
    func start() {
        restart()
    }
    
    func restart() {
        // Clear active obstacles
        for obs in obstacles {
            obs.removeFromParent()
        }
        obstacles.removeAll()
        
        state = .running
        currentScore = 0
        distanceTraveled = 0.0
        timeInRun = 0.0
        currentSpeed = baseSpeed
        distanceSinceLastObstacle = 0.0
        nextObstacleDistance = CGFloat.random(in: 220...320)
        highScore = ScoreStore.shared.highScore(for: .runner)
        
        groundNode.reset()
        playerNode.reset(at: groundY)
        _ = playerNode.jump()
        
        onStateChanged?(.running)
        onScoreChanged?(0)
        onHighScoreChanged?(highScore)
    }
    
    func update(deltaTime: TimeInterval) {
        guard state == .running else { return }
        
        timeInRun += deltaTime
        currentSpeed = min(baseSpeed + CGFloat(timeInRun) * speedRampRate, maxSpeed)
        
        let moveDistance = currentSpeed * CGFloat(deltaTime)
        distanceTraveled += moveDistance
        
        let newScore = Int(distanceTraveled / 12.0)
        if newScore != currentScore {
            currentScore = newScore
            onScoreChanged?(currentScore)
            
            if currentScore > highScore {
                highScore = currentScore
                onHighScoreChanged?(highScore)
            }
        }
        
        groundNode.update(deltaTime: deltaTime, speed: currentSpeed)
        playerNode.update(deltaTime: deltaTime, speed: currentSpeed, groundY: groundY)
        
        updateObstacles(deltaTime: deltaTime, speed: currentSpeed)
        checkCollisions()
    }
    
    private func updateObstacles(deltaTime: TimeInterval, speed: CGFloat) {
        let moveDistance = speed * CGFloat(deltaTime)
        
        var remaining: [ObstacleNode] = []
        for obstacle in obstacles {
            obstacle.position.x -= moveDistance
            if obstacle.position.x < -50.0 {
                obstacle.removeFromParent()
            } else {
                remaining.append(obstacle)
            }
        }
        obstacles = remaining
        
        distanceSinceLastObstacle += moveDistance
        if distanceSinceLastObstacle >= nextObstacleDistance {
            spawnObstacle()
            distanceSinceLastObstacle = 0.0
            
            let speedRatio = (speed - baseSpeed) / (maxSpeed - baseSpeed)
            let minGap: CGFloat = 200.0 + (speedRatio * 80.0)
            let maxGap: CGFloat = 340.0 + (speedRatio * 100.0)
            nextObstacleDistance = CGFloat.random(in: minGap...maxGap)
        }
    }
    
    private func spawnObstacle() {
        var availableTypes: [ObstacleType] = [.smallPillar, .twinPillars, .spikeWedge, .lowBarrier]
        if currentScore >= 180 {
            availableTypes.append(.aerialDrone)
        }
        
        guard let chosenType = availableTypes.randomElement() else { return }
        let obstacle = ObstacleNode(type: chosenType)
        
        let spawnX = sceneSize.width + 30.0
        let spawnY: CGFloat
        if chosenType == .aerialDrone {
            spawnY = groundY + CGFloat.random(in: 28...38)
        } else {
            spawnY = groundY
        }
        
        obstacle.position = CGPoint(x: spawnX, y: spawnY)
        obstacle.zPosition = 10
        rootNode.addChild(obstacle)
        obstacles.append(obstacle)
    }
    
    private func checkCollisions() {
        let playerBox = playerNode.collisionRect
        for obstacle in obstacles {
            if playerBox.intersects(obstacle.collisionRect) {
                triggerGameOver()
                break
            }
        }
    }
    
    private func triggerGameOver() {
        guard state == .running else { return }
        state = .gameOver
        ScoreStore.shared.record(score: currentScore, for: .runner)
        highScore = ScoreStore.shared.highScore(for: .runner)
        playerNode.playDeathAnimation()
        onStateChanged?(.gameOver)
    }
    
    func handleKeyDown(event: NSEvent) -> Bool {
        let keyCode = event.keyCode
        // Space (49), Up Arrow (126), W (13)
        if keyCode == 49 || keyCode == 126 || keyCode == 13 {
            handleAction()
            return true
        } else if keyCode == 53 { // ESC
            if state == .running {
                pause()
            } else if state == .paused {
                resume()
            }
            return true
        }
        return false
    }
    
    func handleMouseDown(at point: CGPoint) -> Bool {
        handleAction()
        return true
    }
    
    private func handleAction() {
        switch state {
        case .idle, .gameOver:
            restart()
        case .running:
            _ = playerNode.jump()
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
        for obs in obstacles {
            obs.removeFromParent()
        }
        obstacles.removeAll()
        rootNode.removeAllChildren()
    }
}
