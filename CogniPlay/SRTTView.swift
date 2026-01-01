import SwiftUI

struct SRTTView: View {
  @Binding var currentView: ContentView.AppView
  @ObservedObject private var sessionManager = SessionManager.shared

  @State private var showTutorial = true
  @State private var gameStarted = false

  var task: Task {
    sessionManager.currentSession?.tasks.first(where: { $0.id == "srtt" })
      ?? createDefaultSRTTTask()
  }

  var body: some View {
    VStack(spacing: 0) {
      if showTutorial && !task.tutorialSteps.isEmpty {
        SRTTTutorialView(task: task) {
          showTutorial = false
          gameStarted = true
        }
      } else {
        SRTTGameView(currentView: $currentView, task: task)
      }
    }
  }

  private func createDefaultSRTTTask() -> Task {
    Task(
      id: "srtt",
      name: "Serial Reaction Time",
      duration: "(0:30)",
      tutorialSteps: [
        TutorialStep(
          title: "Tap Quickly",
          description: "Tap the square that lights up as quickly as possible",
          icon: "hand.tap.fill"
        ),
        TutorialStep(
          title: "Speed Matters",
          description: "Respond as fast and accurately as you can",
          icon: "speedometer"
        ),
        TutorialStep(
          title: "Complete Rounds",
          description: "Complete 12 rounds to finish the task",
          icon: "arrow.clockwise"
        ),
        TutorialStep(
          title: "Pattern Learning",
          description: "Some sequences may feel familiar - that's normal!",
          icon: "brain.head.profile"
        ),
      ],
      prerequisiteTaskIDs: [],
      isCompleted: false,
      isLocked: false,
      isOptional: false
    )
  }
}

// MARK: - Tutorial View
struct SRTTTutorialView: View {
  let task: Task
  let onComplete: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      Spacer()

      VStack(spacing: 15) {
        Text("Reaction Time Task")
          .font(.largeTitle)
          .fontWeight(.bold)
      }
      .padding(.bottom, 30)

      VStack(alignment: .leading, spacing: 20) {
        Text("Instructions")
          .font(.title)
          .fontWeight(.bold)

        VStack(alignment: .leading, spacing: 15) {
          ForEach(task.tutorialSteps) { step in
            HStack(spacing: 15) {
              Image(systemName: step.icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)

              Text(step.description)
                .font(.body)
            }
          }
        }

        Button(action: onComplete) {
          Text("Start Task")
            .font(.title2)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.blue)
            .cornerRadius(10)
        }
        .padding(.top, 20)
      }
      .padding(.horizontal, 30)

      Spacer()
      Spacer()
    }
    .background(Color(.systemBackground))
  }
}

// MARK: - Game View
struct SRTTGameView: View {
  @Binding var currentView: ContentView.AppView
  let task: Task

  @ObservedObject private var sessionManager = SessionManager.shared

  // SRTT Game State
  @State private var targetPosition: Int = -1
  @State private var currentRound: Int = 0
  @State private var totalRounds: Int = 12
  @State private var reactionTimes: [Double] = []
  @State private var startTime: Date?

  // Pattern state
  @State private var patternSequence: [Int] = [0, 2, 1, 3, 0, 1, 2, 3]

  // UI State
  @State private var showingTarget: Bool = false
  @State private var feedback: String = ""
  @State private var showFeedback: Bool = false
  @State private var isComplete: Bool = false

  // Results
  @State private var averageRT: Double = 0.0
  @State private var patternRT: Double = 0.0
  @State private var randomRT: Double = 0.0

  let gridSize = 4

  var body: some View {
    VStack(spacing: 0) {
      Spacer()

      // MARK: - Header
      headerSection

      if isComplete {
        resultsView
      } else {
        gameContent
      }

      Spacer()

      // MARK: - Controls
      controlsSection

      Spacer()
    }
    .background(Color(.systemBackground))
    .onAppear {
      startNextRound()
    }
  }

  // MARK: - View Components
  private var headerSection: some View {
    VStack(spacing: 15) {
      Text("Reaction Time Task")
        .font(.largeTitle)
        .fontWeight(.bold)

      if !isComplete {
        Text("Round \(currentRound + 1) of \(totalRounds)")
          .font(.title2)
          .fontWeight(.medium)
          .foregroundColor(.primary)
      }
    }
    .padding(.bottom, 30)
  }

