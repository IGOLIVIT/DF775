//
//  SettingsView.swift
//  DF775
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var progressManager: ProgressManager
    @Environment(\.dismiss) private var dismiss
    @State private var showResetConfirmation = false
    @State private var animateStats = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundGradient()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Statistics section
                        statisticsSection
                            .opacity(animateStats ? 1 : 0)
                            .offset(y: animateStats ? 0 : 20)
                        
                        // Per-game stats
                        gameStatsSection
                            .opacity(animateStats ? 1 : 0)
                            .offset(y: animateStats ? 0 : 20)
                            .animation(.spring(response: 0.6).delay(0.1), value: animateStats)
                        
                        // Reset section
                        resetSection
                            .opacity(animateStats ? 1 : 0)
                            .offset(y: animateStats ? 0 : 20)
                            .animation(.spring(response: 0.6).delay(0.2), value: animateStats)
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .alert("Reset Progress", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    progressManager.resetAllProgress()
                }
            } message: {
                Text("This will permanently delete all your progress, statistics, and rewards. This action cannot be undone.")
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6)) {
                animateStats = true
            }
        }
    }
    
    // MARK: - Statistics Section
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overall Statistics")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            VStack(spacing: 0) {
                StatRow(
                    icon: "gamecontroller.fill",
                    label: "Games Completed",
                    value: "\(progressManager.statistics.totalGamesCompleted)",
                    color: Color("AccentPrimary")
                )
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                StatRow(
                    icon: "flag.checkered",
                    label: "Levels Cleared",
                    value: "\(progressManager.statistics.totalLevelsCleared)",
                    color: Color("AccentSecondary")
                )
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                StatRow(
                    icon: "clock.fill",
                    label: "Time Played",
                    value: progressManager.statistics.formattedPlayTime,
                    color: Color("AccentPrimary")
                )
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                StatRow(
                    icon: "sparkles",
                    label: "Rewards Collected",
                    value: "\(progressManager.statistics.totalRewardsCollected)",
                    color: Color("AccentSecondary")
                )
            }
            .padding(16)
            .background(CardBackground(cornerRadius: 20))
        }
    }
    
    // MARK: - Game Stats Section
    private var gameStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Game Progress")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(GameType.allCases, id: \.rawValue) { gameType in
                    GameStatCard(
                        gameType: gameType,
                        progress: progressManager.getOverallProgress(for: gameType),
                        rewards: progressManager.getTotalRewards(for: gameType)
                    )
                }
            }
        }
    }
    
    // MARK: - Reset Section
    private var resetSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Data")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Button(action: { showResetConfirmation = true }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 18, weight: .medium))
                    
                    Text("Reset All Progress")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
                .foregroundColor(Color("AccentPrimary"))
                .padding(16)
                .background(CardBackground(cornerRadius: 16))
            }
        }
    }
}

// MARK: - Stat Row
struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(color)
                .frame(width: 28)
            
            Text(label)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Game Stat Card
struct GameStatCard: View {
    let gameType: GameType
    let progress: Double
    let rewards: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color("AccentPrimary").opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: gameType.iconName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color("AccentPrimary"))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(gameType.title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [Color("AccentPrimary"), Color("AccentSecondary")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 6)
                    }
                }
                .frame(height: 6)
            }
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                HStack(spacing: 3) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                    Text("\(rewards)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                }
                .foregroundColor(Color("AccentSecondary"))
            }
        }
        .padding(14)
        .background(CardBackground(cornerRadius: 16))
    }
}

#Preview {
    SettingsView(progressManager: ProgressManager.shared)
}

