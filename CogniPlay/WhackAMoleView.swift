//
//  WhackAMoleView.swift
//  CogniPlay
//
//  Created by Lucas Lum on 6/29/25.
//

import SwiftUI

// MARK: - Whack-a-Mole View
struct WhackAMoleView: View {
    @Binding var currentView: ContentView.AppView
    @State private var moles: [Bool] = Array(repeating: false, count: 12)
    @State private var score = 0
    @State private var timeRemaining = 30
    @State private var gameActive = false
    @State private var gameTimer: Timer?
    @State private var moleTimer: Timer?
    
    let columns = Array(repeating: GridItem(.flexible()), count: 3)
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Title
            VStack(spacing: 5) {
                Text("Whack-a-Mole")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Click Moles")
                    .font(.title2)
                    .fontWeight(.medium)
            }
            .padding(.bottom, 20)
            
            // Score and Timer
            HStack {
                Text("Score: \(score)")
                    .font(.title3)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("Time: \(timeRemaining)")
                    .font(.title3)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 20)
            
            // Game Grid
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(0..<12, id: \.self) { index in
                    Button(action: {
                        if gameActive && moles[index] {
                            whackMole(at: index)
                        }
                    }) {
                        ZStack {
                            // Hole
                            Ellipse()
                                .fill(Color.brown)
                                .frame(width: 80, height: 40)
                            
                            // Mole
                            if moles[index] {
                                Text("🐹")
                                    .font(.system(size: 40))
                                    .offset(y: -10)
                                    .animation(.easeInOut(duration: 0.2), value: moles[index])
                            }
                        }
                    }
                    .frame(width: 90, height: 90)
                    .disabled(!gameActive)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
            
            // Control Buttons
            VStack(spacing: 15) {
                if !gameActive && timeRemaining > 0 {
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
                } else if !gameActive && timeRemaining == 0 {
                    VStack(spacing: 10) {
                        Text("Game Over!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                        
                        Text("Final Score: \(score)")
                            .font(.title3)
                            .fontWeight(.medium)
                        
                        Button(action: resetGame) {
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
                }
                
                Button(action: {
                    stopGame()
                    currentView = .home
                }) {
                    Text("Done")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.green.opacity(0.7))
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .background(Color.white)
        .onDisappear {
            stopGame()
        }
    }
    
    func startGame() {
        gameActive = true
        score = 0
        timeRemaining = 30
        moles = Array(repeating: false, count: 12)
        
        // Start game timer
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                stopGame()
            }
        }
        
        // Start mole timer
        moleTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            showRandomMole()
        }
    }
    
    func stopGame() {
        gameActive = false
        gameTimer?.invalidate()
        moleTimer?.invalidate()
        moles = Array(repeating: false, count: 12)
    }
    
    func resetGame() {
        timeRemaining = 30
        score = 0
        moles = Array(repeating: false, count: 12)
    }
    
    func showRandomMole() {
        // Hide all moles first
        for i in 0..<moles.count {
            moles[i] = false
        }
        
        // Show 1-3 random moles
        let numberOfMoles = Int.random(in: 1...3)
        var availablePositions = Array(0..<12)
        
        for _ in 0..<numberOfMoles {
            if !availablePositions.isEmpty {
                let randomIndex = availablePositions.randomElement()!
                moles[randomIndex] = true
                availablePositions.removeAll { $0 == randomIndex }
                
                // Hide mole after 1.5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    moles[randomIndex] = false
                }
            }
        }
    }
    
    func whackMole(at index: Int) {
        if moles[index] {
            moles[index] = false
            score += 1
        }
    }
}
