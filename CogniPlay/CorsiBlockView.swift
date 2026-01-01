import SwiftUI

struct CorsiBlockView: View {
  @Binding var currentView: ContentView.AppView
  @ObservedObject private var sessionManager = SessionManager.shared

  @State private var showTutorial = true
  @State private var gameStarted = false

  var task: Task {
    sessionManager.currentSession?.tasks.first(where: { $0.id == "corsi" })
      ?? createDefaultCorsiTask()
  }

  var body: some View {
    VStack(spacing: 0) {
      if showTutorial && !task.tutorialSteps.isEmpty {
        CorsiTutorialView(task: task) {
          showTutorial = false
          gameStarted = true
        }
      } else {
        CorsiGameView(currentView: $currentView, task: task)
      }
    }
  }

  private func createDefaultCorsiTask() -> Task {
    Task(
      id: "corsi",
      name: "Corsi Block",
      duration: "(2:00)",
      tutorialSteps: [
        TutorialStep(
          title: "Watch the Sequence",
          description: "Pay attention as blocks light up in a specific order",
          icon: "eye.fill"
        ),
        TutorialStep(
          title: "Remember the Order",
          description: "Memorize the sequence of blocks that light up",
          icon: "brain.head.profile"
        ),
        TutorialStep(
          title: "Repeat the Pattern",
          description: "Tap the blocks in the same order they lit up",
          icon: "hand.tap.fill"
        ),
        TutorialStep(
          title: "Advance Levels",
          description: "Sequences get longer as you progress",
          icon: "arrow.up.circle.fill"
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
struct CorsiTutorialView: View {
  let task: Task
  let onComplete: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      Spacer()

      VStack(spacing: 15) {
        Text("Corsi Block Task")
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
struct CorsiGameView: View {
  @Binding var currentView: ContentView.AppView
  let task: Task

  @ObservedObject private var sessionManager = SessionManager.shared

  // Corsi Block Game State
  @State private var currentSequence: [Int] = []
  @State private var userSequence: [Int] = []
  @State private var currentLevel: Int = 2
  @State private var maxLevel: Int = 9
  @State private var currentTrial: Int = 0
  @State private var trialsPerLevel: Int = 2
  @State private var consecutiveFailures: Int = 0
  @State private var maxConsecutiveFailures: Int = 2

  // Animation state
  @State private var highlightedBlock: Int? = nil
  @State private var isShowingSequence: Bool = false
  @State private var isWaitingForInput: Bool = false

  // Results tracking
  @State private var correctTrials: Int = 0
  @State private var totalTrials: Int = 0
  @State private var highestLevelReached: Int = 2
  @State private var spanScore: Int = 0

  // UI State
  @State private var feedback: String = ""
  @State private var showFeedback: Bool = false
  @State private var isComplete: Bool = false

  let gridColumns = 3
  let gridRows = 3
  let totalBlocks = 9

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
      startNewTrial()
    }
  }

  // MARK: - View Components
  private var headerSection: some View {
    VStack(spacing: 15) {
      Text("Corsi Block Task")
        .font(.largeTitle)
        .fontWeight(.bold)

      if !isComplete {
        VStack(spacing: 8) {
          Text("Level \(currentLevel)")
            .font(.title2)
            .fontWeight(.medium)
            .foregroundColor(.primary)

          Text(
            isShowingSequence
              ? "Watch carefully..." : (isWaitingForInput ? "Your turn!" : "Get ready...")
          )
          .font(.body)
          .foregroundColor(.secondary)
        }
      }
    }
    .padding(.bottom, 30)
  }

  private var gameContent: some View {
    VStack(spacing: 40) {
      // Block grid
      VStack(spacing: 15) {
        ForEach(0..<gridRows, id: \.self) { row in
          HStack(spacing: 15) {
            ForEach(0..<gridColumns, id: \.self) { col in
              let index = row * gridColumns + col
              Rectangle()
                .fill(highlightedBlock == index ? Color.blue : Color.gray.opacity(0.3))
                .frame(width: 70, height: 70)
                .cornerRadius(10)
                .onTapGesture {
                  handleBlockTap(index: index)
                }
                .scaleEffect(highlightedBlock == index ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: highlightedBlock)
            }
          }
        }
      }

      // Progress indicator
      if isWaitingForInput {
        HStack(spacing: 8) {
          ForEach(0..<currentLevel, id: \.self) { index in
            Circle()
              .fill(index < userSequence.count ? Color.blue : Color.gray.opacity(0.3))
              .frame(width: 12, height: 12)
          }
        }
      }

      // Feedback
      if showFeedback {
        Text(feedback)
          .font(.title3)
          .fontWeight(.medium)
          .foregroundColor(feedback.contains("Correct") ? .green : .red)
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
        resultRow(label: "Corsi Span", value: "\(spanScore) blocks")
        resultRow(label: "Highest Level Reached", value: "Level \(highestLevelReached)")
        resultRow(
          label: "Success Rate",
          value: String(
            format: "%.1f%%",
            totalTrials > 0 ? (Double(correctTrials) / Double(totalTrials) * 100) : 0)
        )
        resultRow(label: "Total Trials", value: "\(totalTrials)")
      }
      .padding()
      .background(Color.blue.opacity(0.1))
      .cornerRadius(12)

      Text("Corsi span measures visuospatial working memory capacity")
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
            "corsi",
            withScore: CorsiScore(
              spanScore: spanScore,
              highestLevel: highestLevelReached,
              correctTrials: correctTrials,
              totalTrials: totalTrials,
              successRate: totalTrials > 0 ? Double(correctTrials) / Double(totalTrials) : 0
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
  private func startNewTrial() {
    guard currentLevel <= maxLevel && consecutiveFailures < maxConsecutiveFailures else {
      completeTask()
      return
    }

    userSequence = []
    currentSequence = generateSequence(length: currentLevel)
    isShowingSequence = true
    isWaitingForInput = false

    // Show sequence after brief delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      showSequence()
    }
  }

  private func generateSequence(length: Int) -> [Int] {
    var sequence: [Int] = []
    var availableBlocks = Array(0..<totalBlocks)

    for _ in 0..<length {
      if let randomBlock = availableBlocks.randomElement() {
        sequence.append(randomBlock)
        availableBlocks.removeAll { $0 == randomBlock }
      }
    }

    return sequence
  }

  private func showSequence() {
    guard !currentSequence.isEmpty else { return }

    showSequenceBlock(at: 0)
  }

  private func showSequenceBlock(at index: Int) {
    guard index < currentSequence.count else {
      // Sequence complete, wait for user input
      isShowingSequence = false
      isWaitingForInput = true
      return
    }

    let blockIndex = currentSequence[index]

    // Highlight block
    highlightedBlock = blockIndex

    // Unhighlight after delay and show next block
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
      highlightedBlock = nil

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
        showSequenceBlock(at: index + 1)
      }
    }
  }

  private func handleBlockTap(index: Int) {
    guard isWaitingForInput && !isShowingSequence else { return }

    userSequence.append(index)

    // Brief visual feedback
    highlightedBlock = index
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      highlightedBlock = nil
    }

    // Check if sequence is complete
    if userSequence.count == currentLevel {
      checkAnswer()
    }
  }

  private func checkAnswer() {
    totalTrials += 1

    if userSequence == currentSequence {
      // Correct answer
      correctTrials += 1
      consecutiveFailures = 0
      currentTrial += 1

      feedback = "Correct! Well done!"
      showFeedback = true

      // Update highest level reached
      if currentLevel > highestLevelReached {
        highestLevelReached = currentLevel
        spanScore = currentLevel
      }

      // Advance to next level after completing required trials
      if currentTrial >= trialsPerLevel {
        currentLevel += 1
        currentTrial = 0
      }

      DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
        showFeedback = false
        startNewTrial()
      }
    } else {
      // Incorrect answer
      consecutiveFailures += 1
      currentTrial += 1

      feedback = "Incorrect. Try again!"
      showFeedback = true

      // Check if we should advance or end
      if currentTrial >= trialsPerLevel {
        // Move to next level even after failure, or end if too many failures
        if consecutiveFailures < maxConsecutiveFailures {
          currentLevel += 1
          currentTrial = 0
        }
      }

      DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
        showFeedback = false
        startNewTrial()
      }
    }
  }

  private func completeTask() {
    isComplete = true
    isWaitingForInput = false
    isShowingSequence = false
  }
}

struct CorsiScore: TaskScore {
  let spanScore: Int
  let highestLevel: Int
  let correctTrials: Int
  let totalTrials: Int
  let successRate: Double

  func convertToMMSE() -> Int {
    return 0
  }
}
