import SpriteKit
import AppKit

/// AHK Snake — Minimalist vector grid snake.
/// Navigate a segmented data serpent, collect golden memory tokens, and avoid collisions.
final class SnakeGame: MiniGame {
    let gameType: GameType = .snake
    let rootNode: SKNode = SKNode()
    
    private(set) var state: GameState = .idle
    private(set) var currentScore: Int = 0
    private(set) var highScore: Int = 0
    
    var onScoreChanged: ((Int) -> Void)?
    var onHighScoreChanged: ((Int) -> Void)?
    var onStateChanged: ((GameState) -> Void)?
    
    private let sceneSize: CGSize
    private let cellSize: CGFloat = 10.0
    private let gridCols: Int = 42
    private let gridRows: Int = 14
    
    struct GridPoint: Equatable {
        var x: Int
        var y: Int
    }
    
    private var snake: [GridPoint] = []
    private var direction: GridPoint = GridPoint(x: 1, y: 0)
    private var nextDirection: GridPoint = GridPoint(x: 1, y: 0)
    private var food: GridPoint = GridPoint(x: 20, y: 7)
    
    private var stepTimer: TimeInterval = 0.0
    private var stepInterval: TimeInterval = 0.11
    
    private var segmentNodes: [SKShapeNode] = []
    private var foodNode: SKShapeNode!
    
    init(size: CGSize) {
        self.sceneSize = size
        self.highScore = ScoreStore.shared.highScore(for: .snake)
        setupElements()
    }
    
    private func setupElements() {
        // Food node (AHK yellow rounded diamond)
        let foodPath = CGPath(roundedRect: CGRect(x: 1, y: 1, width: cellSize - 2, height: cellSize - 2), cornerWidth: 2, cornerHeight: 2, transform: nil)
        foodNode = SKShapeNode(path: foodPath)
        foodNode.fillColor = NSColor(red: 1.0, green: 0.81, blue: 0.0, alpha: 1.0)
        foodNode.strokeColor = .clear
        foodNode.zPosition = 6
        rootNode.addChild(foodNode)
    }
    
    func start() {
        restart()
    }
    
    func restart() {
        for s in segmentNodes { s.removeFromParent() }
        segmentNodes.removeAll()
        
        state = .running
        currentScore = 0
        stepTimer = 0.0
        stepInterval = 0.11
        direction = GridPoint(x: 1, y: 0)
        nextDirection = GridPoint(x: 1, y: 0)
        highScore = ScoreStore.shared.highScore(for: .snake)
        
        // Initial 4 segments
        snake = [
            GridPoint(x: 12, y: 7),
            GridPoint(x: 11, y: 7),
            GridPoint(x: 10, y: 7),
            GridPoint(x: 9, y: 7)
        ]
        
        spawnFood()
        rebuildSnakeNodes()
        
        onStateChanged?(.running)
        onScoreChanged?(0)
        onHighScoreChanged?(highScore)
    }
    
    private func spawnFood() {
        var emptyCells: [GridPoint] = []
        for x in 1..<(gridCols - 1) {
            for y in 1..<(gridRows - 1) {
                let pt = GridPoint(x: x, y: y)
                if !snake.contains(pt) {
                    emptyCells.append(pt)
                }
            }
        }
        food = emptyCells.randomElement() ?? GridPoint(x: 20, y: 7)
        foodNode.position = CGPoint(x: CGFloat(food.x) * cellSize, y: CGFloat(food.y) * cellSize)
    }
    
    private func rebuildSnakeNodes() {
        for s in segmentNodes { s.removeFromParent() }
        segmentNodes.removeAll()
        
        for (i, seg) in snake.enumerated() {
            let path = CGPath(roundedRect: CGRect(x: 0.5, y: 0.5, width: cellSize - 1, height: cellSize - 1), cornerWidth: 2, cornerHeight: 2, transform: nil)
            let node = SKShapeNode(path: path)
            if i == 0 {
                node.fillColor = NSColor(white: 0.96, alpha: 1.0) // Head
            } else {
                node.fillColor = NSColor(white: 0.72, alpha: 1.0)
            }
            node.strokeColor = .clear
            node.position = CGPoint(x: CGFloat(seg.x) * cellSize, y: CGFloat(seg.y) * cellSize)
            node.zPosition = 8
            rootNode.addChild(node)
            segmentNodes.append(node)
        }
    }
    
