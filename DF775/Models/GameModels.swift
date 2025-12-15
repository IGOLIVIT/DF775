//
//  GameModels.swift
//  DF775
//

import SwiftUI

// MARK: - Difficulty Level
enum DifficultyLevel: String, CaseIterable, Codable {
    case initiate = "Initiate"
    case adept = "Adept"
    case master = "Master"
    
    var description: String {
        switch self {
        case .initiate: return "Begin your journey"
        case .adept: return "Test your skills"
        case .master: return "Prove your mastery"
        }
    }
    
    var levelCount: Int {
        switch self {
        case .initiate: return 5
        case .adept: return 7
        case .master: return 10
        }
    }
    
    var speedMultiplier: Double {
        switch self {
        case .initiate: return 1.0
        case .adept: return 1.5
        case .master: return 2.0
        }
    }
    
    var complexityMultiplier: Int {
        switch self {
        case .initiate: return 1
        case .adept: return 2
        case .master: return 3
        }
    }
}

// MARK: - Game Type
enum GameType: String, CaseIterable, Codable, Identifiable {
    case pulseSync = "pulse_sync"
    case pathWeaver = "path_weaver"
    case signalFlow = "signal_flow"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .pulseSync: return "Catch the Beat"
        case .pathWeaver: return "Mind Trace"
        case .signalFlow: return "Route Master"
        }
    }
    
    var description: String {
        switch self {
        case .pulseSync: return "Hit the zone at the right moment"
        case .pathWeaver: return "Remember and repeat the sequence"
        case .signalFlow: return "Find your way through the grid"
        }
    }
    
    var iconName: String {
        switch self {
        case .pulseSync: return "waveform.circle.fill"
        case .pathWeaver: return "square.grid.3x3.fill"
        case .signalFlow: return "arrow.triangle.branch"
        }
    }
    
    var rewardName: String {
        switch self {
        case .pulseSync: return "Sparks"
        case .pathWeaver: return "Shards"
        case .signalFlow: return "Points"
        }
    }
}

// MARK: - Level Progress
struct LevelProgress: Codable, Identifiable {
    var id: String { "\(gameType.rawValue)_\(difficulty.rawValue)_\(levelNumber)" }
    let gameType: GameType
    let difficulty: DifficultyLevel
    let levelNumber: Int
    var isCompleted: Bool
    var bestScore: Int
    var attemptsCount: Int
    
    init(gameType: GameType, difficulty: DifficultyLevel, levelNumber: Int) {
        self.gameType = gameType
        self.difficulty = difficulty
        self.levelNumber = levelNumber
        self.isCompleted = false
        self.bestScore = 0
        self.attemptsCount = 0
    }
}

// MARK: - Game Progress
struct GameProgress: Codable {
    var gameType: GameType
    var difficulty: DifficultyLevel
    var currentLevel: Int
    var totalRewards: Int
    var levelsCompleted: Int
    var totalPlayTime: TimeInterval
    
    init(gameType: GameType, difficulty: DifficultyLevel) {
        self.gameType = gameType
        self.difficulty = difficulty
        self.currentLevel = 1
        self.totalRewards = 0
        self.levelsCompleted = 0
        self.totalPlayTime = 0
    }
}

// MARK: - Overall Statistics
struct OverallStatistics: Codable {
    var totalGamesCompleted: Int
    var totalLevelsCleared: Int
    var totalPlayTime: TimeInterval
    var totalRewardsCollected: Int
    
    init() {
        self.totalGamesCompleted = 0
        self.totalLevelsCleared = 0
        self.totalPlayTime = 0
        self.totalRewardsCollected = 0
    }
    
    var formattedPlayTime: String {
        let hours = Int(totalPlayTime) / 3600
        let minutes = (Int(totalPlayTime) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Game Card Data
struct GameCardData: Identifiable {
    let id = UUID()
    let gameType: GameType
    var progressPercentage: Double
    var totalRewards: Int
    
    init(gameType: GameType, progressPercentage: Double = 0, totalRewards: Int = 0) {
        self.gameType = gameType
        self.progressPercentage = progressPercentage
        self.totalRewards = totalRewards
    }
}

