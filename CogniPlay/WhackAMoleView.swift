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
  @Binding var whackAMoleScore: Double

  @ObservedObject private var sessionManager = SessionManager.shared

  @State private var moles: [Bool] = Array(repeating: false, count: 20)
  @State private var moleAppearances: [Bool] = Array(repeating: false, count: 20)  // For fade animations
  @State private var moleDismissalTimers: [Timer?] = Array(repeating: nil, count: 20)  // Individual timers for each mole
  @State private var score = 0
  @State private var timeRemaining = 30.0
  @State private var gameActive = false
  @State private var gameCompleted = false
  @State private var gameTimer: Timer?
  @State private var moleGroupTimer: Timer?
  @State private var whackedMoles: [Bool] = Array(repeating: false, count: 20)  // For particle effects
  @State private var activeMoleCount = 0  // Track how many moles are currently active

  // New properties for dynamic lifespan calculation
  @State private var averageMoleLifespan: Double = 2.0  // Start with a 2-second default
  @State private var moleSpawnTimes: [Date?] = Array(repeating: nil, count: 20)
  @State private var moleLifespanData: [Double] = []

  let columns = Array(repeating: GridItem(.flexible()), count: 4)

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
      .padding(.bottom, 10)

      // Score and Timer
      HStack {
        Text("Score: \(score)")
          .font(.title3)
          .fontWeight(.medium)

        Spacer()

        let displayTime = timeRemaining < 0.01 && timeRemaining > -0.01 ? 0.0 : timeRemaining

        Text("Time: \(String(format: "%.1f", displayTime))")
          .font(.title3)
          .fontWeight(.medium)
      }
      .padding(.horizontal, 30)
      .padding(.bottom, 15)

      // Game Grid
      LazyVGrid(columns: columns, spacing: 8) {
        ForEach(0..<20, id: \.self) { index in
          Button(action: {
            if gameActive && moles[index] {
              whackMole(at: index)
            }
          }) {
            ZStack {
              // Hole
              Ellipse()
                .fill(Color.brown)
                .frame(width: 70, height: 35)

              // Mole with fade animation
              if moles[index] {
                Text("🐹")
                  .font(.system(size: 32))
                  .offset(y: -8)
                  .scaleEffect(moleAppearances[index] ? 1.0 : 0.3)
                  .opacity(moleAppearances[index] ? 1.0 : 0.0)
                  .animation(.easeOut(duration: 0.3), value: moleAppearances[index])
              }

              // Particle effect when mole is whacked
              if whackedMoles[index] {
                ParticleEffect()
                  .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                      whackedMoles[index] = false
                    }
                  }
              }
            }
          }
          .frame(width: 80, height: 60)
          .disabled(!gameActive)
        }
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 20)

      // Control Button - Updated logic
      Button(action: {
        if !gameActive && !gameCompleted {
          startGame()
        } else if gameCompleted {
          stopGame()
          whackAMoleScore = moleLifespanData.reduce(0, +) / Double(moleLifespanData.count)
          sessionManager.completeTask("whack")
          currentView = .sessionChecklist
        }
        // Do nothing if game is active (button shows countdown)
      }) {
        Text(buttonText)
          .font(.title2)
          .fontWeight(.medium)
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .frame(height: 50)
          .background(buttonBackgroundColor)
          .cornerRadius(10)
      }
      .padding(.horizontal, 30)
      .disabled(gameActive && !gameCompleted)  // Disable during active game

      Spacer()
    }
    .background(Color.white)
    .onDisappear {
      stopGame()
    }
  }

  // Computed property for button text
  private var buttonText: String {
    if !gameActive && !gameCompleted {
      return "Start Game"
    } else if gameActive {
      let displayTime = timeRemaining < 0.01 && timeRemaining > -0.01 ? 0.0 : timeRemaining
      return String(format: "%.1f", displayTime)
    } else {
      return "Done"
    }
  }

  // Computed property for button background color
  private var buttonBackgroundColor: Color {
    if !gameActive && !gameCompleted {
      return Color.green.opacity(0.7)
    } else if gameActive {
      let progress = (30.0 - timeRemaining) / 30.0

      if progress <= 0.5 {
        let localProgress = progress * 2.0
        return blendColors(.yellow, .red, weight: localProgress).opacity(0.7)
      } else {
        let localProgress = (progress - 0.5) * 2.0
        return blendColors(.green, .yellow, weight: localProgress).opacity(0.7)
      }
    } else {
      return Color.green.opacity(0.7)
    }
  }

  func startGame() {
    gameActive = true
    gameCompleted = false
    score = 0
    timeRemaining = 30.0
    activeMoleCount = 0
    moles = Array(repeating: false, count: 20)
    moleAppearances = Array(repeating: false, count: 20)
    whackedMoles = Array(repeating: false, count: 20)
    moleDismissalTimers = Array(repeating: nil, count: 20)

    // Reset lifespan tracking data
    moleSpawnTimes = Array(repeating: nil, count: 20)
    moleLifespanData.removeAll()
    recalculateAverageLifespan()  // Sets the initial averageMoleLifespan

    // Start game timer - updates every 0.1 seconds for smooth color transition
    gameTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
      if timeRemaining > 0 {
        timeRemaining -= 0.1
      } else {
        stopGame()
        gameCompleted = true
      }
    }

    // Start first mole group immediately
    showRandomMoleGroup()
  }

  func stopGame() {
    gameActive = false
    gameTimer?.invalidate()
    moleGroupTimer?.invalidate()

    // Invalidate all individual mole timers
    for i in 0..<moleDismissalTimers.count {
      moleDismissalTimers[i]?.invalidate()
      moleDismissalTimers[i] = nil
    }

    // Fade out all visible moles
    for i in 0..<moles.count {
      if moles[i] {
        moleAppearances[i] = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
          moles[i] = false
        }
      }
    }

    activeMoleCount = 0
  }

  func resetGame() {
    timeRemaining = 30.0
    score = 0
    activeMoleCount = 0
    moles = Array(repeating: false, count: 20)
    moleAppearances = Array(repeating: false, count: 20)
    whackedMoles = Array(repeating: false, count: 20)
    moleDismissalTimers = Array(repeating: nil, count: 20)
  }

  // New function to calculate average lifespan based on player performance
  func recalculateAverageLifespan() {
    guard !moleLifespanData.isEmpty else {
      averageMoleLifespan = 2.0
      return
    }

    let totalLifespan = moleLifespanData.reduce(0, +)
    let newAverage = totalLifespan / Double(moleLifespanData.count)

    // Clamp the average to keep the game playable (between 0.5 and 3.0 seconds)
    averageMoleLifespan = max(0.5, min(3.0, newAverage))
  }

  func showRandomMoleGroup() {
    guard gameActive else { return }

    // Determine number of moles: 25% chance for 1, 50% chance for 2, 25% chance for 3
    let randomValue = Double.random(in: 0...1)
    let numberOfMoles: Int
    if randomValue < 0.25 {
      numberOfMoles = 1
    } else if randomValue < 0.75 {
      numberOfMoles = 2
    } else {
      numberOfMoles = 3
    }

    var availablePositions = Array(0..<20)

    for _ in 0..<numberOfMoles {
      if !availablePositions.isEmpty {
        let randomIndex = availablePositions.randomElement()!
        availablePositions.removeAll { $0 == randomIndex }

        showMole(at: randomIndex)
      }
    }

    // Schedule check for when all moles are gone
    scheduleNextMoleGroup()
  }

  func showMole(at index: Int) {
    moles[index] = true
    activeMoleCount += 1
    moleSpawnTimes[index] = Date()  // Record spawn time

    // Trigger fade in animation
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      moleAppearances[index] = true
    }

    // Set individual timer for this mole based on the dynamic average lifespan
    let moleLifespan = averageMoleLifespan + Double.random(in: -0.3...0.3)  // Add some randomness
    let clampedLifespan = max(0.5, min(3.0, moleLifespan))

    moleDismissalTimers[index] = Timer.scheduledTimer(
      withTimeInterval: clampedLifespan, repeats: false
    ) { _ in
      if moles[index] {  // Mole was missed
        // Calculate lifespan for the missed mole as 1.2x its visible time
        let untappedLifespan = clampedLifespan * 1.2
        moleLifespanData.append(untappedLifespan)
        recalculateAverageLifespan()  // Update the average for next moles

        moleSpawnTimes[index] = nil  // Clear spawn time
        hideMole(at: index, wasWhacked: false)
      }
    }
  }

  func hideMole(at index: Int, wasWhacked: Bool) {
    guard moles[index] else { return }

    moleDismissalTimers[index]?.invalidate()
    moleDismissalTimers[index] = nil

    // Fade out the mole
    moleAppearances[index] = false
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      moles[index] = false
      activeMoleCount = max(0, activeMoleCount - 1)
    }
  }

  func scheduleNextMoleGroup() {
    // Check every 0.1 seconds if all moles are gone
    moleGroupTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
      if activeMoleCount == 0 {
        timer.invalidate()

        // Wait 1-1.5 seconds before showing next group
        let waitTime = Double.random(in: 1.0...1.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + waitTime) {
          if gameActive {
            showRandomMoleGroup()
          }
        }
      }
    }
  }

  func whackMole(at index: Int) {
    // Check if the mole is active and its spawn time is recorded
    if moles[index], let spawnTime = moleSpawnTimes[index] {
      // Calculate actual time the mole was visible before being whacked
      let lifespan = Date().timeIntervalSince(spawnTime)
      moleLifespanData.append(lifespan)
      recalculateAverageLifespan()  // Update the average for next moles

      moleSpawnTimes[index] = nil  // Clear spawn time for this mole

      // Trigger particle effect
      whackedMoles[index] = true

      // Hide the mole
      hideMole(at: index, wasWhacked: true)

      score += 1
    }
  }
}

