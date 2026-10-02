import SpriteKit
import AppKit

/// Unified Arcade HUD with score counter, high score, and back-to-menu button.
final class ArcadeHUDNode: SKNode {
    private let sceneSize: CGSize
    var onBackToArcade: (() -> Void)?
    
    private var backButtonRect: CGRect = .zero
    private var backButtonNode: SKShapeNode!
    
    private var titleLabel: SKLabelNode!
    private var scoreLabel: SKLabelNode!
    private var highScoreLabel: SKLabelNode!
    
    private var centerOverlay: SKNode!
    private var overlayTitle: SKLabelNode!
    private var overlaySubtitle: SKLabelNode!
    
    private let accentYellow = NSColor(red: 1.0, green: 0.81, blue: 0.0, alpha: 1.0)
    private let mutedText = NSColor(white: 0.52, alpha: 1.0)
    private let brightText = NSColor(white: 0.96, alpha: 1.0)
    
    init(size: CGSize) {
        self.sceneSize = size
        super.init()
        setupTopBar()
        setupCenterOverlay()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupTopBar() {
        let topY = sceneSize.height - 18.0
        
        // Back to Menu Button
        backButtonRect = CGRect(x: 12.0, y: topY - 10.0, width: 62.0, height: 20.0)
        let bPath = CGPath(roundedRect: CGRect(x: -31.0, y: -10.0, width: 62.0, height: 20.0), cornerWidth: 4, cornerHeight: 4, transform: nil)
        backButtonNode = SKShapeNode(path: bPath)
        backButtonNode.fillColor = NSColor(white: 0.16, alpha: 0.8)
        backButtonNode.strokeColor = NSColor(white: 0.32, alpha: 0.6)
        backButtonNode.lineWidth = 1.0
        backButtonNode.position = CGPoint(x: 43.0, y: topY)
        addChild(backButtonNode)
        
        let backLabel = SKLabelNode(fontNamed: "SFPro-Medium")
        if backLabel.fontName == nil { backLabel.fontName = "HelveticaNeue-Medium" }
        backLabel.text = "‹ MENU"
        backLabel.fontSize = 8.5
        backLabel.fontColor = NSColor(white: 0.85, alpha: 1.0)
        backLabel.horizontalAlignmentMode = .center
        backLabel.verticalAlignmentMode = .center
        backButtonNode.addChild(backLabel)
        
        // Game Title
        titleLabel = SKLabelNode(fontNamed: "SFPro-Bold")
        if titleLabel.fontName == nil { titleLabel.fontName = "HelveticaNeue-Bold" }
        titleLabel.text = "AHK RUNNER"
        titleLabel.fontSize = 9.5
        titleLabel.fontColor = mutedText
        titleLabel.horizontalAlignmentMode = .left
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 84.0, y: topY)
        addChild(titleLabel)
        
        // Current score
        scoreLabel = SKLabelNode(fontNamed: "SFMono-Medium")
        if scoreLabel.fontName == nil { scoreLabel.fontName = "Menlo-Bold" }
        scoreLabel.text = "00000"
        scoreLabel.fontSize = 11.5
        scoreLabel.fontColor = brightText
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.position = CGPoint(x: sceneSize.width - 16.0, y: topY)
        addChild(scoreLabel)
        
        // High score
        highScoreLabel = SKLabelNode(fontNamed: "SFMono-Regular")
        if highScoreLabel.fontName == nil { highScoreLabel.fontName = "Menlo-Regular" }
        highScoreLabel.text = "HI 00000"
        highScoreLabel.fontSize = 10.0
        highScoreLabel.fontColor = mutedText
        highScoreLabel.horizontalAlignmentMode = .right
        highScoreLabel.verticalAlignmentMode = .center
        highScoreLabel.position = CGPoint(x: sceneSize.width - 76.0, y: topY)
        addChild(highScoreLabel)
    }
    
    private func setupCenterOverlay() {
        centerOverlay = SKNode()
        centerOverlay.position = CGPoint(x: sceneSize.width / 2.0, y: sceneSize.height / 2.0 + 4.0)
        addChild(centerOverlay)
        
        overlayTitle = SKLabelNode(fontNamed: "SFPro-Heavy")
        if overlayTitle.fontName == nil { overlayTitle.fontName = "HelveticaNeue-Bold" }
        overlayTitle.fontSize = 15.0
        overlayTitle.fontColor = brightText
        overlayTitle.horizontalAlignmentMode = .center
        overlayTitle.verticalAlignmentMode = .center
        overlayTitle.position = CGPoint(x: 0, y: 7.0)
        centerOverlay.addChild(overlayTitle)
        
        overlaySubtitle = SKLabelNode(fontNamed: "SFPro-Medium")
        if overlaySubtitle.fontName == nil { overlaySubtitle.fontName = "HelveticaNeue" }
        overlaySubtitle.fontSize = 9.0
        overlaySubtitle.fontColor = mutedText
        overlaySubtitle.horizontalAlignmentMode = .center
        overlaySubtitle.verticalAlignmentMode = .center
        overlaySubtitle.position = CGPoint(x: 0, y: -9.0)
        centerOverlay.addChild(overlaySubtitle)
    }
    
    func configure(for game: GameType) {
        titleLabel.text = "\(game.icon) AHK \(game.displayName.uppercased())"
    }
    
    func updateScore(_ score: Int) {
        scoreLabel.text = String(format: "%05d", score)
    }
    
    func updateHighScore(_ highScore: Int) {
        highScoreLabel.text = String(format: "HI %05d", highScore)
    }
    
    func setOverlay(state: GameState, gameName: String) {
        centerOverlay.removeAllActions()
        
        switch state {
        case .idle:
            centerOverlay.isHidden = false
            overlayTitle.text = gameName.uppercased()
            overlaySubtitle.text = "PRESS SPACE OR CLICK TO START"
            let pulse = SKAction.sequence([SKAction.fadeAlpha(to: 0.4, duration: 0.8), SKAction.fadeAlpha(to: 1.0, duration: 0.8)])
            overlaySubtitle.run(SKAction.repeatForever(pulse))
            
        case .running:
            centerOverlay.isHidden = true
            
        case .paused:
            centerOverlay.isHidden = false
            overlayTitle.text = "PAUSED"
            overlaySubtitle.text = "CLICK TO RESUME"
            overlaySubtitle.alpha = 0.9
            
        case .gameOver:
            centerOverlay.isHidden = false
            overlayTitle.text = "GAME OVER"
            overlaySubtitle.text = "PRESS SPACE OR CLICK TO RETRY"
            let pulse = SKAction.sequence([SKAction.fadeAlpha(to: 0.5, duration: 0.6), SKAction.fadeAlpha(to: 1.0, duration: 0.6)])
            overlaySubtitle.run(SKAction.repeatForever(pulse))
        }
    }
    
    func handleMouseDown(at point: CGPoint) -> Bool {
        if backButtonRect.contains(point) {
            onBackToArcade?()
            return true
        }
        return false
    }
}
