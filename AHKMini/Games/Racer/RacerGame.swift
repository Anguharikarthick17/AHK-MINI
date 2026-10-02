import SpriteKit
import AppKit

/// AHK Racer — 3-lane horizontal highway speed dodger.
/// Player steers an aerodynamic vector racer across 3 lanes avoiding oncoming traffic.
final class RacerGame: MiniGame {
    let gameType: GameType = .racer
    let rootNode: SKNode = SKNode()
    
    private(set) var state: GameState = .idle
    private(set) var currentScore: Int = 0
    private(set) var highScore: Int = 0
    
    var onScoreChanged: ((Int) -> Void)?
    var onHighScoreChanged: ((Int) -> Void)?
    var onStateChanged: ((GameState) -> Void)?
    
    private let sceneSize: CGSize
    private let laneY: [CGFloat] = [32.0, 70.0, 108.0]
    private var currentLane: Int = 1 // Middle lane
    
    private var carNode: SKShapeNode!
    private var carCockpit: SKShapeNode!
    private var trafficCars: [SKShapeNode] = []
    private var laneDividers: [SKShapeNode] = []
    
    private var speed: CGFloat = 260.0
    private var distance: CGFloat = 0.0
    private var spawnTimer: TimeInterval = 0.0
    
    init(size: CGSize) {
        self.sceneSize = size
        self.highScore = ScoreStore.shared.highScore(for: .racer)
        setupTrack()
    }
    
