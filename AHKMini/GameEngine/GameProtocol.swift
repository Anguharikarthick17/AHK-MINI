import SpriteKit
import AppKit

enum GameState: Equatable {
    case idle
    case running
    case paused
    case gameOver
}

/// Standard protocol implemented by all mini-games in the AHK Mini Arcade.
protocol MiniGame: AnyObject {
    var gameType: GameType { get }
    var rootNode: SKNode { get }
    var state: GameState { get }
    var currentScore: Int { get }
    var highScore: Int { get }
    
    var onScoreChanged: ((Int) -> Void)? { get set }
    var onHighScoreChanged: ((Int) -> Void)? { get set }
    var onStateChanged: ((GameState) -> Void)? { get set }
    
    func start()
    func update(deltaTime: TimeInterval)
    func handleKeyDown(event: NSEvent) -> Bool
    func handleMouseDown(at point: CGPoint) -> Bool
    func pause()
    func resume()
    func restart()
    func teardown()
}