  private var gameContent: some View {
    VStack(spacing: 40) {
      // Target grid
      HStack(spacing: 20) {
        ForEach(0..<gridSize, id: \.self) { index in
          Rectangle()
            .fill(targetPosition == index && showingTarget ? Color.blue : Color.gray.opacity(0.3))
            .frame(width: 60, height: 60)
            .cornerRadius(8)
            .onTapGesture {
              handleTap(position: index)
            }
            .scaleEffect(targetPosition == index && showingTarget ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: showingTarget)
        }
      }

      // Feedback
      if showFeedback {
        Text(feedback)
          .font(.title3)
          .fontWeight(.medium)
          .foregroundColor(feedback.contains("Correct") ? .green : .orange)
          .transition(.scale)
      }
    }
    .frame(maxHeight: .infinity)
  }

  private var resultsView: some View {
    VStack(spacing: 25) {
      Text("Task Complete!")
        .font(.title)
        .fontWeight(.bold)
        .foregroundColor(.green)

      VStack(spacing: 15) {
        resultRow(label: "Average Reaction Time", value: String(format: "%.0f ms", averageRT))
        resultRow(label: "Pattern Phase RT", value: String(format: "%.0f ms", patternRT))
        resultRow(label: "Random Phase RT", value: String(format: "%.0f ms", randomRT))

        if patternRT > 0 && randomRT > 0 {
          let improvement = ((randomRT - patternRT) / randomRT) * 100
          resultRow(
            label: "Learning Effect",
            value: String(format: "%.1f%%", improvement),
            highlight: improvement > 0
          )
        }
      }
      .padding()
      .background(Color.blue.opacity(0.1))
      .cornerRadius(12)

      Text("Faster reaction times in the pattern phase suggest implicit learning ability")
        .font(.caption)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal)
    }
    .padding(.horizontal, 30)
  }

  private func resultRow(label: String, value: String, highlight: Bool = false) -> some View {
    HStack {
      Text("\(label):")
        .fontWeight(.medium)
      Spacer()
      Text(value)
        .fontWeight(.semibold)
        .foregroundColor(highlight ? .green : .primary)
    }
  }

  private var controlsSection: some View {
    VStack(spacing: 15) {
      if isComplete {
        Button(action: {
          sessionManager.completeTask(
            "srtt",
            withScore: SRTTScore(
              averageRT: averageRT,
              patternRT: patternRT,
              randomRT: randomRT,
              learningEffect: patternRT > 0 && randomRT > 0
                ? ((randomRT - patternRT) / randomRT) : 0
            ))
          currentView = .sessionChecklist
        }) {
          Text("Done")
            .font(.title2)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.green)
            .cornerRadius(10)
        }
        .padding(.horizontal, 30)
      }
    }
  }

  // MARK: - Game Logic
  private func startNextRound() {
    guard currentRound < totalRounds else {
      completeTask()
      return
    }

    // Determine target position
    if currentRound < 8 {
      // Pattern phase: use repeating pattern
      targetPosition = patternSequence[currentRound % patternSequence.count]
    } else {
      // Random phase: random positions
      targetPosition = Int.random(in: 0..<gridSize)
    }

    // Show target after brief delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      showingTarget = true
      startTime = Date()
    }
  }

  private func handleTap(position: Int) {
    guard showingTarget, let startTime = startTime else { return }

    let reactionTime = Date().timeIntervalSince(startTime) * 1000  // Convert to ms

    if position == targetPosition {
      // Correct response
      reactionTimes.append(reactionTime)
      feedback = "Correct! \(Int(reactionTime))ms"
      showFeedback = true

      // Hide target and move to next round
      showingTarget = false
      currentRound += 1

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        showFeedback = false
        startNextRound()
      }
    } else {
      // Incorrect response
      feedback = "Wrong position, try again!"
      showFeedback = true

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
        showFeedback = false
      }
    }
  }

  private func completeTask() {
    isComplete = true
    calculateResults()
  }

  private func calculateResults() {
    guard !reactionTimes.isEmpty else { return }

    // Calculate average RT
    averageRT = reactionTimes.reduce(0, +) / Double(reactionTimes.count)

    // Calculate pattern phase RT (first 8 rounds)
    let patternRTs = Array(reactionTimes.prefix(min(8, reactionTimes.count)))
    patternRT = patternRTs.isEmpty ? 0 : patternRTs.reduce(0, +) / Double(patternRTs.count)

    // Calculate random phase RT (last 4 rounds)
    let randomRTs = Array(reactionTimes.suffix(min(4, reactionTimes.count)))
    randomRT = randomRTs.isEmpty ? 0 : randomRTs.reduce(0, +) / Double(randomRTs.count)
  }
}

struct SRTTScore: TaskScore {
  let averageRT: Double
  let patternRT: Double
  let randomRT: Double
  let learningEffect: Double

  func convertToMMSE() -> Int {
    return 0
  }
}
