//
//  PathWeaverGame.swift
//  DF775
//

import SwiftUI

// MARK: - Path Weaver Game View
struct PathWeaverGameView: View {
    let difficulty: DifficultyLevel
    let level: Int
    let onComplete: (Int, Int) -> Void
    let onExit: () -> Void
    
    @State private var gameState: PathWeaverState = .showing
    @State private var gridSize: Int = 3
    @State private var pattern: [Int] = []
    @State private var playerPattern: [Int] = []
    @State private var currentShowingIndex: Int = -1
    @State private var score: Int = 0
    @State private var currentRound: Int = 1
    @State private var totalRounds: Int = 5
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorTile: Int = -1
    
    private let patternLength: Int
    private let showDelay: Double
    
    init(difficulty: DifficultyLevel, level: Int, onComplete: @escaping (Int, Int) -> Void, onExit: @escaping () -> Void) {
        self.difficulty = difficulty
        self.level = level
        self.onComplete = onComplete
        self.onExit = onExit
        
        // Configure based on difficulty and level - more reasonable pattern lengths
        let baseLength = 3 + (level - 1) / 3
        self.patternLength = min(6, baseLength + (difficulty.complexityMultiplier - 1))
        self.showDelay = max(0.5, 0.9 - Double(difficulty.complexityMultiplier - 1) * 0.1)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.height < 700
            
            ZStack {
                Color("BackgroundPrimary").ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: isCompact ? 16 : 24) {
                        // Header
                        headerView(isCompact: isCompact)
                        
                        // Instructions
                        instructionText
                        
                        // Game grid
                        gameGrid(in: geometry)
                        
                        // Progress
                        progressView
                            .padding(.vertical, isCompact ? 12 : 20)
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20)
                }
                
                // Success/Error overlay
                if showSuccess {
                    successOverlay
                }
                
