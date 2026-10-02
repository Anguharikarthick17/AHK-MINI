import SpriteKit
import AppKit

/// Endless scrolling ground plane with minimal vector markings and parallax horizon dust.
final class GroundNode: SKNode {
    private let sceneWidth: CGFloat
    private let groundY: CGFloat
    
    private var lineNode1: SKShapeNode!
    private var lineNode2: SKShapeNode!
    private var segmentWidth: CGFloat = 450.0
    
    // Parallax background dust/stars
    private var backgroundDustNode: SKNode!
    private var dustPoints: [CGPoint] = []
    
    init(sceneWidth: CGFloat, groundY: CGFloat) {
        self.sceneWidth = sceneWidth
        self.groundY = groundY
        super.init()
        setupGround()
        setupBackgroundDust()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupGround() {
        segmentWidth = sceneWidth + 60.0
        
        lineNode1 = makeGroundSegment()
        lineNode1.position = CGPoint(x: 0, y: groundY)
        addChild(lineNode1)
        
        lineNode2 = makeGroundSegment()
        lineNode2.position = CGPoint(x: segmentWidth, y: groundY)
        addChild(lineNode2)
    }
    
    private func makeGroundSegment() -> SKShapeNode {
        let path = CGMutablePath()
        // Main continuous baseline
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: segmentWidth, y: 0))
        
        // Subtle rhythmic tick marks beneath the line
        var x: CGFloat = 16.0
        while x < segmentWidth {
            path.move(to: CGPoint(x: x, y: -2))
            let tickHeight: CGFloat = (Int(x) % 48 == 0) ? -5.0 : -2.5
            path.addLine(to: CGPoint(x: x + 4, y: tickHeight))
            x += CGFloat.random(in: 24...44)
        }
        
        let shape = SKShapeNode(path: path)
        shape.strokeColor = NSColor(white: 0.35, alpha: 0.8)
        shape.lineWidth = 1.0
        return shape
    }
    
    private func setupBackgroundDust() {
        backgroundDustNode = SKNode()
        backgroundDustNode.zPosition = -1
        addChild(backgroundDustNode)
        
        // Ambient distant points
        for _ in 0..<12 {
            let px = CGFloat.random(in: 0...sceneWidth)
            let py = CGFloat.random(in: (groundY + 15)...(groundY + 80))
            let dot = SKShapeNode(circleOfRadius: 0.75)
            dot.fillColor = NSColor(white: 0.25, alpha: 0.5)
            dot.strokeColor = .clear
            dot.position = CGPoint(x: px, y: py)
            backgroundDustNode.addChild(dot)
        }
    }
    
    func update(deltaTime: TimeInterval, speed: CGFloat) {
        let moveDistance = speed * CGFloat(deltaTime)
        
        lineNode1.position.x -= moveDistance
        lineNode2.position.x -= moveDistance
        
        if lineNode1.position.x <= -segmentWidth {
            lineNode1.position.x = lineNode2.position.x + segmentWidth
        }
        if lineNode2.position.x <= -segmentWidth {
            lineNode2.position.x = lineNode1.position.x + segmentWidth
        }
        
        // Slow parallax for background dust
        let dustMove = (speed * 0.2) * CGFloat(deltaTime)
        for child in backgroundDustNode.children {
            child.position.x -= dustMove
            if child.position.x < 0 {
                child.position.x += sceneWidth
                child.position.y = CGFloat.random(in: (groundY + 15)...(groundY + 80))
            }
        }
    }
    
    func reset() {
        lineNode1.position = CGPoint(x: 0, y: groundY)
        lineNode2.position = CGPoint(x: segmentWidth, y: groundY)
    }
}
