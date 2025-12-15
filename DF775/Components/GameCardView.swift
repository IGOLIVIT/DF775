//
//  GameCardView.swift
//  DF775
//

import SwiftUI

struct GameCardView: View {
    let gameData: GameCardData
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Header with icon and progress
                HStack(alignment: .top) {
                    // Icon container
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color("AccentPrimary").opacity(0.2),
                                        Color("AccentPrimary").opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                        
                        AnimatedIcon(
                            iconName: gameData.gameType.iconName,
                            color: Color("AccentPrimary")
                        )
                    }
                    
                    Spacer()
                    
                    // Progress ring
                    VStack(alignment: .trailing, spacing: 4) {
                        ProgressRing(progress: gameData.progressPercentage, lineWidth: 3, size: 44)
                            .overlay(
                                Text("\(Int(gameData.progressPercentage * 100))%")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.8))
                            )
                    }
                }
                
                // Title and description
                VStack(alignment: .leading, spacing: 6) {
                    Text(gameData.gameType.title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(gameData.gameType.description)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Rewards indicator
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color("AccentSecondary"))
                    
                    Text("\(gameData.totalRewards) \(gameData.gameType.rewardName)")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(Color("AccentSecondary"))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(20)
            .background(CardBackground(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color("AccentPrimary").opacity(isHovered ? 0.4 : 0),
                                Color("AccentSecondary").opacity(isHovered ? 0.2 : 0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(GameCardStyle())
    }
}

// MARK: - Level Card View
struct LevelCardView: View {
    let level: Int
    let isCompleted: Bool
    let isUnlocked: Bool
    let bestScore: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                GeometryReader { geometry in
                    let size = min(geometry.size.width, geometry.size.height)
                    
                    ZStack {
                        Circle()
                            .fill(backgroundColor)
                            .frame(width: size, height: size)
                        
                        if isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: size * 0.35, weight: .bold))
                                .foregroundColor(.white)
                        } else if !isUnlocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: size * 0.3, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        } else {
                            Text("\(level)")
                                .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                    .overlay(
                        Circle()
                            .stroke(borderColor, lineWidth: 2)
                    )
                    .frame(width: size, height: size)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
                .aspectRatio(1, contentMode: .fit)
                
                if isCompleted && bestScore > 0 {
                    Text("\(bestScore)")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(Color("AccentSecondary"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                } else {
                    Text("Lv.\(level)")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }
            }
        }
        .disabled(!isUnlocked)
        .opacity(isUnlocked ? 1.0 : 0.5)
    }
    
    private var backgroundColor: Color {
        if isCompleted {
            return Color("AccentPrimary").opacity(0.3)
        } else if isUnlocked {
            return Color("BackgroundSecondary")
        } else {
            return Color("BackgroundPrimary").opacity(0.5)
        }
    }
    
    private var borderColor: Color {
        if isCompleted {
            return Color("AccentPrimary")
        } else if isUnlocked {
            return Color("AccentSecondary").opacity(0.5)
        } else {
            return Color.white.opacity(0.1)
        }
    }
}

// MARK: - Difficulty Card View
struct DifficultyCardView: View {
    let difficulty: DifficultyLevel
    let progress: GameProgress
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(difficulty.rawValue)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(difficulty.description)
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(progress.levelsCompleted)/\(difficulty.levelCount)")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(Color("AccentSecondary"))
                        
                        Text("Levels")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [Color("AccentPrimary"), Color("AccentSecondary")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progressPercentage, height: 6)
                    }
                }
                .frame(height: 6)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("BackgroundSecondary"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Color("AccentPrimary") : Color.white.opacity(0.1),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(GameCardStyle())
    }
    
    private var progressPercentage: CGFloat {
        guard difficulty.levelCount > 0 else { return 0 }
        return CGFloat(progress.levelsCompleted) / CGFloat(difficulty.levelCount)
    }
}

