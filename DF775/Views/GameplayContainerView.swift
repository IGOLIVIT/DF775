//
//  GameplayContainerView.swift
//  DF775
//

import SwiftUI

struct GameplayContainerView: View {
    let gameType: GameType
    let difficulty: DifficultyLevel
    let level: Int
    @ObservedObject var progressManager: ProgressManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showCompletionScreen = false
    @State private var finalScore: Int = 0
    @State private var earnedRewards: Int = 0
    @State private var gameStartTime = Date()
    
    var body: some View {
        ZStack {
            // Game view based on type
            gameView
            
            // Completion overlay
            if showCompletionScreen {
                completionOverlay
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            gameStartTime = Date()
        }
    }
    
    // MARK: - Game View
    @ViewBuilder
    private var gameView: some View {
        switch gameType {
        case .pulseSync:
            PulseSyncGameView(
                difficulty: difficulty,
                level: level,
                onComplete: handleGameComplete,
                onExit: handleExit
            )
            
        case .pathWeaver:
            PathWeaverGameView(
                difficulty: difficulty,
                level: level,
                onComplete: handleGameComplete,
                onExit: handleExit
            )
            
        case .signalFlow:
            SignalFlowGameView(
                difficulty: difficulty,
                level: level,
                onComplete: handleGameComplete,
                onExit: handleExit
            )
        }
    }
    
    // MARK: - Completion Overlay
    private var completionOverlay: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.height < 700
            
            ZStack {
                Color("BackgroundPrimary").opacity(0.97).ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: isCompact ? 20 : 28) {
                        Spacer(minLength: isCompact ? 40 : 60)
                        
                        // Success animation
                        successIcon(isCompact: isCompact)
                        
                        // Level complete text
                        VStack(spacing: 6) {
                            Text("Level \(level) Complete")
                                .font(.system(size: isCompact ? 24 : 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text(difficulty.rawValue)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        // Stats
                        statsView(isCompact: isCompact)
                        
                        // Buttons
                        VStack(spacing: 12) {
                            if hasNextLevel {
                                Button(action: continueToNextLevel) {
                                    HStack {
                                        Text("Next Level")
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                }
                                .buttonStyle(PrimaryButtonStyle())
                            }
                            
                            Button(action: { dismiss() }) {
                                Text("Back to Levels")
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: isCompact ? 30 : 50)
                    }
                }
            }
        }
    }
    
    private func successIcon(isCompact: Bool) -> some View {
        let mainSize: CGFloat = isCompact ? 90 : 110
        let ringSpacing: CGFloat = isCompact ? 28 : 35
        
        return ZStack {
            // Outer glow rings
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(
                        Color("AccentSecondary").opacity(0.3 - Double(index) * 0.1),
                        lineWidth: 2
                    )
                    .frame(
                        width: mainSize + CGFloat(index) * ringSpacing,
                        height: mainSize + CGFloat(index) * ringSpacing
                    )
            }
            
            // Main circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color("AccentSecondary").opacity(0.3),
                            Color("AccentSecondary").opacity(0.1)
                        ],
                        center: .center,
                        startRadius: 15,
                        endRadius: mainSize / 2
                    )
                )
                .frame(width: mainSize, height: mainSize)
            
            Image(systemName: "checkmark")
                .font(.system(size: mainSize * 0.4, weight: .bold))
                .foregroundColor(Color("AccentSecondary"))
        }
    }
    
    private func statsView(isCompact: Bool) -> some View {
        HStack(spacing: isCompact ? 24 : 36) {
            VStack(spacing: 6) {
                Text("\(finalScore)")
                    .font(.system(size: isCompact ? 26 : 30, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Score")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: isCompact ? 14 : 16))
                    Text("+\(earnedRewards)")
                        .font(.system(size: isCompact ? 26 : 30, weight: .bold, design: .rounded))
                }
                .foregroundColor(Color("AccentSecondary"))
                
                Text(gameType.rewardName)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.vertical, isCompact ? 12 : 18)
    }
    
    // MARK: - Logic
    private var hasNextLevel: Bool {
        level < difficulty.levelCount
    }
    
    private func handleGameComplete(score: Int, rewards: Int) {
        // Record play time
        let playTime = Date().timeIntervalSince(gameStartTime)
        progressManager.addPlayTime(playTime, for: gameType, difficulty: difficulty)
        
        // Save progress
        progressManager.completeLevel(
            gameType: gameType,
            difficulty: difficulty,
            level: level,
            score: score,
            rewards: rewards
        )
        
        finalScore = score
        earnedRewards = rewards
        
        withAnimation(.spring(response: 0.5)) {
            showCompletionScreen = true
        }
    }
    
    private func handleExit() {
        // Record play time even on exit
        let playTime = Date().timeIntervalSince(gameStartTime)
        progressManager.addPlayTime(playTime, for: gameType, difficulty: difficulty)
        
        dismiss()
    }
    
    private func continueToNextLevel() {
        // Reset state and continue
        showCompletionScreen = false
        gameStartTime = Date()
        
        // Navigate to next level - handled by parent
        dismiss()
    }
}

#Preview {
    if #available(iOS 16.0, *) {
        NavigationStack {
            GameplayContainerView(
                gameType: .pulseSync,
                difficulty: .initiate,
                level: 1,
                progressManager: ProgressManager.shared
            )
        }
    }
}
