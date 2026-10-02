import SpriteKit
import AppKit

/// Lightweight Game Selector menu for AHK Mini Arcade.
/// Displays 8 compact arcade buttons with quick keyboard (1-8) and mouse selection.
final class GameSelectorNode: SKNode {
    private let sceneSize: CGSize
    var onSelectGame: ((GameType) -> Void)?
    
    private var buttonNodes: [(GameType, CGRect, SKShapeNode)] = []
    
    init(size: CGSize) {
        self.sceneSize = size
        super.init()
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        let topY = sceneSize.height - 20.0
        
        // Brand Dot
        let brandDot = SKShapeNode(circleOfRadius: 2.5)
        brandDot.fillColor = NSColor(red: 1.0, green: 0.81, blue: 0.0, alpha: 1.0)
        brandDot.strokeColor = .clear
        brandDot.position = CGPoint(x: 22.0, y: topY)
        addChild(brandDot)
        
        // Brand Title
        let brandLabel = SKLabelNode(fontNamed: "SFPro-Bold")
        if brandLabel.fontName == nil { brandLabel.fontName = "HelveticaNeue-Bold" }
        brandLabel.text = "AHK MINI"
        brandLabel.fontSize = 10.5
        brandLabel.fontColor = NSColor(white: 0.95, alpha: 1.0)
        brandLabel.horizontalAlignmentMode = .left
        brandLabel.verticalAlignmentMode = .center
        brandLabel.position = CGPoint(x: 30.0, y: topY)
        addChild(brandLabel)
        
        // Subtitle: ARCADE (SELECT 1-8 OR CLICK)
        let subLabel = SKLabelNode(fontNamed: "SFMono-Regular")
        if subLabel.fontName == nil { subLabel.fontName = "Menlo-Regular" }
        subLabel.text = "SELECT GAME (1-8 OR CLICK)"
        subLabel.fontSize = 8.5
        subLabel.fontColor = NSColor(white: 0.45, alpha: 1.0)
        subLabel.horizontalAlignmentMode = .right
        subLabel.verticalAlignmentMode = .center
        subLabel.position = CGPoint(x: sceneSize.width - 22.0, y: topY)
        addChild(subLabel)
        
        // 8 Games arranged in 2 rows of 4 columns
        let cols = 4
        let btnWidth: CGFloat = 88.0
        let btnHeight: CGFloat = 38.0
        let spacingX: CGFloat = 10.0
        
        let totalW = CGFloat(cols) * btnWidth + CGFloat(cols - 1) * spacingX
        let startX = (sceneSize.width - totalW) / 2.0 + btnWidth / 2.0
        // Clean non-overlapping row centers: Row 0 at y=74, Row 1 at y=28
        let rowCentersY: [CGFloat] = [74.0, 28.0]
        
        let allGames = GameType.allCases
        for (i, game) in allGames.enumerated() {
            let col = i % cols
            let row = i / cols
            let x = startX + CGFloat(col) * (btnWidth + spacingX)
            let y = rowCentersY[row]
            
            let btnRect = CGRect(x: x - btnWidth / 2.0, y: y - btnHeight / 2.0, width: btnWidth, height: btnHeight)
            let btnNode = makeGameButton(game: game, index: i + 1, width: btnWidth, height: btnHeight)
            btnNode.position = CGPoint(x: x, y: y)
            addChild(btnNode)
            
            buttonNodes.append((game, btnRect, btnNode))
        }
    }
    
    private func makeGameButton(game: GameType, index: Int, width: CGFloat, height: CGFloat) -> SKShapeNode {
        let path = CGPath(roundedRect: CGRect(x: -width/2, y: -height/2, width: width, height: height), cornerWidth: 6, cornerHeight: 6, transform: nil)
        let btn = SKShapeNode(path: path)
        btn.fillColor = NSColor(white: 0.12, alpha: 1.0)
        btn.strokeColor = NSColor(white: 0.28, alpha: 0.8)
        btn.lineWidth = 1.0
        
        // Icon label
        let iconLabel = SKLabelNode(text: game.icon)
        iconLabel.fontSize = 13.0
        iconLabel.horizontalAlignmentMode = .center
        iconLabel.verticalAlignmentMode = .center
        iconLabel.position = CGPoint(x: 0, y: 7.0)
        btn.addChild(iconLabel)
        
        // Title + Key shortcut e.g. "1. Runner"
        let nameLabel = SKLabelNode(fontNamed: "SFPro-Medium")
        if nameLabel.fontName == nil { nameLabel.fontName = "HelveticaNeue-Medium" }
        nameLabel.text = "\(index) \(game.displayName)"
        nameLabel.fontSize = 8.5
        nameLabel.fontColor = NSColor(white: 0.88, alpha: 1.0)
        nameLabel.horizontalAlignmentMode = .center
        nameLabel.verticalAlignmentMode = .center
        nameLabel.position = CGPoint(x: 0, y: -9.0)
        btn.addChild(nameLabel)
        
        return btn
    }
    
    func handleMouseDown(at point: CGPoint) -> Bool {
        for (game, rect, node) in buttonNodes {
            if rect.contains(point) {
                // Button click feedback
                node.run(SKAction.sequence([
                    SKAction.scale(to: 0.94, duration: 0.05),
                    SKAction.scale(to: 1.0, duration: 0.05),
                    SKAction.run { [weak self] in
                        self?.onSelectGame?(game)
                    }
                ]))
                return true
            }
        }
        return false
    }
    
    func handleKeyDown(event: NSEvent) -> Bool {
        let chars = event.characters ?? ""
        if let firstChar = chars.first, let num = Int(String(firstChar)), num >= 1 && num <= 8 {
            let game = GameType.allCases[num - 1]
            onSelectGame?(game)
            return true
        }
        return false
    }
}
