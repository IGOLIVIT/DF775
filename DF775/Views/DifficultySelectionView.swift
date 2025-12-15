//
//  DifficultySelectionView.swift
//  DF775
//

import SwiftUI

struct DifficultySelectionView: View {
    let gameType: GameType
    @ObservedObject var progressManager: ProgressManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedDifficulty: DifficultyLevel?
    @State private var animateContent = false
    
    var body: some View {
        ZStack {
            BackgroundGradient()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Game info header
                    gameInfoHeader
                        .padding(.top, 20)
                    
                    // Difficulty selection
                    difficultySection
                    
                    // Continue button
                    if selectedDifficulty != nil {
                        continueButton
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .navigationDestination(item: $selectedDifficulty) { difficulty in
            LevelSelectionView(
                gameType: gameType,
                difficulty: difficulty,
                progressManager: progressManager
            )
        }
        .onAppear {
            withAnimation(.spring(response: 0.6).delay(0.1)) {
                animateContent = true
            }
        }
    }
    
    // MARK: - Game Info Header
    private var gameInfoHeader: some View {
        VStack(spacing: 20) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color("AccentPrimary").opacity(0.3),
                                Color("AccentPrimary").opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: gameType.iconName)
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("AccentPrimary"), Color("AccentSecondary")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .opacity(animateContent ? 1 : 0)
            .scaleEffect(animateContent ? 1 : 0.8)
            
            VStack(spacing: 8) {
                Text(gameType.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(gameType.description)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 20)
        }
    }
    
    // MARK: - Difficulty Section
    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Difficulty")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .opacity(animateContent ? 1 : 0)
            
            VStack(spacing: 12) {
                ForEach(Array(DifficultyLevel.allCases.enumerated()), id: \.element) { index, difficulty in
                    let progress = progressManager.getProgress(for: gameType, difficulty: difficulty)
                    
                    DifficultyCardView(
                        difficulty: difficulty,
                        progress: progress,
                        isSelected: selectedDifficulty == difficulty
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedDifficulty = difficulty
                        }
                    }
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 30)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.1 + 0.2), value: animateContent)
                }
            }
        }
    }
    
    // MARK: - Continue Button
    private var continueButton: some View {
        Button(action: {
            // Navigation is handled by selectedDifficulty
        }) {
            HStack {
                Text("Select Levels")
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .padding(.top, 8)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}

// MARK: - Level Selection View
struct LevelSelectionView: View {
    let gameType: GameType
    let difficulty: DifficultyLevel
    @ObservedObject var progressManager: ProgressManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedLevel: Int?
    @State private var animateLevels = false
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ZStack {
            BackgroundGradient()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    headerView
                        .padding(.top, 20)
                    
                    // Levels grid
                    levelsGrid
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .navigationDestination(item: $selectedLevel) { level in
            GameplayContainerView(
                gameType: gameType,
                difficulty: difficulty,
                level: level,
                progressManager: progressManager
            )
        }
        .onAppear {
            withAnimation(.spring(response: 0.6).delay(0.1)) {
                animateLevels = true
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(gameType.title)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(difficulty.rawValue)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(Color("AccentSecondary"))
                }
                
                Spacer()
                
                // Progress indicator
                let progress = progressManager.getProgress(for: gameType, difficulty: difficulty)
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(progress.levelsCompleted)/\(difficulty.levelCount)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Completed")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(20)
            .background(CardBackground(cornerRadius: 20))
        }
    }
    
    // MARK: - Levels Grid
    private var levelsGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Levels")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(1...difficulty.levelCount, id: \.self) { level in
                    let levelProgress = progressManager.getLevelProgress(for: gameType, difficulty: difficulty, level: level)
                    let isUnlocked = progressManager.isLevelUnlocked(gameType: gameType, difficulty: difficulty, level: level)
                    
                    LevelCardView(
                        level: level,
                        isCompleted: levelProgress.isCompleted,
                        isUnlocked: isUnlocked,
                        bestScore: levelProgress.bestScore
                    ) {
                        selectedLevel = level
                    }
                    .opacity(animateLevels ? 1 : 0)
                    .scaleEffect(animateLevels ? 1 : 0.8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(level - 1) * 0.05), value: animateLevels)
                }
            }
            .padding(20)
            .background(CardBackground(cornerRadius: 24))
        }
    }
}

#Preview {
    if #available(iOS 16.0, *) {
        NavigationStack {
            DifficultySelectionView(gameType: .pulseSync, progressManager: ProgressManager.shared)
        }
    }
}

