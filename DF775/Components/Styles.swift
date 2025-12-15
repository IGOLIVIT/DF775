//
//  Styles.swift
//  DF775
//

import SwiftUI

// MARK: - Primary Button Style
struct PrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isEnabled ? Color("AccentPrimary") : Color("AccentPrimaryDim"))
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundColor(Color("AccentSecondary"))
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color("AccentSecondary").opacity(0.5), lineWidth: 1.5)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color("AccentSecondary").opacity(0.1))
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Game Card Style
struct GameCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Background Gradient
struct BackgroundGradient: View {
    @State private var animateGradient = false
    
    var body: some View {
        ZStack {
            Color("BackgroundPrimary")
                .ignoresSafeArea()
            
            // Animated gradient orbs
            GeometryReader { geometry in
                ZStack {
                    // Red accent orb
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color("AccentPrimary").opacity(0.15),
                                    Color("AccentPrimary").opacity(0.05),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: geometry.size.width * 0.5
                            )
                        )
                        .frame(width: geometry.size.width * 0.8)
                        .offset(
                            x: animateGradient ? -50 : -30,
                            y: animateGradient ? -100 : -80
                        )
                        .blur(radius: 60)
                    
                    // Gold accent orb
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color("AccentSecondary").opacity(0.1),
                                    Color("AccentSecondary").opacity(0.03),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: geometry.size.width * 0.4
                            )
                        )
                        .frame(width: geometry.size.width * 0.6)
                        .offset(
                            x: animateGradient ? geometry.size.width * 0.3 : geometry.size.width * 0.25,
                            y: animateGradient ? geometry.size.height * 0.5 : geometry.size.height * 0.45
                        )
                        .blur(radius: 50)
                }
            }
            .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
    }
}

// MARK: - Card Background
struct CardBackground: View {
    var cornerRadius: CGFloat = 20
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color("BackgroundSecondary"))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

// MARK: - Progress Ring
struct ProgressRing: View {
    var progress: Double
    var lineWidth: CGFloat = 4
    var size: CGFloat = 50
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color("AccentPrimaryDim").opacity(0.3), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [Color("AccentPrimary"), Color("AccentSecondary")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6), value: progress)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Animated Icon
struct AnimatedIcon: View {
    let iconName: String
    let color: Color
    @State private var isAnimating = false
    
    var body: some View {
        Image(systemName: iconName)
            .font(.system(size: 32, weight: .medium))
            .foregroundStyle(
                LinearGradient(
                    colors: [color, color.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .scaleEffect(isAnimating ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Glow Effect
struct GlowEffect: ViewModifier {
    let color: Color
    let radius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.5), radius: radius / 2)
            .shadow(color: color.opacity(0.3), radius: radius)
    }
}

extension View {
    func glow(color: Color, radius: CGFloat = 10) -> some View {
        modifier(GlowEffect(color: color, radius: radius))
    }
}

// MARK: - Pulse Animation
struct PulseAnimation: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.02 : 1.0)
            .opacity(isPulsing ? 1.0 : 0.95)
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear {
                isPulsing = true
            }
    }
}

extension View {
    func pulse() -> some View {
        modifier(PulseAnimation())
    }
}

