import SpriteKit
import AppKit

enum ArcadeMode {
    case selector
    case inGame
}

/// Orchestrates game selection, modular loading/unloading, and extreme battery conservation.
final class ArcadeManager {
    private(set) var mode: ArcadeMode = .selector
    private(set) var activeGame: MiniGame?
    
    private let sceneSize: CGSize
    private let rootScene: SKScene
    
    private var selectorNode: GameSelectorNode!
    private var hudNode: ArcadeHUDNode!
    
    var onGameSwitched: ((GameType?) -> Void)?
    
    init(scene: SKScene, size: CGSize) {
        self.rootScene = scene
        self.sceneSize = size
        setupUI()
    }
    
    private func setupUI() {
        // Selector Node
        selectorNode = GameSelectorNode(size: sceneSize)
        selectorNode.onSelectGame = { [weak self] selected in
            self?.loadGame(selected)
        }
        rootScene.addChild(selectorNode)
        
        // HUD Node
        hudNode = ArcadeHUDNode(size: sceneSize)
        hudNode.onBackToArcade = { [weak self] in
            self?.returnToSelector()
        }
        hudNode.isHidden = true
        hudNode.zPosition = 100
        rootScene.addChild(hudNode)
        
        mode = .selector
    }
    
    func loadGame(_ type: GameType) {
        // 1. Completely unload previous game
        unloadActiveGame()
        
        // 2. Hide selector, show HUD
        selectorNode.isHidden = true
        hudNode.isHidden = false
        hudNode.configure(for: type)
        
        // 3. Instantiate and wire newly selected game
        let newGame: MiniGame
        switch type {
        case .runner:
            newGame = RunnerGame(size: sceneSize)
        case .space:
            newGame = SpaceGame(size: sceneSize)
        case .hop:
            newGame = HopGame(size: sceneSize)
        case .racer:
            newGame = RacerGame(size: sceneSize)
        case .breakOut:
            newGame = BreakGame(size: sceneSize)
        case .snake:
            newGame = SnakeGame(size: sceneSize)
        case .pong:
            newGame = PongGame(size: sceneSize)
        case .memory:
            newGame = MemoryGame(size: sceneSize)
        }
        
        newGame.onScoreChanged = { [weak self] score in
            self?.hudNode.updateScore(score)
        }
        newGame.onHighScoreChanged = { [weak self] high in
            self?.hudNode.updateHighScore(high)
        }
        newGame.onStateChanged = { [weak self] state in
            guard let self = self, let game = self.activeGame else { return }
            self.hudNode.setOverlay(state: state, gameName: game.gameType.displayName)
        }
        
        rootScene.addChild(newGame.rootNode)
        self.activeGame = newGame
        self.mode = .inGame
        
        newGame.start()
        onGameSwitched?(type)
    }
    
    func returnToSelector() {
        unloadActiveGame()
        hudNode.isHidden = true
        selectorNode.isHidden = false
        mode = .selector
        onGameSwitched?(nil)
    }
    
    private func unloadActiveGame() {
        if let game = activeGame {
            game.teardown()
            game.rootNode.removeFromParent()
            activeGame = nil
        }
    }
    
    func update(deltaTime: TimeInterval) {
        guard mode == .inGame, let game = activeGame, game.state == .running else {
            // When in selector or paused, ZERO work is executed for 0% CPU consumption
            return
        }
        game.update(deltaTime: deltaTime)
    }
    
    func handleKeyDown(event: NSEvent) -> Bool {
        if mode == .selector {
            return selectorNode.handleKeyDown(event: event)
        } else if let game = activeGame {
            // If ESC key in game, check whether to return to selector or toggle pause
            if event.keyCode == 53 {
                returnToSelector()
                return true
            }
            return game.handleKeyDown(event: event)
        }
        return false
    }
    
    func handleMouseDown(at point: CGPoint) -> Bool {
        if mode == .selector {
            return selectorNode.handleMouseDown(at: point)
        } else if mode == .inGame {
            if hudNode.handleMouseDown(at: point) {
                return true
            }
            if let game = activeGame {
                return game.handleMouseDown(at: point)
            }
        }
        return false
    }
    
    func pause() {
        activeGame?.pause()
    }
    
    func resume() {
        activeGame?.resume()
    }
}
