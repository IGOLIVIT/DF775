//
//  SignalFlowGame.swift
//  DF775
//

import SwiftUI

// MARK: - Signal Flow Game View
struct SignalFlowGameView: View {
    let difficulty: DifficultyLevel
    let level: Int
    let onComplete: (Int, Int) -> Void
    let onExit: () -> Void
    
    @State private var gameState: SignalFlowState = .ready
    @State private var nodes: [SignalNode] = []
    @State private var connections: [SignalConnection] = []
    @State private var signalPosition: Int = 0
    @State private var targetNode: Int = 0
    @State private var score: Int = 0
    @State private var currentRound: Int = 1
    @State private var totalRounds: Int = 5
    @State private var movesLeft: Int = 10
    @State private var showSuccess = false
    @State private var showFailure = false
    @State private var animatingSignal = false
    
    private let gridCols = 4
    private let gridRows = 4
    
    init(difficulty: DifficultyLevel, level: Int, onComplete: @escaping (Int, Int) -> Void, onExit: @escaping () -> Void) {
        self.difficulty = difficulty
        self.level = level
        self.onComplete = onComplete
        self.onExit = onExit
    }
    
    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.height < 700
            let horizontalPadding: CGFloat = 16
            
            ZStack {
                Color("BackgroundPrimary").ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: isCompact ? 12 : 16) {
                        // Header
                        headerView
                            .padding(.top, isCompact ? 8 : 16)
                        
                        // Instructions
                        instructionText
                        
                        // Game area - adaptive size
                        gameArea(in: geometry, horizontalPadding: horizontalPadding)
                        
                        // Controls or Start button
                        if gameState == .playing {
                            controlButtons(in: geometry, isCompact: isCompact)
                        } else if gameState == .ready {
                            startButton
                        }
                        
                        Spacer(minLength: isCompact ? 16 : 30)
                    }
                    .padding(.horizontal, horizontalPadding)
                }
                
                // Overlays
                if showSuccess {
                    successOverlay
                }
                
                if showFailure {
                    failureOverlay
                }
            }
        }
        .onAppear {
            setupGame()
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
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
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.branch")
                            .font(.system(size: 11))
                        Text("\(movesLeft)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(Color("AccentSecondary"))
                    
                    Text("\(score)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            Color.clear.frame(width: 40, height: 40)
        }
    }
    
    // MARK: - Instruction Text
    private var instructionText: some View {
        Text(instructionMessage)
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundColor(.white.opacity(0.6))
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
    
    private var instructionMessage: String {
        switch gameState {
        case .ready:
            return "Guide the signal to the target"
        case .playing:
            return "Use arrows to move"
        case .success:
            return "Signal reached target!"
        case .failed:
            return "Out of moves!"
        case .finished:
            return "Complete!"
        }
    }
    
    // MARK: - Game Area
    private func gameArea(in geometry: GeometryProxy, horizontalPadding: CGFloat) -> some View {
        let availableWidth = geometry.size.width - (horizontalPadding * 2) - 32 // padding inside card
        let nodeSize = min(44, (availableWidth - CGFloat(gridCols - 1) * 8) / CGFloat(gridCols))
        let spacing = (availableWidth - nodeSize * CGFloat(gridCols)) / CGFloat(gridCols - 1)
        let gridHeight = CGFloat(gridRows) * nodeSize + CGFloat(gridRows - 1) * spacing
        
        return ZStack {
            // Connection lines
            ForEach(connections) { connection in
                ConnectionLine(
                    from: nodePosition(connection.from, nodeSize: nodeSize, spacing: spacing),
                    to: nodePosition(connection.to, nodeSize: nodeSize, spacing: spacing),
                    isActive: connection.from == signalPosition || connection.to == signalPosition
                )
            }
            
            // Nodes
            ForEach(nodes) { node in
                NodeView(
                    node: node,
                    isSignal: signalPosition == node.id,
                    isTarget: targetNode == node.id,
                    size: nodeSize,
                    isAnimating: animatingSignal && signalPosition == node.id
                )
                .position(nodePosition(node.id, nodeSize: nodeSize, spacing: spacing))
            }
        }
        .frame(width: availableWidth, height: gridHeight)
        .padding(16)
        .background(CardBackground(cornerRadius: 20))
    }
    
    private func nodePosition(_ id: Int, nodeSize: CGFloat, spacing: CGFloat) -> CGPoint {
        let col = id % gridCols
        let row = id / gridCols
        let x = CGFloat(col) * (nodeSize + spacing) + nodeSize / 2
        let y = CGFloat(row) * (nodeSize + spacing) + nodeSize / 2
        return CGPoint(x: x, y: y)
    }
    
    // MARK: - Control Buttons
    private func controlButtons(in geometry: GeometryProxy, isCompact: Bool) -> some View {
        let buttonSize: CGFloat = isCompact ? 52 : 60
        let buttonSpacing: CGFloat = isCompact ? 8 : 12
        let horizontalSpacing: CGFloat = buttonSize + buttonSpacing * 2
        
        return VStack(spacing: buttonSpacing) {
            // Up
            directionButton(.up, size: buttonSize)
            
            HStack(spacing: horizontalSpacing) {
                // Left
                directionButton(.left, size: buttonSize)
                
                // Right
                directionButton(.right, size: buttonSize)
            }
            
            // Down
            directionButton(.down, size: buttonSize)
        }
        .padding(.vertical, isCompact ? 8 : 16)
    }
    
    private func directionButton(_ direction: Direction, size: CGFloat) -> some View {
        Button(action: { moveSignal(direction) }) {
            Image(systemName: direction.iconName)
                .font(.system(size: size * 0.35, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(canMove(direction) ? Color("AccentPrimary") : Color("AccentPrimaryDim"))
                        .shadow(color: canMove(direction) ? Color("AccentPrimary").opacity(0.4) : Color.clear, radius: 6)
                )
        }
        .disabled(!canMove(direction))
        .opacity(canMove(direction) ? 1.0 : 0.5)
    }
    
    // MARK: - Start Button
    private var startButton: some View {
        Button(action: startGame) {
            Text("Start")
        }
        .buttonStyle(PrimaryButtonStyle())
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
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
    
    private var failureOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(Color("AccentPrimaryDim"))
            
            Text("No moves left")
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
        totalRounds = 3 + level / 3
        generateLevel()
    }
    
    private func generateLevel() {
        nodes = []
        connections = []
        
        // Create nodes in a grid
        for i in 0..<(gridCols * gridRows) {
            let isBlocked = shouldBlockNode(i)
            nodes.append(SignalNode(id: i, isBlocked: isBlocked))
        }
        
        // Generate connections between adjacent non-blocked nodes
        for node in nodes where !node.isBlocked {
            let col = node.id % gridCols
            let row = node.id / gridCols
            
            // Right connection
            if col < gridCols - 1 {
                let rightId = node.id + 1
                if !nodes[rightId].isBlocked {
                    connections.append(SignalConnection(from: node.id, to: rightId))
                }
            }
            
            // Down connection
            if row < gridRows - 1 {
                let downId = node.id + gridCols
                if !nodes[downId].isBlocked {
                    connections.append(SignalConnection(from: node.id, to: downId))
                }
            }
        }
        
        // Set start position (top-left area)
        let startCandidates = nodes.filter { !$0.isBlocked && $0.id < gridCols }
        signalPosition = startCandidates.randomElement()?.id ?? 0
        
        // Set target (bottom-right area)
        let targetCandidates = nodes.filter { !$0.isBlocked && $0.id >= gridCols * (gridRows - 1) }
        targetNode = targetCandidates.randomElement()?.id ?? (gridCols * gridRows - 1)
        
        // Ensure target is not the same as start
        if targetNode == signalPosition {
            targetNode = nodes.filter { !$0.isBlocked && $0.id != signalPosition }.last?.id ?? targetNode
        }
        
        // More generous moves
        let baseMoves = 10 + level
        movesLeft = max(6, baseMoves - difficulty.complexityMultiplier)
    }
    
    private func shouldBlockNode(_ id: Int) -> Bool {
        // Never block corners for start/target positions
        let corners = [0, gridCols - 1, gridCols * (gridRows - 1), gridCols * gridRows - 1]
        if corners.contains(id) { return false }
        
        // Lower block probability for playability
        let blockProbability = 0.1 + Double(difficulty.complexityMultiplier - 1) * 0.05 + Double(level - 1) * 0.01
        return Double.random(in: 0...1) < min(0.25, blockProbability)
    }
    
    private func startGame() {
        withAnimation(.spring(response: 0.3)) {
            gameState = .playing
        }
    }
    
    private func canMove(_ direction: Direction) -> Bool {
        guard gameState == .playing else { return false }
        
        let col = signalPosition % gridCols
        let row = signalPosition / gridCols
        
        var targetId: Int?
        
        switch direction {
        case .up:
            if row > 0 { targetId = signalPosition - gridCols }
        case .down:
            if row < gridRows - 1 { targetId = signalPosition + gridCols }
        case .left:
            if col > 0 { targetId = signalPosition - 1 }
        case .right:
            if col < gridCols - 1 { targetId = signalPosition + 1 }
        }
        
        guard let target = targetId else { return false }
        guard target >= 0 && target < nodes.count else { return false }
        
        // Check if target node is not blocked
        if nodes[target].isBlocked { return false }
        
        // Check if connection exists
        return connections.contains { conn in
            (conn.from == signalPosition && conn.to == target) ||
            (conn.to == signalPosition && conn.from == target)
        }
    }
    
    private func moveSignal(_ direction: Direction) {
        guard canMove(direction), movesLeft > 0 else { return }
        
        var newPosition = signalPosition
        
        switch direction {
        case .up: newPosition -= gridCols
        case .down: newPosition += gridCols
        case .left: newPosition -= 1
        case .right: newPosition += 1
        }
        
        movesLeft -= 1
        
        withAnimation(.spring(response: 0.3)) {
            animatingSignal = true
            signalPosition = newPosition
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            animatingSignal = false
            
            // Check if reached target
            if signalPosition == targetNode {
                handleRoundSuccess()
            } else if movesLeft == 0 {
                handleRoundFailure()
            }
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
                generateLevel()
                gameState = .playing
            }
        }
    }
    
    private func handleRoundFailure() {
        gameState = .failed
        
        withAnimation(.spring(response: 0.3)) {
            showFailure = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                showFailure = false
            }
            
            finishGame(success: false)
        }
    }
    
    private func calculateRoundScore() -> Int {
        return (movesLeft * 15) + (currentRound * 20) + (difficulty.complexityMultiplier * 25)
    }
    
    private func finishGame(success: Bool) {
        gameState = .finished
        
        let rewards = success ? (12 + level * 3 + difficulty.complexityMultiplier * 6) : 0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if success {
                onComplete(score, rewards)
            } else {
                onExit()
            }
        }
    }
}

