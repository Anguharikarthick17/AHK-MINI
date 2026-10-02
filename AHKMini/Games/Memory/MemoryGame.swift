import SpriteKit
import AppKit

/// AHK Memory — Minimal card flip & match puzzle.
/// Flip vector data cards to match 4 pairs in the fewest moves and fastest time.
final class MemoryGame: MiniGame {
    let gameType: GameType = .memory
    let rootNode: SKNode = SKNode()
    
    private(set) var state: GameState = .idle
    private(set) var currentScore: Int = 0
    private(set) var highScore: Int = 0
    
    var onScoreChanged: ((Int) -> Void)?
    var onHighScoreChanged: ((Int) -> Void)?
    var onStateChanged: ((GameState) -> Void)?
    
    private let sceneSize: CGSize
    private let cardWidth: CGFloat = 52.0
    private let cardHeight: CGFloat = 40.0
    
    struct Card {
        let id: Int
        let symbol: Int // 0: Diamond, 1: Circle, 2: Triangle, 3: Square
        var isFaceUp: Bool = false
        var isMatched: Bool = false
        var node: SKNode?
    }
    
    private var cards: [Card] = []
    private var firstSelectedIndex: Int? = nil
    private var isEvaluatingMatch: Bool = false
    private var moveCount: Int = 0
    private var elapsedSeconds: TimeInterval = 0.0
    
    init(size: CGSize) {
        self.sceneSize = size
        self.highScore = ScoreStore.shared.highScore(for: .memory)
    }
    
    func start() {
        restart()
    }
    
    func restart() {
        rootNode.removeAllChildren()
        state = .running
        moveCount = 0
        elapsedSeconds = 0.0
        currentScore = 1000
        firstSelectedIndex = nil
        isEvaluatingMatch = false
        highScore = ScoreStore.shared.highScore(for: .memory)
        
        setupCards()
        
        onStateChanged?(.running)
        onScoreChanged?(currentScore)
        onHighScoreChanged?(highScore)
    }
    
    private func setupCards() {
        cards.removeAll()
        // 4 pairs of symbols (0, 1, 2, 3) = 8 cards
        var symbols = [0, 0, 1, 1, 2, 2, 3, 3]
        symbols.shuffle()
        
        let cols = 4
        let rows = 2
        let spacingX: CGFloat = 16.0
        let spacingY: CGFloat = 12.0
        
        let totalW = CGFloat(cols) * cardWidth + CGFloat(cols - 1) * spacingX
        let totalH = CGFloat(rows) * cardHeight + CGFloat(rows - 1) * spacingY
        let startX = (sceneSize.width - totalW) / 2.0 + cardWidth / 2.0
        let startY = (sceneSize.height - totalH) / 2.0 + cardHeight / 2.0 + 8.0
        
        for i in 0..<8 {
            let col = i % cols
            let row = i / cols
            let x = startX + CGFloat(col) * (cardWidth + spacingX)
            let y = startY + CGFloat(rows - 1 - row) * (cardHeight + spacingY)
            
            var card = Card(id: i, symbol: symbols[i])
            let node = makeCardNode(for: card, at: CGPoint(x: x, y: y))
            card.node = node
            rootNode.addChild(node)
            cards.append(card)
        }
    }
    
    private func makeCardNode(for card: Card, at position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position
        container.name = "card_\(card.id)"
        
        // Card background tile
        let rect = CGRect(x: -cardWidth/2, y: -cardHeight/2, width: cardWidth, height: cardHeight)
        let bgPath = CGPath(roundedRect: rect, cornerWidth: 6, cornerHeight: 6, transform: nil)
        let bg = SKShapeNode(path: bgPath)
        bg.fillColor = NSColor(white: 0.16, alpha: 1.0)
        bg.strokeColor = NSColor(white: 0.35, alpha: 0.6)
        bg.lineWidth = 1.0
        bg.name = "bg"
        container.addChild(bg)
        
        // Icon node (hidden initially)
        let icon = makeSymbolNode(symbol: card.symbol)
        icon.name = "icon"
        icon.isHidden = true
        container.addChild(icon)
        
        return container
    }
    
    private func makeSymbolNode(symbol: Int) -> SKShapeNode {
        let path = CGMutablePath()
        let yellow = NSColor(red: 1.0, green: 0.81, blue: 0.0, alpha: 1.0)
        
        switch symbol {
        case 0: // Diamond
            path.move(to: CGPoint(x: 0, y: 10))
            path.addLine(to: CGPoint(x: 9, y: 0))
            path.addLine(to: CGPoint(x: 0, y: -10))
            path.addLine(to: CGPoint(x: -9, y: 0))
            path.closeSubpath()
        case 1: // Circle
            path.addEllipse(in: CGRect(x: -8, y: -8, width: 16, height: 16))
        case 2: // Triangle
            path.move(to: CGPoint(x: 0, y: 10))
            path.addLine(to: CGPoint(x: 9, y: -7))
            path.addLine(to: CGPoint(x: -9, y: -7))
            path.closeSubpath()
        default: // Square
            path.addRoundedRect(in: CGRect(x: -7, y: -7, width: 14, height: 14), cornerWidth: 2, cornerHeight: 2)
        }
        
        let shape = SKShapeNode(path: path)
        shape.fillColor = yellow
        shape.strokeColor = .clear
        return shape
    }
    