// MARK: - Particle Effect View
struct ParticleEffect: View {
  @State private var particles: [Particle] = []
  @State private var animationTrigger = false

  var body: some View {
    ZStack {
      ForEach(0..<particles.count, id: \.self) { index in
        Circle()
          .fill(particles[index].color)
          .frame(width: 12, height: 12)
          .offset(x: particles[index].offsetX, y: particles[index].offsetY)
          .opacity(particles[index].opacity)
          .scaleEffect(particles[index].scale)
          .shadow(color: particles[index].color.opacity(0.8), radius: 2, x: 0, y: 0)
      }
    }
    .onAppear {
      createAndAnimateParticles()
    }
  }

  private func createAndAnimateParticles() {
    // Create particles at center with initial properties
    particles = (0..<8).map { i in
      let angle = Double(i) * (2 * Double.pi / 8)
      return Particle(
        offsetX: 0,
        offsetY: 0,
        opacity: 1.0,
        scale: 1.5,
        color: [Color.yellow, Color.orange, Color.red, Color.pink, Color.purple].randomElement()
          ?? Color.yellow,
        finalX: cos(angle) * 35,
        finalY: sin(angle) * 35
      )
    }

    // Animate particles outward
    withAnimation(.easeOut(duration: 0.6)) {
      for i in 0..<particles.count {
        particles[i].offsetX = particles[i].finalX
        particles[i].offsetY = particles[i].finalY
        particles[i].opacity = 0.0
        particles[i].scale = 0.2
      }
    }
  }
}

// MARK: - Particle Model
struct Particle: Hashable {
  var id = UUID()
  var offsetX: Double
  var offsetY: Double
  var opacity: Double
  var scale: Double
  var color: Color
  var finalX: Double
  var finalY: Double
}