// MARK: - Supporting Types
enum SignalFlowState {
    case ready
    case playing
    case success
    case failed
    case finished
}

struct SignalNode: Identifiable {
    let id: Int
    let isBlocked: Bool
}

struct SignalConnection: Identifiable {
    var id: String { "\(from)-\(to)" }
    let from: Int
    let to: Int
}

enum Direction {
    case up, down, left, right
    
    var iconName: String {
        switch self {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .left: return "arrow.left"
        case .right: return "arrow.right"
        }
    }
}

// MARK: - Node View
struct NodeView: View {
    let node: SignalNode
    let isSignal: Bool
    let isTarget: Bool
    let size: CGFloat
    let isAnimating: Bool
    
    var body: some View {
        ZStack {
            if node.isBlocked {
                Circle()
                    .fill(Color("BackgroundPrimary").opacity(0.5))
                    .frame(width: size * 0.5, height: size * 0.5)
            } else {
                Circle()
                    .fill(nodeColor)
                    .frame(width: size, height: size)
                    .overlay(
                        Circle()
                            .stroke(borderColor, lineWidth: 2)
                    )
                    .shadow(color: shadowColor, radius: isSignal || isTarget ? 6 : 0)
                    .scaleEffect(isAnimating ? 1.15 : 1.0)
                
                if isTarget && !isSignal {
                    Image(systemName: "flag.fill")
                        .font(.system(size: size * 0.35))
                        .foregroundColor(Color("AccentSecondary"))
                }
                
                if isSignal {
                    Circle()
                        .fill(Color("AccentSecondary"))
                        .frame(width: size * 0.5, height: size * 0.5)
                        .shadow(color: Color("AccentSecondary").opacity(0.8), radius: 4)
                }
            }
        }
    }
    
    private var nodeColor: Color {
        if isSignal {
            return Color("AccentPrimary").opacity(0.4)
        }
        if isTarget {
            return Color("AccentSecondary").opacity(0.2)
        }
        return Color("BackgroundSecondary")
    }
    
    private var borderColor: Color {
        if isSignal {
            return Color("AccentPrimary")
        }
        if isTarget {
            return Color("AccentSecondary")
        }
        return Color.white.opacity(0.1)
    }
    
    private var shadowColor: Color {
        if isSignal {
            return Color("AccentSecondary").opacity(0.5)
        }
        if isTarget {
            return Color("AccentSecondary").opacity(0.3)
        }
        return Color.clear
    }
}

// MARK: - Connection Line
struct ConnectionLine: View {
    let from: CGPoint
    let to: CGPoint
    let isActive: Bool
    
    var body: some View {
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }
        .stroke(
            isActive ? Color("AccentPrimary").opacity(0.6) : Color.white.opacity(0.15),
            style: StrokeStyle(lineWidth: 2, lineCap: .round)
        )
    }
}
