import SpriteKit
import AppKit

/// Original AHK-style minimalist runner character.
/// Features vector-drawn geometry, AHK liquid-yellow visor accent, and procedural run animation.
final class PlayerNode: SKNode {
    
    // Physical attributes
    let playerWidth: CGFloat = 22.0
    let playerHeight: CGFloat = 26.0
    
    // Jump mechanics
    var velocityY: CGFloat = 0.0
    let gravity: CGFloat = -1150.0
    let jumpImpulse: CGFloat = 390.0
    private(set) var isGrounded: Bool = true
    
    // Procedural animation state
    private var stridePhase: CGFloat = 0.0
    private var bodyNode: SKShapeNode!
    private var visorNode: SKShapeNode!
    private var leftLegNode: SKShapeNode!
    private var rightLegNode: SKShapeNode!
    private var shadowNode: SKShapeNode!
    
    // Visual colors
    private let bodyColor = NSColor(white: 0.95, alpha: 1.0)
    private let accentYellow = NSColor(red: 1.0, green: 0.81, blue: 0.0, alpha: 1.0) // AHK signature yellow
    private let legColor = NSColor(white: 0.75, alpha: 1.0)
    
    override init() {
        super.init()
        setupNodes()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupNodes() {
        // Shadow underneath
        let shadowPath = CGPath(ellipseIn: CGRect(x: -12, y: -2, width: 24, height: 4), transform: nil)
        shadowNode = SKShapeNode(path: shadowPath)
        shadowNode.fillColor = NSColor(white: 0.0, alpha: 0.4)
        shadowNode.strokeColor = .clear
        shadowNode.zPosition = 1
        addChild(shadowNode)
        
        // Procedural legs
        leftLegNode = makeLeg()
        leftLegNode.position = CGPoint(x: -4, y: 8)
        leftLegNode.zPosition = 2
        addChild(leftLegNode)
        
        rightLegNode = makeLeg()
        rightLegNode.position = CGPoint(x: 4, y: 8)
        rightLegNode.zPosition = 3
        addChild(rightLegNode)
        
        // Aerodynamic Torso/Head
        let bodyPath = CGMutablePath()
        // Sleek runner silhouette: angled back, rounded front, sharp visor notch
        bodyPath.move(to: CGPoint(x: -8, y: 6))
        bodyPath.addLine(to: CGPoint(x: -6, y: 22))
        bodyPath.addLine(to: CGPoint(x: 4, y: 24))
        bodyPath.addLine(to: CGPoint(x: 10, y: 19))
        bodyPath.addLine(to: CGPoint(x: 9, y: 13))
        bodyPath.addLine(to: CGPoint(x: 2, y: 11))
        bodyPath.addLine(to: CGPoint(x: 0, y: 6))
        bodyPath.closeSubpath()
        
        bodyNode = SKShapeNode(path: bodyPath)
        bodyNode.fillColor = bodyColor
        bodyNode.strokeColor = .clear
        bodyNode.zPosition = 4
        addChild(bodyNode)
        
        // AHK signature yellow visor / core
        let visorPath = CGMutablePath()
        visorPath.move(to: CGPoint(x: 3, y: 18))
        visorPath.addLine(to: CGPoint(x: 9, y: 18))
        visorPath.addLine(to: CGPoint(x: 7.5, y: 14))
        visorPath.addLine(to: CGPoint(x: 2, y: 14))
        visorPath.closeSubpath()
        
        visorNode = SKShapeNode(path: visorPath)
        visorNode.fillColor = accentYellow
        visorNode.strokeColor = .clear
        visorNode.glowWidth = 1.0
        visorNode.zPosition = 5
        addChild(visorNode)
    }
    
    private func makeLeg() -> SKShapeNode {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: -7))
        path.addLine(to: CGPoint(x: 3, y: -7))
        
        let leg = SKShapeNode(path: path)
        leg.strokeColor = legColor
        leg.lineWidth = 2.0
        leg.lineCap = .round
        leg.lineJoin = .round
        return leg
    }
    
    func jump() -> Bool {
        guard isGrounded else { return false }
        velocityY = jumpImpulse
        isGrounded = false
        
        // Tuck legs for jump
        leftLegNode.zRotation = 0.6
        rightLegNode.zRotation = -0.5
        bodyNode.zRotation = 0.12
        visorNode.zRotation = 0.12
        return true
    }
    
    func update(deltaTime: TimeInterval, speed: CGFloat, groundY: CGFloat) {
        if !isGrounded {
            // Apply gravity
            velocityY += gravity * CGFloat(deltaTime)
            position.y += velocityY * CGFloat(deltaTime)
            
            if position.y <= groundY {
                position.y = groundY
                velocityY = 0.0
                isGrounded = true
                bodyNode.zRotation = 0.0
                visorNode.zRotation = 0.0
            }
            
            // Fade shadow with jump height
            let heightAboveGround = position.y - groundY
            let shadowScale = max(0.4, 1.0 - (heightAboveGround / 70.0))
            shadowNode.xScale = shadowScale
            shadowNode.yScale = shadowScale
            shadowNode.alpha = max(0.1, 0.4 - (heightAboveGround / 120.0))
        } else {
            // Grounded run-cycle animation
            let strideFrequency: CGFloat = max(14.0, speed * 0.06)
            stridePhase += CGFloat(deltaTime) * strideFrequency
            
            let legSwing = sin(stridePhase)
            leftLegNode.zRotation = legSwing * 0.75
            rightLegNode.zRotation = -legSwing * 0.75
            
            // Subtle vertical body bobbing
            let bob = abs(sin(stridePhase)) * 1.8
            bodyNode.position.y = bob
            visorNode.position.y = bob
            
            shadowNode.xScale = 1.0
            shadowNode.yScale = 1.0
            shadowNode.alpha = 0.4
        }
    }
    
    func playDeathAnimation() {
        bodyNode.fillColor = NSColor(white: 0.5, alpha: 1.0)
        visorNode.fillColor = NSColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1.0) // Red glitch flash
        
        let tilt = SKAction.rotate(toAngle: -CGFloat.pi / 3, duration: 0.12)
        let drop = SKAction.moveBy(x: -8, y: -4, duration: 0.12)
        run(SKAction.group([tilt, drop]))
    }
    
    func reset(at groundY: CGFloat) {
        position.y = groundY
        velocityY = 0.0
        isGrounded = true
        stridePhase = 0.0
        zRotation = 0.0
        bodyNode.position = .zero
        visorNode.position = .zero
        bodyNode.zRotation = 0.0
        visorNode.zRotation = 0.0
        leftLegNode.zRotation = 0.0
        rightLegNode.zRotation = 0.0
        bodyNode.fillColor = bodyColor
        visorNode.fillColor = accentYellow
        shadowNode.xScale = 1.0
        shadowNode.yScale = 1.0
        shadowNode.alpha = 0.4
    }
    
    /// Fair, slightly inset collision bounding box in scene coordinates.
    var collisionRect: CGRect {
        let insetX: CGFloat = 3.0
        let insetY: CGFloat = 3.0
        return CGRect(
            x: position.x - 7.0 + insetX,
            y: position.y + insetY,
            width: playerWidth - (insetX * 2),
            height: playerHeight - (insetY * 2)
        )
    }
}