    func update(deltaTime: TimeInterval) {
        guard state == .running else { return }
        stepTimer += deltaTime
        
        if stepTimer >= stepInterval {
            stepTimer = 0.0
            direction = nextDirection
            
            let head = snake[0]
            let newHead = GridPoint(x: head.x + direction.x, y: head.y + direction.y)
            
            // Wall collision check
            if newHead.x < 0 || newHead.x >= gridCols || newHead.y < 0 || newHead.y >= gridRows {
                triggerGameOver()
                return
            }
            
            // Self-collision check
            if snake.contains(newHead) {
                triggerGameOver()
                return
            }
            
            // Move snake
            snake.insert(newHead, at: 0)
            
            if newHead == food {
                // Ate food
                currentScore += 10
                onScoreChanged?(currentScore)
                if currentScore > highScore {
                    highScore = currentScore
                    onHighScoreChanged?(highScore)
                }
                stepInterval = max(0.065, 0.11 - Double(currentScore / 250) * 0.01)
                spawnFood()
            } else {
                snake.removeLast()
            }
            
            rebuildSnakeNodes()
        }
    }
    
    private func triggerGameOver() {
        guard state == .running else { return }
        state = .gameOver
        ScoreStore.shared.record(score: currentScore, for: .snake)
        highScore = ScoreStore.shared.highScore(for: .snake)
        if let head = segmentNodes.first {
            head.fillColor = NSColor(red: 0.95, green: 0.3, blue: 0.3, alpha: 1.0)
        }
        onStateChanged?(.gameOver)
    }
    
    func handleKeyDown(event: NSEvent) -> Bool {
        let keyCode = event.keyCode
        if state != .running && (keyCode == 49 || keyCode == 126 || keyCode == 125 || keyCode == 123 || keyCode == 124) {
            restart()
            return true
        }
        
        switch keyCode {
        case 126, 13: // Up / W
            if direction.y == 0 { nextDirection = GridPoint(x: 0, y: 1) }
            return true
        case 125, 1:  // Down / S
            if direction.y == 0 { nextDirection = GridPoint(x: 0, y: -1) }
            return true
        case 123, 0:  // Left / A
            if direction.x == 0 { nextDirection = GridPoint(x: -1, y: 0) }
            return true
        case 124, 2:  // Right / D
            if direction.x == 0 { nextDirection = GridPoint(x: 1, y: 0) }
            return true
        case 49:      // Space
            if state == .idle || state == .gameOver { restart() }
            return true
        case 53:      // ESC
            if state == .running { pause() } else if state == .paused { resume() }
            return true
        default:
            return false
        }
    }
    
    func handleMouseDown(at point: CGPoint) -> Bool {
        if state != .running {
            restart()
            return true
        }
        // Click relative to snake head to turn
        if let head = snake.first {
            let headX = CGFloat(head.x) * cellSize
            let headY = CGFloat(head.y) * cellSize
            let dx = point.x - headX
            let dy = point.y - headY
            if abs(dx) > abs(dy) {
                if dx > 0 && direction.x == 0 { nextDirection = GridPoint(x: 1, y: 0) }
                else if dx < 0 && direction.x == 0 { nextDirection = GridPoint(x: -1, y: 0) }
            } else {
                if dy > 0 && direction.y == 0 { nextDirection = GridPoint(x: 0, y: 1) }
                else if dy < 0 && direction.y == 0 { nextDirection = GridPoint(x: 0, y: -1) }
            }
        }
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
        for s in segmentNodes { s.removeFromParent() }
        segmentNodes.removeAll()
        rootNode.removeAllChildren()
    }
}
