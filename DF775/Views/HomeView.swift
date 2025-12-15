//
//  HomeView.swift
//  DF775
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var progressManager: ProgressManager
    @State private var selectedGame: GameType?
    @State private var showSettings = false
    @State private var animateCards = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundGradient()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        headerView
                            .padding(.top, 20)
                        
                        // Stats summary
                        statsSummaryView
                        
                        // Games section
                        gamesSectionView
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(item: $selectedGame) { gameType in
                DifficultySelectionView(gameType: gameType, progressManager: progressManager)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(progressManager: progressManager)
            }
            .onAppear {
                withAnimation(.spring(response: 0.6).delay(0.2)) {
                    animateCards = true
                }
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome Back")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                
                Text("Choose Your Path")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Settings button
            Button(action: { showSettings = true }) {
                ZStack {
                    Circle()
                        .fill(Color("BackgroundSecondary"))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
    }
    
    // MARK: - Stats Summary View
    private var statsSummaryView: some View {
        HStack(spacing: 16) {
            StatItemView(
                icon: "flame.fill",
                value: "\(progressManager.statistics.totalLevelsCleared)",
                label: "Cleared",
                color: Color("AccentPrimary")
            )
            
            StatItemView(
                icon: "sparkles",
                value: "\(progressManager.statistics.totalRewardsCollected)",
                label: "Collected",
                color: Color("AccentSecondary")
            )
            
            StatItemView(
                icon: "clock.fill",
                value: progressManager.statistics.formattedPlayTime,
                label: "Played",
                color: Color("AccentPrimary")
            )
        }
        .padding(16)
        .background(CardBackground(cornerRadius: 20))
    }
    
    // MARK: - Games Section View
    private var gamesSectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Games")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                ForEach(Array(progressManager.getGameCards().enumerated()), id: \.element.id) { index, gameData in
                    GameCardView(gameData: gameData) {
                        selectedGame = gameData.gameType
                    }
                    .opacity(animateCards ? 1 : 0)
                    .offset(y: animateCards ? 0 : 30)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.1), value: animateCards)
                }
            }
        }
    }
}

// MARK: - Stat Item View
struct StatItemView: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HomeView(progressManager: ProgressManager.shared)
}

