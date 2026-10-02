import Foundation

/// Defines all supported games in the AHK Mini Arcade.
enum GameType: String, CaseIterable {
    case runner = "runner"
    case space = "space"
    case hop = "hop"
    case racer = "racer"
    case breakOut = "break"
    case snake = "snake"
    case pong = "pong"
    case memory = "memory"
    
    var displayName: String {
        switch self {
        case .runner: return "Runner"
        case .space: return "Space"
        case .hop: return "Hop"
        case .racer: return "Racer"
        case .breakOut: return "Break"
        case .snake: return "Snake"
        case .pong: return "Pong"
        case .memory: return "Memory"
        }
    }
    
    var icon: String {
        switch self {
        case .runner: return "🦖"
        case .space: return "🚀"
        case .hop: return "🐦"
        case .racer: return "🏎"
        case .breakOut: return "🧱"
        case .snake: return "🐍"
        case .pong: return "🏓"
        case .memory: return "🧠"
        }
    }
}

/// Manages local high-score persistence for all AHK Mini Arcade games.
/// Strictly uses local UserDefaults with zero cloud or network sync.
final class ScoreStore {
    static let shared = ScoreStore()
    
    private let userDefaults: UserDefaults
    private let legacyKey = "com.ahk.mini.highScore"
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        migrateLegacyScoreIfNeeded()
    }
    
    private func defaultsKey(for game: GameType) -> String {
        return "com.ahk.mini.highScore.\(game.rawValue)"
    }
    
    private func migrateLegacyScoreIfNeeded() {
        let legacyScore = userDefaults.integer(forKey: legacyKey)
        let runnerKey = defaultsKey(for: .runner)
        if legacyScore > 0 && userDefaults.integer(forKey: runnerKey) == 0 {
            userDefaults.set(legacyScore, forKey: runnerKey)
        }
    }
    
    /// Returns the persisted high score for a given game.
    func highScore(for game: GameType) -> Int {
        return userDefaults.integer(forKey: defaultsKey(for: game))
    }
    
    /// Updates the high score if the new score exceeds the current record.
    /// Returns `true` if a new high score was set.
    @discardableResult
    func record(score: Int, for game: GameType) -> Bool {
        let current = highScore(for: game)
        guard score > current else { return false }
        userDefaults.set(score, forKey: defaultsKey(for: game))
        return true
    }
    
    /// Resets high score for a specific game (for testing/debug).
    func reset(for game: GameType) {
        userDefaults.removeObject(forKey: defaultsKey(for: game))
    }
    
    /// Resets all high scores across all games.
    func resetAll() {
        for game in GameType.allCases {
            reset(for: game)
        }
        userDefaults.removeObject(forKey: legacyKey)
    }
}