                if showError {
                    errorOverlay
                }
            }
        }
        .onAppear {
            setupGame()
        }
    }
    
    // MARK: - Header View
    private func headerView(isCompact: Bool) -> some View {
        HStack {
            Button(action: onExit) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color("BackgroundSecondary")))
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("Round \(currentRound)/\(totalRounds)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                
                Text("\(score)")
                    .font(.system(size: isCompact ? 24 : 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.top, isCompact ? 12 : 20)
    }
    
    // MARK: - Instruction Text
    private var instructionText: some View {
        Text(instructionMessage)
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .foregroundColor(.white.opacity(0.7))
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
    
    private var instructionMessage: String {
        switch gameState {
        case .showing:
            return "Watch the pattern..."
        case .input:
            return "Repeat the pattern"
        case .success:
            return "Perfect!"
        case .failed:
            return "Wrong tile!"
        case .finished:
            return "Complete!"
        }
    }
    
    // MARK: - Game Grid
    private func gameGrid(in geometry: GeometryProxy) -> some View {
        let horizontalPadding: CGFloat = 40 + 32 // outer padding + card padding
        let availableWidth = geometry.size.width - horizontalPadding
        let maxGridWidth: CGFloat = 280
        let gridWidth = min(availableWidth, maxGridWidth)
        let spacing: CGFloat = 10
        let tileSize = (gridWidth - CGFloat(gridSize - 1) * spacing) / CGFloat(gridSize)
        
        return VStack(spacing: spacing) {
            ForEach(0..<gridSize, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(0..<gridSize, id: \.self) { col in
                        let index = row * gridSize + col
                        TileView(
                            index: index,
                            isHighlighted: isTileHighlighted(index),
                            isError: errorTile == index,
                            isInteractive: gameState == .input,
                            size: tileSize
                        ) {
                            handleTileTap(index)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(CardBackground(cornerRadius: 20))
    }
    
    private func isTileHighlighted(_ index: Int) -> Bool {
        if gameState == .showing && currentShowingIndex >= 0 {
            return pattern.indices.contains(currentShowingIndex) && pattern[currentShowingIndex] == index
        }
        if gameState == .input {
            return playerPattern.contains(index)
        }
        return false
    }
    
    // MARK: - Progress View
    private var progressView: some View {
        VStack(spacing: 8) {
            Text("Pattern: \(playerPattern.count)/\(patternLength)")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
            
            HStack(spacing: 6) {
                ForEach(0..<patternLength, id: \.self) { index in
                    Circle()
                        .fill(progressDotColor(for: index))
                        .frame(width: 10, height: 10)
                }
            }
        }
    }
    
    private func progressDotColor(for index: Int) -> Color {
        if gameState == .showing {
            if index <= currentShowingIndex {
                return Color("AccentPrimary")
            }
            return Color.white.opacity(0.2)
        } else {
            if index < playerPattern.count {
                return Color("AccentSecondary")
            }
            return Color.white.opacity(0.2)
        }
    }
    
    // MARK: - Overlays
    private var successOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(Color("AccentSecondary"))
            
            Text("+\(calculateRoundScore())")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(Color("AccentSecondary"))
        }
        .padding(30)
        .background(Color("BackgroundPrimary").opacity(0.9))
        .cornerRadius(20)
        .transition(.scale.combined(with: .opacity))
    }
    
    private var errorOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(Color("AccentPrimaryDim"))
            
            Text("Wrong tile")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Color("AccentPrimaryDim"))
        }
        .padding(30)
        .background(Color("BackgroundPrimary").opacity(0.9))
        .cornerRadius(20)
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Game Logic
    private func setupGame() {
        // Keep grid size reasonable - max 4x4
        gridSize = 3
        if level > 4 && difficulty != .initiate {
            gridSize = 4
        }
        
        totalRounds = 3 + level / 3
        generatePattern()
        
        // Start showing pattern after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showPattern()
        }
    }
    
    private func generatePattern() {
        pattern = []
        let totalTiles = gridSize * gridSize
        
        for _ in 0..<patternLength {
            var newTile: Int
            repeat {
                newTile = Int.random(in: 0..<totalTiles)
            } while pattern.last == newTile // Avoid immediate repeats
            pattern.append(newTile)
        }
    }
    
    private func showPattern() {
        gameState = .showing
        currentShowingIndex = -1
        
        for i in 0..<pattern.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + showDelay * Double(i + 1)) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentShowingIndex = i
                }
                
                // Unhighlight after showing
                DispatchQueue.main.asyncAfter(deadline: .now() + showDelay * 0.5) {
                    if i == pattern.count - 1 {
                        // Last one - transition to input
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                currentShowingIndex = -1
                                gameState = .input
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func handleTileTap(_ index: Int) {
        guard gameState == .input else { return }
        
        let expectedIndex = playerPattern.count
        guard expectedIndex < pattern.count else { return }
        
        if pattern[expectedIndex] == index {
            // Correct
            withAnimation(.spring(response: 0.2)) {
                playerPattern.append(index)
            }
            
            if playerPattern.count == pattern.count {
                // Round complete
                handleRoundSuccess()
            }
        } else {
            // Wrong
            handleRoundFailure(wrongTile: index)
        }
    }
    
    private func handleRoundSuccess() {
        gameState = .success
        let roundScore = calculateRoundScore()
        score += roundScore
        
        withAnimation(.spring(response: 0.3)) {
            showSuccess = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                showSuccess = false
            }
            
            currentRound += 1
            
            if currentRound > totalRounds {
                finishGame(success: true)
            } else {
                playerPattern = []
                generatePattern()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showPattern()
                }
            }
        }
    }
    
    private func handleRoundFailure(wrongTile: Int) {
        gameState = .failed
        errorTile = wrongTile
        
        withAnimation(.spring(response: 0.3)) {
            showError = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                showError = false
                errorTile = -1
            }
            
            finishGame(success: false)
        }
    }
    
    private func calculateRoundScore() -> Int {
        return patternLength * 20 + currentRound * 10 + difficulty.complexityMultiplier * 15
    }
    
    private func finishGame(success: Bool) {
        gameState = .finished
        
        let rewards = success ? (15 + level * 3 + difficulty.complexityMultiplier * 5) : 0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if success {
                onComplete(score, rewards)
            } else {
                onExit()
            }
        }
    }
}

// MARK: - Tile View
struct TileView: View {
    let index: Int
    let isHighlighted: Bool
    let isError: Bool
    let isInteractive: Bool
    let size: CGFloat
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            RoundedRectangle(cornerRadius: 12)
                .fill(tileColor)
                .frame(width: size, height: size)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderColor, lineWidth: 2)
                )
                .shadow(color: shadowColor, radius: isHighlighted ? 8 : 0)
                .scaleEffect(isHighlighted ? 1.05 : 1.0)
                .animation(.spring(response: 0.2), value: isHighlighted)
        }
        .disabled(!isInteractive)
    }
    
    private var tileColor: Color {
        if isError {
            return Color("AccentPrimaryDim")
        }
        if isHighlighted {
            return Color("AccentPrimary")
        }
        return Color("BackgroundSecondary")
    }
    
    private var borderColor: Color {
        if isError {
            return Color("AccentPrimary")
        }
        if isHighlighted {
            return Color("AccentSecondary")
        }
        return Color.white.opacity(0.1)
    }
    
    private var shadowColor: Color {
        if isHighlighted {
            return Color("AccentPrimary").opacity(0.5)
        }
        return Color.clear
    }
}

// MARK: - Supporting Types
enum PathWeaverState {
    case showing
    case input
    case success
    case failed
    case finished
}
