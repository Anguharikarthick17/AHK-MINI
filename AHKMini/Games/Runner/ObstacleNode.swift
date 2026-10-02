import SpriteKit
import AppKit

enum ObstacleType: CaseIterable {
    case smallPillar
    case twinPillars
    case spikeWedge
    case lowBarrier
    case aerialDrone
}

/// Minimalist vector obstacle node designed for high-contrast, Retina rendering.
final class ObstacleNode: SKNode {
    let type: ObstacleType
    private(set) var obstacleBounds: CGSize
    private var shapeNode: SKShapeNode!
    
    init(type: ObstacleType) {
        self.type = type
        self.obstacleBounds = .zero
        super.init()
        setupShape()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupShape() {
        let path = CGMutablePath()
        let fillColor = NSColor(white: 0.92, alpha: 1.0)
        let strokeColor = NSColor(white: 0.4, alpha: 0.5)
        
        switch type {
        case .smallPillar:
            // Sleek chamfered monolith
            obstacleBounds = CGSize(width: 14, height: 24)
            path.move(to: CGPoint(x: -7, y: 0))
            path.addLine(to: CGPoint(x: -7, y: 20))
            path.addLine(to: CGPoint(x: -3, y: 24))
            path.addLine(to: CGPoint(x: 3, y: 24))
            path.addLine(to: CGPoint(x: 7, y: 20))
            path.addLine(to: CGPoint(x: 7, y: 0))
            path.closeSubpath()
            
        case .twinPillars:
            // Two staggered thin pillars
            obstacleBounds = CGSize(width: 24, height: 26)
            // Left pillar
            path.addRect(CGRect(x: -12, y: 0, width: 8, height: 20))
            // Right pillar
            path.addRect(CGRect(x: 2, y: 0, width: 8, height: 26))
            
        case .spikeWedge:
            // Angular sharp geometric spike
            obstacleBounds = CGSize(width: 16, height: 22)
            path.move(to: CGPoint(x: -8, y: 0))
            path.addLine(to: CGPoint(x: 0, y: 22))
            path.addLine(to: CGPoint(x: 8, y: 0))
            path.closeSubpath()
            
        case .lowBarrier:
            // Wide low hurdle
            obstacleBounds = CGSize(width: 28, height: 16)
            path.addRoundedRect(
                in: CGRect(x: -14, y: 0, width: 28, height: 16),
                cornerWidth: 3,
                cornerHeight: 3
            )
            
        case .aerialDrone:
            // Floating diamond drone requiring player to stay low or time jump
            obstacleBounds = CGSize(width: 18, height: 14)
            path.move(to: CGPoint(x: -9, y: 7))
            path.addLine(to: CGPoint(x: 0, y: 14))
            path.addLine(to: CGPoint(x: 9, y: 7))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.closeSubpath()
        }
        
        shapeNode = SKShapeNode(path: path)
        shapeNode.fillColor = fillColor
        shapeNode.strokeColor = strokeColor
        shapeNode.lineWidth = 1.0
        addChild(shapeNode)
    }
    
    var collisionRect: CGRect {
        let margin: CGFloat = 2.0
        let w = max(4.0, obstacleBounds.width - (margin * 2))
        let h = max(4.0, obstacleBounds.height - (margin * 2))
        return CGRect(
            x: position.x - (w / 2.0),
            y: position.y + margin,
            width: w,
            height: h
        )
    }
}
