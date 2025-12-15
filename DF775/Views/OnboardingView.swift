//
//  OnboardingView.swift
//  DF775
//

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var progressManager: ProgressManager
    @State private var currentPage = 0
    @State private var isAnimating = false
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            iconName: "sparkles",
            title: "Master Your Focus",
            description: "Engage your mind with carefully crafted challenges that reward precision and patience.",
            accentColor: Color("AccentPrimary")
        ),
        OnboardingPage(
            iconName: "waveform.path",
            title: "Find Your Rhythm",
            description: "Every action matters. Time your moves, sync your decisions, and feel the flow.",
            accentColor: Color("AccentSecondary")
        ),
        OnboardingPage(
            iconName: "arrow.triangle.branch",
            title: "Progress With Purpose",
            description: "Unlock new paths as you grow. Your journey is measured in skill, not chance.",
            accentColor: Color("AccentPrimary")
        )
    ]
    
    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.height < 700
            
            ZStack {
                BackgroundGradient()
                
                VStack(spacing: 0) {
                    // Skip button
                    HStack {
                        Spacer()
                        
                        if currentPage < pages.count - 1 {
                            Button(action: skipToEnd) {
                                Text("Skip")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                            }
                        }
                    }
                    .frame(height: 44)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    Spacer()
                    
                    // Page content
                    TabView(selection: $currentPage) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            OnboardingPageView(
                                page: pages[index],
                                isActive: currentPage == index,
                                isCompact: isCompact
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    
                    Spacer()
                    
                    // Page indicators
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Capsule()
                                .fill(currentPage == index ? Color("AccentPrimary") : Color.white.opacity(0.3))
                                .frame(width: currentPage == index ? 20 : 8, height: 8)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }
                    .padding(.bottom, isCompact ? 16 : 24)
                    
                    // Continue button
                    Button(action: nextPage) {
                        HStack {
                            Text(currentPage == pages.count - 1 ? "Begin Journey" : "Continue")
                            
                            Image(systemName: currentPage == pages.count - 1 ? "arrow.right" : "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 20)
                    .padding(.bottom, isCompact ? 24 : 40)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                isAnimating = true
            }
        }
    }
    
    private func nextPage() {
        if currentPage < pages.count - 1 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentPage += 1
            }
        } else {
            completeOnboarding()
        }
    }
    
    private func skipToEnd() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentPage = pages.count - 1
        }
    }
    
    private func completeOnboarding() {
        withAnimation(.easeInOut(duration: 0.4)) {
            progressManager.hasCompletedOnboarding = true
        }
    }
}

// MARK: - Onboarding Page Model
struct OnboardingPage {
    let iconName: String
    let title: String
    let description: String
    let accentColor: Color
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let page: OnboardingPage
    let isActive: Bool
    let isCompact: Bool
    
    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: Double = 0
    @State private var textOffset: CGFloat = 30
    @State private var textOpacity: Double = 0
    @State private var ringRotation: Double = 0
    @State private var particleOffset: CGFloat = 0
    
    private var iconContainerSize: CGFloat {
        isCompact ? 140 : 180
    }
    
    private var iconSize: CGFloat {
        isCompact ? 44 : 56
    }
    
    var body: some View {
        VStack(spacing: isCompact ? 24 : 40) {
            // Animated icon container
            ZStack {
                // Outer rotating ring
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                page.accentColor.opacity(0.5),
                                page.accentColor.opacity(0.1),
                                page.accentColor.opacity(0.3),
                                page.accentColor.opacity(0.1),
                                page.accentColor.opacity(0.5)
                            ],
                            center: .center
                        ),
                        lineWidth: 2
                    )
                    .frame(width: iconContainerSize, height: iconContainerSize)
                    .rotationEffect(.degrees(ringRotation))
                
                // Middle pulsing ring
                Circle()
                    .stroke(page.accentColor.opacity(0.2), lineWidth: 1)
                    .frame(width: iconContainerSize * 0.78, height: iconContainerSize * 0.78)
                    .scaleEffect(isActive ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isActive)
                
                // Floating particles
                ForEach(0..<6, id: \.self) { index in
                    Circle()
                        .fill(page.accentColor.opacity(0.4))
                        .frame(width: 5, height: 5)
                        .offset(
                            x: cos(Double(index) * .pi / 3 + particleOffset) * (iconContainerSize * 0.38),
                            y: sin(Double(index) * .pi / 3 + particleOffset) * (iconContainerSize * 0.38)
                        )
                        .blur(radius: 1)
                }
                
                // Icon background glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                page.accentColor.opacity(0.3),
                                page.accentColor.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 15,
                            endRadius: iconContainerSize * 0.45
                        )
                    )
                    .frame(width: iconContainerSize * 0.9, height: iconContainerSize * 0.9)
                
                // Icon
                Image(systemName: page.iconName)
                    .font(.system(size: iconSize, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [page.accentColor, page.accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)
            }
            .frame(height: iconContainerSize + 20)
            
            // Text content
            VStack(spacing: isCompact ? 10 : 16) {
                Text(page.title)
                    .font(.system(size: isCompact ? 24 : 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                
                Text(page.description)
                    .font(.system(size: isCompact ? 14 : 16, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 20)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .offset(y: textOffset)
            .opacity(textOpacity)
        }
        .padding(.horizontal, 20)
        .onChange(of: isActive) { _, newValue in
            if newValue {
                animateIn()
            } else {
                resetAnimation()
            }
        }
        .onAppear {
            if isActive {
                animateIn()
            }
            startContinuousAnimations()
        }
    }
    
    private func animateIn() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            iconScale = 1.0
            iconOpacity = 1.0
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
            textOffset = 0
            textOpacity = 1.0
        }
    }
    
    private func resetAnimation() {
        iconScale = 0.5
        iconOpacity = 0
        textOffset = 30
        textOpacity = 0
    }
    
    private func startContinuousAnimations() {
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }
        
        withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
            particleOffset = .pi * 2
        }
    }
}

#Preview {
    OnboardingView(progressManager: ProgressManager.shared)
}