    func update(deltaTime: TimeInterval) {
        guard state == .running else { return }
        elapsedSeconds += deltaTime
        
        // Score calculation: decays gracefully over moves and time
        let score = max(100, 1000 - (moveCount * 30) - Int(elapsedSeconds * 5))
        if score != currentScore {
            currentScore = score
            onScoreChanged?(currentScore)
        }
    }
    
    func handleMouseDown(at point: CGPoint) -> Bool {
        guard state == .running, !isEvaluatingMatch else {
            if state == .gameOver || state == .idle {
                restart()
            }
            return true
        }
        
        for (index, card) in cards.enumerated() {
            guard !card.isMatched, !card.isFaceUp, let node = card.node else { continue }
            let cardBox = CGRect(x: node.position.x - cardWidth/2, y: node.position.y - cardHeight/2, width: cardWidth, height: cardHeight)
            if cardBox.contains(point) {
                flipCard(at: index)
                break
            }
        }
        return true
    }
    
    private func flipCard(at index: Int) {
        cards[index].isFaceUp = true
        if let node = cards[index].node, let icon = node.childNode(withName: "icon"), let bg = node.childNode(withName: "bg") as? SKShapeNode {
            icon.isHidden = false
            bg.fillColor = NSColor(white: 0.28, alpha: 1.0)
            
            // Subtle flip animation
            node.run(SKAction.sequence([
                SKAction.scaleX(to: 0.1, duration: 0.08),
                SKAction.scaleX(to: 1.0, duration: 0.08)
            ]))
        }
        
        if let firstIdx = firstSelectedIndex {
            // Second card flipped
            moveCount += 1
            isEvaluatingMatch = true
            
            if cards[firstIdx].symbol == cards[index].symbol {
                // Match!
                cards[firstIdx].isMatched = true
                cards[index].isMatched = true
                firstSelectedIndex = nil
                isEvaluatingMatch = false
                
                // Highlight matched cards with AHK gold rim
                highlightMatched(index: firstIdx)
                highlightMatched(index: index)
                
                // Check victory condition
                if cards.allSatisfy({ $0.isMatched }) {
                    triggerVictory()
                }
            } else {
                // Mismatch: flip back after 0.55s
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { [weak self] in
                    self?.flipBack(index1: firstIdx, index2: index)
                }
            }
        } else {
            // First card flipped
            firstSelectedIndex = index
        }
    }
    
    private func highlightMatched(index: Int) {
        guard let node = cards[index].node, let bg = node.childNode(withName: "bg") as? SKShapeNode else { return }
        bg.strokeColor = NSColor(red: 1.0, green: 0.81, blue: 0.0, alpha: 0.9)
        bg.lineWidth = 1.5
    }
    
    private func flipBack(index1: Int, index2: Int) {
        cards[index1].isFaceUp = false
        cards[index2].isFaceUp = false
        
        for idx in [index1, index2] {
            if let node = cards[idx].node, let icon = node.childNode(withName: "icon"), let bg = node.childNode(withName: "bg") as? SKShapeNode {
                node.run(SKAction.sequence([
                    SKAction.scaleX(to: 0.1, duration: 0.06),
                    SKAction.run {
                        icon.isHidden = true
                        bg.fillColor = NSColor(white: 0.16, alpha: 1.0)
                    },
                    SKAction.scaleX(to: 1.0, duration: 0.06)
                ]))
            }
        }
        firstSelectedIndex = nil
        isEvaluatingMatch = false
    }
    
    private func triggerVictory() {
        state = .gameOver
        ScoreStore.shared.record(score: currentScore, for: .memory)
        highScore = ScoreStore.shared.highScore(for: .memory)
        onHighScoreChanged?(highScore)
        onStateChanged?(.gameOver)
    }
    
    func handleKeyDown(event: NSEvent) -> Bool {
        let keyCode = event.keyCode
        if keyCode == 49 { // Space
            if state == .idle || state == .gameOver { restart() }
            return true
        } else if keyCode == 53 { // ESC
            if state == .running { pause() } else if state == .paused { resume() }
            return true
        }
        return false
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
        cards.removeAll()
    }
}
