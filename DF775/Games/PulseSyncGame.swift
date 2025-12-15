//
//  PulseSyncGame.swift
//  DF775
//

import SwiftUI

// MARK: - Pulse Sync Game View
struct PulseSyncGameView: View {
    let difficulty: DifficultyLevel
    let level: Int
    let onComplete: (Int, Int) -> Void // (score, rewards)
    let onExit: () -> Void
    
    @State private var gameState: PulseSyncState = .ready
    @State private var pulsePosition: CGFloat = 0
    @State private var targetZoneStart: CGFloat = 0.35
    @State private var targetZoneWidth: CGFloat = 0.3
    @State private var score: Int = 0
    @State private var currentRound: Int = 0
    @State private var totalRounds: Int = 5
    @State private var hitResults: [HitResult] = []
    @State private var showFeedback = false
    @State private var feedbackType: FeedbackType = .perfect
    @State private var isPulsing = false
    @State private var animationStartTime: Date = Date()
    @State private var timer: Timer?
    
    private let pulseSpeed: Double
    private let successThreshold: Int
    
    init(difficulty: DifficultyLevel, level: Int, onComplete: @escaping (Int, Int) -> Void, onExit: @escaping () -> Void) {
        self.difficulty = difficulty
        self.level = level
        self.onComplete = onComplete
        self.onExit = onExit
        
        // Configure based on difficulty and level - slower speeds for playability
        let baseSpeed = 2.5 - (Double(level) * 0.05)
        self.pulseSpeed = max(1.2, baseSpeed / difficulty.speedMultiplier)
        
        // Lower threshold - need only ~50% success rate
        self.successThreshold = 2 + (difficulty.complexityMultiplier - 1)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color("BackgroundPrimary").ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Header
                    headerView
                    
                    Spacer()
                    
                    // Game area
                    gameAreaView(in: geometry)
                    
                    Spacer()
                    
                    // Action button
                    actionButton
                    
                    // Round indicators
                    roundIndicators
                        .padding(.bottom, 20)
                }
                .padding(.horizontal, 24)
                
