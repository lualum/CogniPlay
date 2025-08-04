//
//  SimonView.swift
//  CogniPlay
//
//  Created by Lucas Lum on 6/29/25.
//

import SwiftUI

// MARK: - Simon Game View
struct SimonView: View {
  @Binding var currentView: ContentView.AppView
  @Binding var simonScore: Int
  @ObservedObject private var sessionManager = SessionManager.shared

  @State private var gameState: SimonGameState = .waiting
  @State private var sequence: [Int] = []
  @State private var playerInput: [Int] = []
  @State private var currentStep = 0
  @State private var score = 0
  @State private var activeButton: Int? = nil
  @State private var showingSequence = false
  @State private var isProcessingInput = false
  @State private var showingEndConfirmation = false

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

      .padding(.bottom, 60)

      // Single toggle button
      VStack(spacing: 15) {
        Button(action: handleButtonTap) {
          Text(getButtonText())
            .font(.title2)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(getButtonColor())
            .cornerRadius(10)
            .animation(.easeInOut(duration: 0.3), value: getButtonText())
            .animation(.easeInOut(duration: 0.3), value: getButtonColor())
        }
        .disabled(
          gameState == .showingSequence || gameState == .playerTurn || showingEndConfirmation
        )
        .animation(
          .easeInOut(duration: 0.3),
          value: gameState == .showingSequence || gameState == .playerTurn || showingEndConfirmation
        )
      }
      .padding(.horizontal, 30)

      Spacer()
    }
    .background(Color.white)
  }

  func getButtonText() -> String {
    if showingEndConfirmation {
      return "Game Over"
    }

    switch gameState {
    case .waiting:
      return "Start Game"
    case .showingSequence:
      return "Watch the sequence..."
    case .playerTurn:
      return "Your turn! Repeat the sequence"
    case .gameOver:
      return "Done"
    }
  }

  func getButtonColor() -> Color {
    if showingEndConfirmation {
      return Color.gray.opacity(0.7)
    }

    switch gameState {
    case .waiting:
      return Color.green.opacity(0.7)
    case .showingSequence:
      return Color.blue.opacity(0.7)
    case .playerTurn:
      return Color.green.opacity(0.7)
    case .gameOver:
      return Color.blue.opacity(0.7)
    }
  }

  func handleButtonTap() {
    switch gameState {
    case .waiting:
      startGame()
    case .showingSequence, .playerTurn:
      // No action during active gameplay
      break
    case .gameOver:
      sessionManager.completeTask("simon", withScore: SimonMemoryScore(score: score))
      currentView = .sessionChecklist
    }
  }

  func endGame() {
    showingEndConfirmation = true

    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
      showingEndConfirmation = false
    }
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
    activeButton = nil  // Ensure we start with no active button

    for (index, colorIndex) in sequence.enumerated() {
      let delay = Double(index) * 0.8 + 0.5

      // First ensure button is deactivated
      DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        activeButton = nil

        // Then activate the button after a brief pause
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          activeButton = colorIndex

          // Then deactivate after showing
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
  }

  func playerTapped(_ index: Int) {
    guard !isProcessingInput else { return }

    isProcessingInput = true
    activeButton = index

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      activeButton = nil

      // Check if the tapped button matches the expected sequence step
      if index != sequence[currentStep] {
        gameState = .gameOver
        isProcessingInput = false

        // Show "Game Ended" confirmation for 2 seconds
        showingEndConfirmation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
          showingEndConfirmation = false
        }
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
    path.addArc(
      center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
    path.closeSubpath()

    return path
  }
}
