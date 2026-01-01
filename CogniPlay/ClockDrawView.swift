import SwiftUI

struct ClockView: View {
  @Binding var currentView: ContentView.AppView
  @ObservedObject private var sessionManager = SessionManager.shared

  @State private var showTutorial = true
  @State private var taskStarted = false

  var task: Task {
    sessionManager.currentSession?.tasks.first(where: { $0.id == "clock_drawing" })
      ?? createDefaultClockTask()
  }

  var body: some View {
    VStack(spacing: 0) {
      if showTutorial && !task.tutorialSteps.isEmpty {
        ClockTutorialView(task: task) {
          showTutorial = false
          taskStarted = true
        }
      } else {
        ClockTaskView(currentView: $currentView, task: task)
      }
    }
  }

  private func createDefaultClockTask() -> Task {
    Task(
      id: "clock_drawing",
      name: "Clock Drawing",
      duration: "(3:00)",
      tutorialSteps: [
        TutorialStep(
          title: "Draw the Circle",
          description: "Start by drawing a circle to represent the clock face",
          icon: "circle"
        ),
        TutorialStep(
          title: "Add All Numbers",
          description: "Place all 12 numbers (1-12) around the clock in their correct positions",
          icon: "textformat.123"
        ),
        TutorialStep(
          title: "Draw the Hands",
          description: "Add both the hour hand and minute hand to match the displayed time",
          icon: "clock.fill"
        ),
        TutorialStep(
          title: "Check Your Time",
          description: "Make sure the hands point to the correct time shown above the clock",
          icon: "checkmark.circle.fill"
        ),
        TutorialStep(
          title: "Take Your Time",
          description: "You have up to 3 minutes - focus on accuracy over speed",
          icon: "timer"
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
struct ClockTutorialView: View {
  let task: Task
  let onComplete: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      Spacer()

      VStack(spacing: 15) {
        Text("Clock Drawing Task")
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

// MARK: - Clock Drawing Task View
struct ClockTaskView: View {
  @Binding var currentView: ContentView.AppView
  let task: Task

  @ObservedObject private var sessionManager = SessionManager.shared

  // Drawing State
  @State private var paths: [DrawingPath] = []
  @State private var currentPath: [CGPoint] = []
  @State private var brushSize: CGFloat = 3.0

  // Task State
  @State private var targetTime: (hour: Int, minute: Int) = (0, 0)
  @State private var startTime: Date?
  @State private var completionTime: TimeInterval = 0
  @State private var isComplete: Bool = false

  // Timer
  @State private var timeRemaining: TimeInterval = 180  // 3 minutes
  @State private var timer: Timer?

  var body: some View {
    VStack(spacing: 0) {
      Spacer()

      // MARK: - Header
      headerSection

      if isComplete {
        resultsView
      } else {
        taskContent
      }

      Spacer()

      // MARK: - Controls
      controlsSection

      Spacer()
    }
    .background(Color(.systemBackground))
    .onAppear {
      startTime = Date()
      generateRandomTime()
      startTimer()
    }
    .onDisappear {
      timer?.invalidate()
    }
  }

  // MARK: - View Components
  private var headerSection: some View {
    VStack(spacing: 15) {
      Text("Clock Drawing Task")
        .font(.largeTitle)
        .fontWeight(.bold)

      if !isComplete {
        VStack(spacing: 8) {
          Text("Time remaining: \(Int(timeRemaining))s")
            .font(.subheadline)
            .foregroundColor(timeRemaining < 30 ? .red : .secondary)
        }
      }
    }
    .padding(.bottom, 20)
  }

  private var taskContent: some View {
    VStack(spacing: 20) {
      // Target Time Display
      VStack(spacing: 8) {
        Text("Draw a clock showing:")
          .font(.headline)
          .foregroundColor(.secondary)

        Text(formatTime(targetTime.hour, targetTime.minute))
          .font(.system(size: 48, weight: .bold))
          .foregroundColor(.blue)
      }
      .padding(.bottom, 10)

      // Drawing Canvas
      ZStack {
        // Background
        RoundedRectangle(cornerRadius: 12)
          .fill(Color.white)
          .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)

        // Reference circle (optional guide)
        Circle()
          .stroke(Color.gray.opacity(0.2), lineWidth: 1)
          .frame(width: 280, height: 280)

        // Drawing paths
        Canvas { context, size in
          for path in paths {
            var cgPath = Path()
            if let firstPoint = path.points.first {
              cgPath.move(to: firstPoint)
              for point in path.points.dropFirst() {
                cgPath.addLine(to: point)
              }
            }
            context.stroke(cgPath, with: .color(path.color), lineWidth: path.width)
          }

          // Current path being drawn
          if !currentPath.isEmpty {
            var currentCGPath = Path()
            currentCGPath.move(to: currentPath[0])
            for point in currentPath.dropFirst() {
              currentCGPath.addLine(to: point)
            }
            context.stroke(currentCGPath, with: .color(.black), lineWidth: brushSize)
          }
        }
        .frame(width: 300, height: 300)
        .gesture(
          DragGesture(minimumDistance: 0)
            .onChanged { value in
              currentPath.append(value.location)
            }
            .onEnded { _ in
              if !currentPath.isEmpty {
                paths.append(DrawingPath(points: currentPath, color: .black, width: brushSize))
                currentPath = []
              }
            }
        )
      }
      .frame(width: 300, height: 300)

      // Drawing Tools
      HStack(spacing: 20) {
        Button(action: {
          if !paths.isEmpty {
            paths.removeLast()
          }
        }) {
          Label("Undo", systemImage: "arrow.uturn.backward")
            .font(.body)
            .foregroundColor(.blue)
        }

        Button(action: {
          paths.removeAll()
          currentPath = []
        }) {
          Label("Clear", systemImage: "trash")
            .font(.body)
            .foregroundColor(.red)
        }
      }
      .padding(.top, 10)
    }
    .padding(.horizontal, 20)
  }

  private var resultsView: some View {
    VStack(spacing: 25) {
      Text("Task Complete!")
        .font(.title)
        .fontWeight(.bold)
        .foregroundColor(.green)

      VStack(spacing: 15) {
        resultRow(label: "Target Time", value: formatTime(targetTime.hour, targetTime.minute))
        resultRow(label: "Completion Time", value: String(format: "%.1f seconds", completionTime))

        Text("Drawing submitted for analysis")
          .font(.subheadline)
          .foregroundColor(.secondary)
          .padding(.top, 10)
      }
      .padding()
      .background(Color.blue.opacity(0.1))
      .cornerRadius(12)

      VStack(alignment: .leading, spacing: 8) {
        Text("Scoring criteria:")
          .font(.caption)
          .fontWeight(.semibold)
        Text("• Clock circle: 1 point")
        Text("• All numbers present: 2 points")
        Text("• Numbers in correct positions: 2 points")
        Text("• Hour hand present: 2 points")
        Text("• Minute hand present: 2 points")
        Text("• Hands pointing to correct time: 1 point")
      }
      .font(.caption)
      .foregroundColor(.secondary)
      .padding(.horizontal)
    }
    .padding(.horizontal, 30)
  }

  private func resultRow(label: String, value: String) -> some View {
    HStack {
      Text("\(label):")
        .fontWeight(.medium)
      Spacer()
      Text(value)
        .fontWeight(.semibold)
    }
  }

  private var controlsSection: some View {
    VStack(spacing: 15) {
      if !isComplete {
        Button(action: submitDrawing) {
          Text("Submit Drawing")
            .font(.title2)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(paths.isEmpty ? Color.gray : Color.blue)
            .cornerRadius(10)
        }
        .disabled(paths.isEmpty)
        .padding(.horizontal, 30)
      } else {
        Button(action: {
          // Change this line in the submitDrawing completion:
          sessionManager.completeTask(
            "clock_drawing",
            withScore: ClockScore(
              completionTime: completionTime,
              targetHour: targetTime.hour,
              targetMinute: targetTime.minute
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

  // MARK: - Helper Functions
  private func generateRandomTime() {
    // Generate random hour (1-12) and minute (0, 15, 30, 45 for simplicity)
    targetTime.hour = Int.random(in: 1...12)
    targetTime.minute = [0, 15, 30, 45].randomElement() ?? 0
  }

  private func formatTime(_ hour: Int, _ minute: Int) -> String {
    return String(format: "%d:%02d", hour, minute)
  }

  private func startTimer() {
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
      if timeRemaining > 0 {
        timeRemaining -= 1
      } else {
        submitDrawing()
      }
    }
  }

  private func submitDrawing() {
    guard !isComplete else { return }

    timer?.invalidate()

    if let start = startTime {
      completionTime = Date().timeIntervalSince(start)
    }

    isComplete = true
  }
}

// MARK: - Supporting Types
struct DrawingPath {
  var points: [CGPoint]
  var color: Color
  var width: CGFloat
}

struct ClockScore: TaskScore {
  let completionTime: TimeInterval
  let targetHour: Int
  let targetMinute: Int

  // Convenience computed property to get tuple format if needed
  var targetTime: (hour: Int, minute: Int) {
    (targetHour, targetMinute)
  }

  func convertToMMSE() -> Int {
    // Will be scored by API later
    return 0
  }
}