                // Feedback overlay
                if showFeedback {
                    feedbackOverlay
                }
            }
        }
        .onAppear {
            setupGame()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Button(action: {
                timer?.invalidate()
                onExit()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color("BackgroundSecondary")))
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("Level \(level)")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                
                Text("\(score)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Placeholder for balance
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Game Area View
    private func gameAreaView(in geometry: GeometryProxy) -> some View {
        let barWidth = geometry.size.width - 48
        
        return VStack(spacing: 40) {
            // Instructions
            Text(instructionText)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .frame(height: 20)
            
            // Pulse bar
            ZStack(alignment: .leading) {
                // Background bar
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("BackgroundSecondary"))
                    .frame(height: 60)
                
                // Target zone
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color("AccentPrimary").opacity(0.3),
                                Color("AccentPrimary").opacity(0.5),
                                Color("AccentPrimary").opacity(0.3)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: barWidth * targetZoneWidth, height: 52)
                    .offset(x: barWidth * targetZoneStart + 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color("AccentPrimary"), lineWidth: 2)
                            .frame(width: barWidth * targetZoneWidth, height: 52)
                            .offset(x: barWidth * targetZoneStart + 4)
                    )
                
                // Pulse indicator
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color("AccentSecondary"),
                                Color("AccentSecondary").opacity(0.8)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 20
                        )
                    )
                    .frame(width: 40, height: 40)
                    .shadow(color: Color("AccentSecondary").opacity(0.6), radius: 10)
                    .offset(x: (barWidth - 40) * pulsePosition + 10)
                    .scaleEffect(isPulsing ? 1.1 : 1.0)
            }
            .frame(width: barWidth)
        }
    }
    
    private var instructionText: String {
        switch gameState {
        case .ready:
            return "Tap START, then tap when ball is in red zone"
        case .playing:
            return "TAP NOW!"
        case .finished:
            return ""
        }
    }
    
    // MARK: - Action Button
    private var actionButton: some View {
        Button(action: handleTap) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color("AccentPrimary"),
                                Color("AccentPrimary").opacity(0.8)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: Color("AccentPrimary").opacity(0.4), radius: 20)
                
                Text(buttonText)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .disabled(gameState == .finished)
    }
    
    private var buttonText: String {
        switch gameState {
        case .ready: return "START"
        case .playing: return "TAP!"
        case .finished: return "DONE"
        }
    }
    
    // MARK: - Round Indicators
    private var roundIndicators: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalRounds, id: \.self) { index in
                Circle()
                    .fill(roundIndicatorColor(for: index))
                    .frame(width: 12, height: 12)
            }
        }
    }
    
    private func roundIndicatorColor(for index: Int) -> Color {
        if index < hitResults.count {
            switch hitResults[index] {
            case .perfect: return Color("AccentSecondary")
            case .good: return Color("AccentPrimary")
            case .miss: return Color("AccentPrimaryDim")
            }
        } else if index == currentRound && gameState == .playing {
            return Color.white.opacity(0.5)
        } else {
            return Color.white.opacity(0.2)
        }
    }
    
    // MARK: - Feedback Overlay
    private var feedbackOverlay: some View {
        VStack {
            Text(feedbackType.text)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(feedbackType.color)
                .shadow(color: feedbackType.color.opacity(0.5), radius: 20)
            
            Text(feedbackType.points)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundColor(feedbackType.color.opacity(0.8))
        }
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Game Logic
    private func setupGame() {
        // Fewer rounds for easier completion
        totalRounds = 4 + (level > 3 ? 1 : 0) + (difficulty == .master ? 1 : 0)
        updateTargetZone()
    }
    
    private func updateTargetZone() {
        // Larger target zone for easier gameplay
        let baseWidth: CGFloat = 0.35
        let reduction = CGFloat(level - 1) * 0.01 + CGFloat(difficulty.complexityMultiplier - 1) * 0.02
        targetZoneWidth = max(0.18, baseWidth - reduction)
        
        // Random position ensuring zone fits within bar
        let maxStart = 1.0 - targetZoneWidth - 0.02
        targetZoneStart = CGFloat.random(in: 0.02...maxStart)
    }
    
    private func handleTap() {
        switch gameState {
        case .ready:
            startRound()
        case .playing:
            checkHit()
        case .finished:
            break
        }
    }
    
    private func startRound() {
        gameState = .playing
        pulsePosition = 0
        animationStartTime = Date()
        
        // Use Timer to track actual position instead of relying on animation
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [self] t in
            let elapsed = Date().timeIntervalSince(animationStartTime)
            let progress = min(1.0, elapsed / pulseSpeed)
            
            DispatchQueue.main.async {
                self.pulsePosition = CGFloat(progress)
                
                if progress >= 1.0 {
                    t.invalidate()
                    // Auto-miss if pulse reaches end without tap
                    if self.gameState == .playing {
                        self.registerHit(.miss, points: 0)
                    }
                }
            }
        }
        
        withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
            isPulsing = true
        }
    }
    
    private func checkHit() {
        timer?.invalidate()
        
        // Check if pulse is within target zone
        let pulseCenter = pulsePosition
        let zoneEnd = targetZoneStart + targetZoneWidth
        
        let inZone = pulseCenter >= targetZoneStart && pulseCenter <= zoneEnd
        
        if inZone {
            // Calculate how centered the hit was
            let zoneCenter = targetZoneStart + targetZoneWidth / 2
            let distanceFromCenter = abs(pulseCenter - zoneCenter)
            let perfectThreshold = targetZoneWidth * 0.3
            
            if distanceFromCenter < perfectThreshold {
                registerHit(.perfect, points: 100)
            } else {
                registerHit(.good, points: 50)
            }
        } else {
            registerHit(.miss, points: 0)
        }
    }
    
    private func registerHit(_ result: HitResult, points: Int) {
        hitResults.append(result)
        score += points
        feedbackType = FeedbackType(from: result)
        
        withAnimation(.spring(response: 0.3)) {
            showFeedback = true
        }
        
        isPulsing = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation {
                showFeedback = false
            }
            
            currentRound += 1
            
            if currentRound >= totalRounds {
                finishGame()
            } else {
                pulsePosition = 0
                updateTargetZone()
                
                // Small delay before next round
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    startRound()
                }
            }
        }
    }
    
    private func finishGame() {
        gameState = .finished
        timer?.invalidate()
        
        let successfulHits = hitResults.filter { $0 != .miss }.count
        let isSuccess = successfulHits >= successThreshold
        let rewards = isSuccess ? (10 + level * 2 + difficulty.complexityMultiplier * 5) : 0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if isSuccess {
                onComplete(score, rewards)
            } else {
                onExit()
            }
        }
    }
}

// MARK: - Supporting Types
enum PulseSyncState {
    case ready
    case playing
    case finished
}

enum HitResult {
    case perfect
    case good
    case miss
}

enum FeedbackType {
    case perfect
    case good
    case miss
    
    init(from result: HitResult) {
        switch result {
        case .perfect: self = .perfect
        case .good: self = .good
        case .miss: self = .miss
        }
    }
    
    var text: String {
        switch self {
        case .perfect: return "PERFECT"
        case .good: return "GOOD"
        case .miss: return "MISS"
        }
    }
    
    var points: String {
        switch self {
        case .perfect: return "+100"
        case .good: return "+50"
        case .miss: return "+0"
        }
    }
    
    var color: Color {
        switch self {
        case .perfect: return Color("AccentSecondary")
        case .good: return Color("AccentPrimary")
        case .miss: return Color("AccentPrimaryDim")
        }
    }
}
