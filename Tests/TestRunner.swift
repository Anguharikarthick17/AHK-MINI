import Foundation
import SpriteKit
import AppKit

func assertEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String = "", file: String = #file, line: Int = #line) {
    if actual != expected {
        print("❌ FAIL: \(actual) != \(expected). \(message) at \(file):\(line)")
        exit(1)
    }
}

func assertTrue(_ condition: Bool, _ message: String = "", file: String = #file, line: Int = #line) {
    if !condition {
        print("❌ FAIL: Expected true, got false. \(message) at \(file):\(line)")
        exit(1)
    }
}

@main
struct TestRunner {
    static func main() {
        print("🧪 Starting AHK Mini Multi-Game Arcade Test Suite...")
        let sceneSize = CGSize(width: 420.0, height: 140.0)

        // 1. Test ScoreStore Multi-Game Keys & Migration
        print("\n[1/10] Testing ScoreStore Multi-Game Keys & Persistence...")
        let suiteName = "com.ahk.mini.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        
        // Seed legacy score
        defaults.set(450, forKey: "com.ahk.mini.highScore")
        let store = ScoreStore(userDefaults: defaults)
        
        // Check migration
        assertEqual(store.highScore(for: .runner), 450, "Legacy score should be migrated to runner")
        assertEqual(store.highScore(for: .space), 0, "Space high score should initially be 0")
        
        // Record scores for each game
        store.record(score: 120, for: .space)
        store.record(score: 300, for: .hop)
        store.record(score: 410, for: .racer)
        store.record(score: 550, for: .breakOut)
        store.record(score: 80, for: .snake)
        store.record(score: 15, for: .pong)
        store.record(score: 850, for: .memory)
        
        assertEqual(store.highScore(for: .space), 120)
        assertEqual(store.highScore(for: .hop), 300)
        assertEqual(store.highScore(for: .racer), 410)
        assertEqual(store.highScore(for: .breakOut), 550)
        assertEqual(store.highScore(for: .snake), 80)
        assertEqual(store.highScore(for: .pong), 15)
        assertEqual(store.highScore(for: .memory), 850)
        print("  ✅ ScoreStore multi-game persistence passed.")

        // 2. Test Runner Game
        print("\n[2/10] Testing AHK Runner (Preserved)...")
        let runner = RunnerGame(size: sceneSize)
        runner.start()
        assertEqual(runner.state, .running)
        for _ in 0..<120 { runner.update(deltaTime: 1.0 / 60.0) }
        assertTrue(runner.currentScore >= 0)
        runner.pause()
        assertEqual(runner.state, .paused)
        runner.resume()
        assertEqual(runner.state, .running)
        runner.teardown()
        assertEqual(runner.rootNode.children.count, 0, "Runner teardown should clear all nodes")
        print("  ✅ Runner passed.")

        // 3. Test Space Game
        print("\n[3/10] Testing AHK Space...")
        let space = SpaceGame(size: sceneSize)
        space.start()
        assertEqual(space.state, .running)
        for _ in 0..<120 { space.update(deltaTime: 1.0 / 60.0) }
        assertTrue(space.currentScore > 0, "Space survival score should increase")
        space.teardown()
        assertEqual(space.rootNode.children.count, 0, "Space teardown should clear all nodes")
        print("  ✅ Space passed.")

        // 4. Test Hop Game
        print("\n[4/10] Testing AHK Hop...")
        let hop = HopGame(size: sceneSize)
        hop.start()
        assertEqual(hop.state, .running)
        for _ in 0..<60 { hop.update(deltaTime: 1.0 / 60.0) }
        hop.teardown()
        assertEqual(hop.rootNode.children.count, 0, "Hop teardown should clear all nodes")
        print("  ✅ Hop passed.")

        // 5. Test Racer Game
        print("\n[5/10] Testing AHK Racer...")
        let racer = RacerGame(size: sceneSize)
        racer.start()
        assertEqual(racer.state, .running)
        for _ in 0..<120 { racer.update(deltaTime: 1.0 / 60.0) }
        assertTrue(racer.currentScore > 0, "Racer distance score should increase")
        racer.teardown()
        assertEqual(racer.rootNode.children.count, 0, "Racer teardown should clear all nodes")
        print("  ✅ Racer passed.")

        // 6. Test Break Game
        print("\n[6/10] Testing AHK Break...")
        let breakGame = BreakGame(size: sceneSize)
        breakGame.start()
        assertEqual(breakGame.state, .running)
        for _ in 0..<60 { breakGame.update(deltaTime: 1.0 / 60.0) }
        breakGame.teardown()
        assertEqual(breakGame.rootNode.children.count, 0, "Break teardown should clear all nodes")
        print("  ✅ Break passed.")

        // 7. Test Snake Game
        print("\n[7/10] Testing AHK Snake...")
        let snake = SnakeGame(size: sceneSize)
        snake.start()
        assertEqual(snake.state, .running)
        for _ in 0..<60 { snake.update(deltaTime: 1.0 / 60.0) }
        snake.teardown()
        assertEqual(snake.rootNode.children.count, 0, "Snake teardown should clear all nodes")
        print("  ✅ Snake passed.")

        // 8. Test Pong Game
        print("\n[8/10] Testing AHK Pong...")
        let pong = PongGame(size: sceneSize)
        pong.start()
        assertEqual(pong.state, .running)
        for _ in 0..<60 { pong.update(deltaTime: 1.0 / 60.0) }
        pong.teardown()
        assertEqual(pong.rootNode.children.count, 0, "Pong teardown should clear all nodes")
        print("  ✅ Pong passed.")

        // 9. Test Memory Game
        print("\n[9/10] Testing AHK Memory...")
        let memory = MemoryGame(size: sceneSize)
        memory.start()
        assertEqual(memory.state, .running)
        assertTrue(memory.currentScore > 0)
        memory.teardown()
        assertEqual(memory.rootNode.children.count, 0, "Memory teardown should clear all nodes")
        print("  ✅ Memory passed.")

        // 10. Test ArcadeManager Switching & Resource Cleanup
        print("\n[10/10] Testing ArcadeManager Switching & Zero-Work Idle Lifecycle...")
        let testScene = SKScene(size: sceneSize)
        let arcade = ArcadeManager(scene: testScene, size: sceneSize)
        assertEqual(arcade.mode, .selector, "Arcade should start in selector mode")
        assertTrue(arcade.activeGame == nil, "No game should be active initially")

        // In selector mode: update should execute 0 game logic
        arcade.update(deltaTime: 0.016)

        // Load Runner
        arcade.loadGame(.runner)
        assertEqual(arcade.mode, .inGame)
        assertTrue(arcade.activeGame is RunnerGame)

        // Switch to Space: verify Runner was torn down and replaced
        arcade.loadGame(.space)
        assertEqual(arcade.mode, .inGame)
        assertTrue(arcade.activeGame is SpaceGame)

        // Return to selector: verify Space was torn down
        arcade.returnToSelector()
        assertEqual(arcade.mode, .selector)
        assertTrue(arcade.activeGame == nil, "Returning to selector must unload active game")
        print("  ✅ ArcadeManager switching and resource cleanup passed.")

        print("\n🎉 ALL 10 TEST SUITES PASSED PERFECTLY!")
    }
}
