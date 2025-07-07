//
//  SimonView.swift
//  CogniPlay
//
//  Created by Lucas Lum on 6/29/25.
//

import SwiftUI

//let startTime = Date() // Save the start time
//I/ Later in your code, check how much time has passed
//let elapsedTime = Date().timelntervalSince(startTime)
//print ("Elapsed time: \(elapsedTime) seconds")

// MARK: - Simon Game View
struct SimonView: View {
    @Binding var currentView: ContentView.AppView
    @State private var gameState: SimonGameState = .waiting
    @State private var sequence: [Int] = []
    @State private var playerInput: [Int] = []
    @State private var currentStep = 0
    @State private var score = 0
    @State private var activeButton: Int? = nil
    @State private var showingSequence = false
    @State private var isProcessingInput = false
    
    enum SimonGameState {
        case waiting, showingSequence, playerTurn, gameOver
    }
    
    let colors: [Color] = [.red, .yellow, .green, .blue]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Title
            VStack(spacing: 5) {
                Text("Simon")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Score: \(score)")
                    .font(.title2)
                    .fontWeight(.medium)
            }
            .padding(.bottom, 30)
            
            // Game board - circular arrangement
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 300, height: 300)
                    .overlay(
                        Circle()
                            .stroke(Color.black, lineWidth: 2)
                    )
                
                // Four colored segments
                ForEach(0..<4) { index in
                    let startAngle = Double(index) * 90 - 90
                    let endAngle = Double(index + 1) * 90 - 90
                    
                    PieSlice(startAngle: .degrees(startAngle), endAngle: .degrees(endAngle))
                        .fill(colors[index])
                        .opacity(activeButton == index ? 1.0 : 0.6)
                        .scaleEffect(activeButton == index ? 1.05 : 1.0)
                        .frame(width: 280, height: 280)
                        .onTapGesture {
                            if gameState == .playerTurn && !isProcessingInput {
                                playerTapped(index)
                            }
                        }
                        .disabled(gameState != .playerTurn || isProcessingInput)
                        .animation(.easeInOut(duration: 0.1), value: activeButton)
                }
            }
            .padding(.bottom, 40)
            
            // Status text
            HStack {
                switch gameState {
                case .waiting:
                    Text("Press Start to begin!")
                        .font(.headline)
                        .foregroundColor(.gray)
                case .showingSequence:
                    Text("Watch the sequence...")
                        .font(.headline)
                        .foregroundColor(.blue)
                case .playerTurn:
                    Text("Your turn! Repeat the sequence")
                        .font(.headline)
                        .foregroundColor(.green)
                case .gameOver:
                    Text("Game Over! Final Score: \(score)")
                        .font(.headline)
                        .foregroundColor(.red)
                }
            }
            .padding(.bottom, 20)
            
            // Control buttons
            VStack(spacing: 15) {
                if gameState == .waiting {
                    Button(action: startGame) {
                        Text("Start Game")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.green.opacity(0.7))
                            .cornerRadius(10)
                    }
                } else if gameState == .gameOver {
                    Button(action: startGame) {
                        Text("Play Again")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.green.opacity(0.7))
                            .cornerRadius(10)
                    }
                }
                
                Button(action: {
                    currentView = .home
                }) {
                    Text("End Game")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue.opacity(0.7))
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .background(Color.white)
    }
    
    func startGame() {
        sequence = []
        playerInput = []
        currentStep = 0
        score = 0
        gameState = .waiting
        isProcessingInput = false
        activeButton = nil
        addToSequence()
    }
    
    func addToSequence() {
        sequence.append(Int.random(in: 0..<4))
        showSequence()
    }
    
    func showSequence() {
        gameState = .showingSequence
        showingSequence = true
        isProcessingInput = true
        
        for (index, colorIndex) in sequence.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.8 + 0.5) {
                activeButton = colorIndex
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    activeButton = nil
                    if index == sequence.count - 1 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            gameState = .playerTurn
                            playerInput = []
                            currentStep = 0
                            isProcessingInput = false
                        }
                    }
                }
            }
        }
    }
    
    func playerTapped(_ index: Int) {
        guard !isProcessingInput else { return }
        
        print("Player tapped: \(index), expected: \(sequence[currentStep])")
        
        isProcessingInput = true
        activeButton = index
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            activeButton = nil
            
            // Check if the tapped button matches the expected sequence step
            if index != sequence[currentStep] {
                print("Game over! Tapped \(index), expected \(sequence[currentStep])")
                gameState = .gameOver
                isProcessingInput = false
                return
            }
            
            currentStep += 1
            
            if currentStep == sequence.count {
                score += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    addToSequence()
                }
            } else {
                isProcessingInput = false
            }
        }
    }
}

// MARK: - Pie Slice Shape for Simon
struct PieSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.closeSubpath()
        
        return path
    }
}
