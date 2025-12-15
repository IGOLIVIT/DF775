//
//  ProgressManager.swift
//  DF775
//

import SwiftUI
import Combine

class ProgressManager: ObservableObject {
    static let shared = ProgressManager()
    
    private let progressKey = "gameProgressData"
    private let statisticsKey = "overallStatistics"
    private let onboardingKey = "hasCompletedOnboarding"
    private let levelProgressKey = "levelProgressData"
    
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: onboardingKey)
        }
    }
    
    @Published var gameProgress: [String: GameProgress] = [:]
    @Published var levelProgress: [String: LevelProgress] = [:]
    @Published var statistics: OverallStatistics
    
    private init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)
        self.statistics = OverallStatistics()
        loadProgress()
    }
    
    // MARK: - Progress Key Generation
    private func progressKey(for gameType: GameType, difficulty: DifficultyLevel) -> String {
        return "\(gameType.rawValue)_\(difficulty.rawValue)"
    }
    
    private func levelKey(for gameType: GameType, difficulty: DifficultyLevel, level: Int) -> String {
        return "\(gameType.rawValue)_\(difficulty.rawValue)_\(level)"
    }
    
    // MARK: - Load/Save Progress
    private func loadProgress() {
        if let data = UserDefaults.standard.data(forKey: progressKey),
           let decoded = try? JSONDecoder().decode([String: GameProgress].self, from: data) {
            self.gameProgress = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: levelProgressKey),
           let decoded = try? JSONDecoder().decode([String: LevelProgress].self, from: data) {
            self.levelProgress = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: statisticsKey),
           let decoded = try? JSONDecoder().decode(OverallStatistics.self, from: data) {
            self.statistics = decoded
        }
    }
    
    private func saveProgress() {
        if let encoded = try? JSONEncoder().encode(gameProgress) {
            UserDefaults.standard.set(encoded, forKey: progressKey)
        }
        
        if let encoded = try? JSONEncoder().encode(levelProgress) {
            UserDefaults.standard.set(encoded, forKey: levelProgressKey)
        }
        
        if let encoded = try? JSONEncoder().encode(statistics) {
            UserDefaults.standard.set(encoded, forKey: statisticsKey)
        }
    }
    
    // MARK: - Game Progress Methods
    func getProgress(for gameType: GameType, difficulty: DifficultyLevel) -> GameProgress {
        let key = progressKey(for: gameType, difficulty: difficulty)
        if let progress = gameProgress[key] {
            return progress
        }
        let newProgress = GameProgress(gameType: gameType, difficulty: difficulty)
        gameProgress[key] = newProgress
        saveProgress()
        return newProgress
    }
    
    func updateProgress(for gameType: GameType, difficulty: DifficultyLevel, update: (inout GameProgress) -> Void) {
        let key = progressKey(for: gameType, difficulty: difficulty)
        var progress = getProgress(for: gameType, difficulty: difficulty)
        update(&progress)
        gameProgress[key] = progress
        saveProgress()
        objectWillChange.send()
    }
    
    // MARK: - Level Progress Methods
    func getLevelProgress(for gameType: GameType, difficulty: DifficultyLevel, level: Int) -> LevelProgress {
        let key = levelKey(for: gameType, difficulty: difficulty, level: level)
        if let progress = levelProgress[key] {
            return progress
        }
        let newProgress = LevelProgress(gameType: gameType, difficulty: difficulty, levelNumber: level)
        levelProgress[key] = newProgress
        saveProgress()
        return newProgress
    }
    
    func completeLevel(gameType: GameType, difficulty: DifficultyLevel, level: Int, score: Int, rewards: Int) {
        let key = levelKey(for: gameType, difficulty: difficulty, level: level)
        var progress = getLevelProgress(for: gameType, difficulty: difficulty, level: level)
        
        let wasCompleted = progress.isCompleted
        progress.isCompleted = true
        progress.attemptsCount += 1
        if score > progress.bestScore {
            progress.bestScore = score
        }
        
        levelProgress[key] = progress
        
        // Update game progress
        updateProgress(for: gameType, difficulty: difficulty) { gameProgress in
            gameProgress.totalRewards += rewards
            if !wasCompleted {
                gameProgress.levelsCompleted += 1
            }
            if level >= gameProgress.currentLevel && level < difficulty.levelCount {
                gameProgress.currentLevel = level + 1
            }
        }
        
        // Update statistics
        if !wasCompleted {
            statistics.totalLevelsCleared += 1
        }
        statistics.totalRewardsCollected += rewards
        
        // Check if game completed
        let totalLevels = difficulty.levelCount
        let completedLevels = (1...totalLevels).filter { lvl in
            getLevelProgress(for: gameType, difficulty: difficulty, level: lvl).isCompleted
        }.count
        
        if completedLevels == totalLevels && !wasCompleted {
            statistics.totalGamesCompleted += 1
        }
        
        saveProgress()
        objectWillChange.send()
    }
    
    func addPlayTime(_ time: TimeInterval, for gameType: GameType, difficulty: DifficultyLevel) {
        updateProgress(for: gameType, difficulty: difficulty) { progress in
            progress.totalPlayTime += time
        }
        statistics.totalPlayTime += time
        saveProgress()
    }
    
    func isLevelUnlocked(gameType: GameType, difficulty: DifficultyLevel, level: Int) -> Bool {
        if level == 1 { return true }
        let previousLevel = getLevelProgress(for: gameType, difficulty: difficulty, level: level - 1)
        return previousLevel.isCompleted
    }
    
    // MARK: - Overall Progress
    func getOverallProgress(for gameType: GameType) -> Double {
        var totalLevels = 0
        var completedLevels = 0
        
        for difficulty in DifficultyLevel.allCases {
            let levels = difficulty.levelCount
            totalLevels += levels
            
            for level in 1...levels {
                if getLevelProgress(for: gameType, difficulty: difficulty, level: level).isCompleted {
                    completedLevels += 1
                }
            }
        }
        
        return totalLevels > 0 ? Double(completedLevels) / Double(totalLevels) : 0
    }
    
    func getTotalRewards(for gameType: GameType) -> Int {
        var total = 0
        for difficulty in DifficultyLevel.allCases {
            let progress = getProgress(for: gameType, difficulty: difficulty)
            total += progress.totalRewards
        }
        return total
    }
    
    // MARK: - Reset Progress
    func resetAllProgress() {
        gameProgress.removeAll()
        levelProgress.removeAll()
        statistics = OverallStatistics()
        
        UserDefaults.standard.removeObject(forKey: progressKey)
        UserDefaults.standard.removeObject(forKey: levelProgressKey)
        UserDefaults.standard.removeObject(forKey: statisticsKey)
        
        saveProgress()
        objectWillChange.send()
    }
    
    // MARK: - Game Card Data
    func getGameCards() -> [GameCardData] {
        return GameType.allCases.map { gameType in
            GameCardData(
                gameType: gameType,
                progressPercentage: getOverallProgress(for: gameType),
                totalRewards: getTotalRewards(for: gameType)
            )
        }
    }
}