    private func setupTrack() {
        // Dashed lane divider lines
        for dividerY in [51.0, 89.0] {
            var x: CGFloat = 0.0
            while x < sceneSize.width + 40 {
                let dash = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 18, height: 1.5))
                dash.fillColor = NSColor(white: 0.28, alpha: 0.8)
                dash.strokeColor = .clear
                dash.position = CGPoint(x: x, y: dividerY)
                rootNode.addChild(dash)
                laneDividers.append(dash)
                x += 32.0
            }
        }
        
        // Player Racer: Sleek aerodynamic speedster
        let carPath = CGMutablePath()
        carPath.move(to: CGPoint(x: 15, y: 0))
        carPath.addLine(to: CGPoint(x: 8, y: 8))
        carPath.addLine(to: CGPoint(x: -12, y: 8))
        carPath.addLine(to: CGPoint(x: -15, y: 4))
        carPath.addLine(to: CGPoint(x: -15, y: -4))
        carPath.addLine(to: CGPoint(x: -12, y: -8))
        carPath.addLine(to: CGPoint(x: 8, y: -8))
        carPath.closeSubpath()
        
        carNode = SKShapeNode(path: carPath)
        carNode.fillColor = NSColor(white: 0.95, alpha: 1.0)
        carNode.strokeColor = .clear
        carNode.position = CGPoint(x: 55.0, y: laneY[currentLane])
        carNode.zPosition = 10
        rootNode.addChild(carNode)
        
        // AHK signature yellow cockpit visor
        let cockpitPath = CGPath(roundedRect: CGRect(x: -2, y: -4, width: 8, height: 8), cornerWidth: 2, cornerHeight: 2, transform: nil)
        carCockpit = SKShapeNode(path: cockpitPath)
        carCockpit.fillColor = NSColor(red: 1.0, green: 0.81, blue: 0.0, alpha: 1.0)
        carCockpit.strokeColor = .clear
        carNode.addChild(carCockpit)
    }
    
    func start() {
        restart()
    }
    
    func restart() {
        for t in trafficCars { t.removeFromParent() }
        trafficCars.removeAll()
        
        state = .running
        currentScore = 0
        distance = 0.0
        speed = 260.0
        spawnTimer = 0.0
        currentLane = 1
        carNode.position = CGPoint(x: 55.0, y: laneY[currentLane])
        carNode.fillColor = NSColor(white: 0.95, alpha: 1.0)
        highScore = ScoreStore.shared.highScore(for: .racer)
        
        onStateChanged?(.running)
        onScoreChanged?(0)
        onHighScoreChanged?(highScore)
    }
    
    func update(deltaTime: TimeInterval) {
        guard state == .running else { return }
        
        let dt = CGFloat(deltaTime)
        speed = min(260.0 + (distance / 40.0), 550.0)
        distance += speed * dt
        
        let newScore = Int(distance / 14.0)
        if newScore != currentScore {
            currentScore = newScore
            onScoreChanged?(currentScore)
            if currentScore > highScore {
                highScore = currentScore
                onHighScoreChanged?(highScore)
            }
        }
        
        // Scroll lane dividers
        let moveX = speed * dt
        for dash in laneDividers {
            dash.position.x -= moveX
            if dash.position.x < -20 {
                dash.position.x += sceneSize.width + 40
            }
        }
        
        // Smooth lane change interpolation
        let targetY = laneY[currentLane]
        carNode.position.y += (targetY - carNode.position.y) * min(1.0, dt * 18.0)
        
        // Traffic management
        var remaining: [SKShapeNode] = []
        for traffic in trafficCars {
            traffic.position.x -= (speed * 0.85) * dt
            if traffic.position.x < -30 {
                traffic.removeFromParent()
            } else {
                remaining.append(traffic)
            }
        }
        trafficCars = remaining
        
        spawnTimer += deltaTime
        let spawnThreshold = max(0.55, 1.3 - Double(speed / 600.0))
        if spawnTimer >= spawnThreshold {
            spawnTimer = 0.0
            spawnTraffic()
        }
        
        checkCollisions()
    }
    
    private func spawnTraffic() {
        let laneIndex = Int.random(in: 0...2)
        let isTruck = Bool.random()
        
        let length: CGFloat = isTruck ? 34.0 : 22.0
        let path = CGPath(roundedRect: CGRect(x: -length/2, y: -7, width: length, height: 14), cornerWidth: 2, cornerHeight: 2, transform: nil)
        let traffic = SKShapeNode(path: path)
        traffic.fillColor = isTruck ? NSColor(white: 0.65, alpha: 1.0) : NSColor(white: 0.82, alpha: 1.0)
        traffic.strokeColor = NSColor(white: 0.35, alpha: 0.7)
        traffic.lineWidth = 1.0
        traffic.position = CGPoint(x: sceneSize.width + 40, y: laneY[laneIndex])
        traffic.zPosition = 6
        rootNode.addChild(traffic)
        trafficCars.append(traffic)
    }
    
    private func checkCollisions() {
        let playerBox = CGRect(x: carNode.position.x - 12, y: carNode.position.y - 6, width: 24, height: 12)
        for t in trafficCars {
            let tBox = CGRect(x: t.position.x - 10, y: t.position.y - 6, width: 20, height: 12)
            if playerBox.intersects(tBox) {
                triggerGameOver()
                break
            }
        }
    }
    
    private func triggerGameOver() {
        guard state == .running else { return }
        state = .gameOver
        ScoreStore.shared.record(score: currentScore, for: .racer)
        highScore = ScoreStore.shared.highScore(for: .racer)
        carNode.fillColor = NSColor(red: 0.95, green: 0.3, blue: 0.3, alpha: 1.0)
        onStateChanged?(.gameOver)
    }
    
    func handleKeyDown(event: NSEvent) -> Bool {
        let keyCode = event.keyCode
        // Up (126, W: 13), Down (125, S: 1), Space (49)
        if keyCode == 126 || keyCode == 13 {
            if state != .running { restart(); return true }
            if currentLane < 2 { currentLane += 1 }
            return true
        } else if keyCode == 125 || keyCode == 1 {
            if state != .running { restart(); return true }
            if currentLane > 0 { currentLane -= 1 }
            return true
        } else if keyCode == 49 {
            if state == .idle || state == .gameOver {
                restart()
            } else if state == .running {
                // Space cycles lanes: 0 -> 1 -> 2 -> 0
                currentLane = (currentLane + 1) % 3
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
        // Click nearest lane
        var closestLane = 0
        var minDist = abs(point.y - laneY[0])
        for i in 1...2 {
            let d = abs(point.y - laneY[i])
            if d < minDist {
                minDist = d
                closestLane = i
            }
        }
        currentLane = closestLane
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
        for t in trafficCars { t.removeFromParent() }
        trafficCars.removeAll()
        rootNode.removeAllChildren()
    }
}
