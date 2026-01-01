import SwiftUI

struct ResultsView: View {
  @Binding var currentView: ContentView.AppView
  @ObservedObject private var sessionManager = SessionManager.shared
  @State private var showingDetails = false

  private var mmseScore: Int {
    sessionManager.getCombinedMMSEScore()
  }

  private var scoreColor: Color {
    return .gray
  }

  private var scoreInterpretation: String {
    switch mmseScore {
    case 24...30: return "Normal cognitive function"
    case 18...23: return "Mild cognitive impairment"
    case 10...17: return "Moderate cognitive impairment"
    default: return "Severe cognitive impairment"
    }
  }

  var body: some View {
    VStack(spacing: 20) {
      // Header
      VStack(spacing: 8) {
        Text("Assessment Results")
          .font(.largeTitle)
          .fontWeight(.bold)

        if let session = sessionManager.currentSession {
          Text(session.sessionTitle)
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
      }

      // Overall Score Card (Grey N/A)
      VStack(spacing: 16) {
        Text("Overall Score")
          .font(.title2)
          .fontWeight(.semibold)

        ZStack {
          Circle()
            .stroke(Color.gray.opacity(0.2), lineWidth: 8)
            .frame(width: 120, height: 120)

          VStack {
            Text("N/A")
              .font(.system(size: 24, weight: .bold))
              .foregroundColor(.gray)
            Text("Raw Scores Below")
              .font(.caption2)
              .foregroundColor(.secondary)
          }
        }

        Text("Individual task scores shown below")
          .font(.subheadline)
          .foregroundColor(.gray)
          .fontWeight(.medium)
      }
      .padding(.vertical, 20)
      .frame(maxWidth: .infinity)
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(Color(.systemBackground))
          .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
      )
      .padding(.horizontal)

      TaskSummaryView()

      Spacer()

      VStack(spacing: 12) {
        Button(action: {
          showingDetails = true
        }) {
          HStack {
            Image(systemName: "chart.bar.doc.horizontal")
            Text("View Detailed Analysis")
          }
          .font(.headline)
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.blue)
          .cornerRadius(12)
        }

        Button(action: {
          sessionManager.createNewSession()
        }) {
          HStack {
            Image(systemName: "plus.circle")
            Text("Start New Assessment")
          }
          .font(.headline)
          .foregroundColor(.blue)
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.blue.opacity(0.1))
          .cornerRadius(12)
        }
      }
      .padding(.horizontal)
      .padding(.bottom, 30)
    }
    .navigationBarHidden(true)
    .ignoresSafeArea(.all, edges: .top)
    .sheet(isPresented: $showingDetails) {
      DetailedResultsView()
    }
  }
}

struct TaskSummaryView: View {
  @ObservedObject private var sessionManager = SessionManager.shared

  private var completedTasks: [Task] {
    sessionManager.currentSession?.tasks.filter { $0.isCompleted && !$0.isOptional } ?? []
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("Task Performance (Raw Scores)")
          .font(.headline)
          .fontWeight(.semibold)
        Spacer()
        Text("\(completedTasks.count) completed")
          .font(.caption)
          .foregroundColor(.secondary)
      }

      LazyVGrid(
        columns: [
          GridItem(.flexible()),
          GridItem(.flexible()),
        ], spacing: 8
      ) {
        ForEach(completedTasks) { task in
          TaskScoreCard(task: task)
        }
      }
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    )
    .padding(.horizontal)
  }
}

struct TaskScoreCard: View {
  let task: Task
  @ObservedObject private var sessionManager = SessionManager.shared

  // Get raw score instead of MMSE score
  private var rawScoreInfo: (value: String, maxValue: String, color: Color) {
    switch task.id {
    case "speech":
      if let score = sessionManager.getTaskScore(task.id, as: SpeechScore.self) {
        let percentage = score.probability * 100
        return (String(format: "%.1f", percentage), "", .gray)
      }
    default:
      if let score = sessionManager.getTaskScore(task.id, as: GenericScore.self) {
        return ("\(score.value)", "", .blue)
      }
    }
    return ("N/A", "", .gray)
  }

  var body: some View {
    VStack(spacing: 8) {
      HStack {
        Image(systemName: taskIcon)
          .foregroundColor(.blue)
          .font(.caption)
        Spacer()
        Text(rawScoreInfo.value)
          .font(.headline)
          .fontWeight(.bold)
          .foregroundColor(rawScoreInfo.color)
      }

      Text(task.name)
        .font(.caption)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)

      // Show max value if available
      if !rawScoreInfo.maxValue.isEmpty && rawScoreInfo.maxValue != "%" {
        Text(rawScoreInfo.maxValue)
          .font(.caption2)
          .foregroundColor(.secondary)
      }
    }
    .padding(8)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(Color(.systemGray6))
    )
  }

  private var taskIcon: String {
    switch task.id {
    case "speech": return "mic.fill"
    case "srtt": return "bolt.fill"
    case "corsi": return "square.fill"
    case "clock": return "clock.fill"
    default: return "circle"
    }
  }
}

struct DetailedResultsView: View {
  @ObservedObject private var sessionManager = SessionManager.shared
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          // Overall Score Section
          OverallScoreSection()

          // Task Details Section
          TaskDetailsSection()

          // Raw Data Section
          RawDataSection()
        }
        .padding()
      }
      .navigationTitle("Detailed Analysis")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
  }
}

struct OverallScoreSection: View {
  @ObservedObject private var sessionManager = SessionManager.shared

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Overall Assessment")
        .font(.title2)
        .fontWeight(.bold)

      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("Combined Score")
            .font(.subheadline)
            .foregroundColor(.secondary)
          Text("N/A")
            .font(.title)
            .fontWeight(.bold)
            .foregroundColor(.gray)
        }

        Spacer()

        VStack(alignment: .trailing, spacing: 4) {
          Text("Completion Rate")
            .font(.subheadline)
            .foregroundColor(.secondary)
          let completedCount =
            sessionManager.currentSession?.tasks.filter { $0.isCompleted && !$0.isOptional }.count
            ?? 0
          let totalCount = sessionManager.currentSession?.tasks.filter { !$0.isOptional }.count ?? 1
          Text("\(Int(Double(completedCount) / Double(totalCount) * 100))%")
            .font(.title)
            .fontWeight(.bold)
            .foregroundColor(.blue)
        }
      }
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    )
  }
}

struct TaskDetailsSection: View {
  @ObservedObject private var sessionManager = SessionManager.shared

  private var completedTasks: [Task] {
    sessionManager.currentSession?.tasks.filter { $0.isCompleted && !$0.isOptional } ?? []
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Task Performance (Raw Scores)")
        .font(.title2)
        .fontWeight(.bold)

      VStack(spacing: 12) {
        ForEach(completedTasks.filter { $0.id != "setup" }) { task in
          TaskDetailRow(task: task)
        }
      }
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    )
  }
}

struct TaskDetailRow: View {
  let task: Task
  @ObservedObject private var sessionManager = SessionManager.shared

  // Get raw score display info
  private var rawScoreDisplay: (value: String, unit: String, color: Color) {
    switch task.id {
    case "speech":
      if let score = sessionManager.getTaskScore(task.id, as: SpeechScore.self) {
        let percentage = score.probability * 100
        let color: Color = percentage >= 80 ? .green : percentage >= 60 ? .orange : .red
        return (String(format: "%.1f", percentage), "% clarity", color)
      }
    default:
      if let score = sessionManager.getTaskScore(task.id, as: GenericScore.self) {
        return ("\(score.value)", "", .blue)
      }
    }
    return ("N/A", "", .gray)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(task.name)
          .font(.headline)
          .lineLimit(2)
        Spacer()
        Text("\(rawScoreDisplay.value)\(rawScoreDisplay.unit)")
          .font(.subheadline)
          .fontWeight(.semibold)
          .foregroundColor(rawScoreDisplay.color)
      }

      // Task-specific details
      TaskSpecificDetails(task: task)

      Divider()
    }
    .padding(.vertical, 4)
  }
}

struct TaskSpecificDetails: View {
  let task: Task
  @ObservedObject private var sessionManager = SessionManager.shared

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      switch task.id {
      case "speech":
        if let score = sessionManager.getTaskScore(task.id, as: SpeechScore.self) {
          Text("Raw Probability: \(String(format: "%.4f", score.probability))")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      default:
        if let score = sessionManager.getTaskScore(task.id, as: GenericScore.self) {
          Text("Raw Score: \(score.value)")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
    }
  }
}

struct RawDataSection: View {
  @ObservedObject private var sessionManager = SessionManager.shared
  @State private var showingRawData = false

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Text("Raw Data")
          .font(.title2)
          .fontWeight(.bold)
        Spacer()
        Button(showingRawData ? "Hide" : "Show") {
          withAnimation(.easeInOut(duration: 0.3)) {
            showingRawData.toggle()
          }
        }
        .foregroundColor(.blue)
      }

      if showingRawData {
        VStack(alignment: .leading, spacing: 12) {
          ForEach(sessionManager.currentSession?.tasks.filter { $0.isCompleted } ?? []) { task in
            VStack(alignment: .leading, spacing: 8) {
              Text(task.name)
                .font(.headline)
                .foregroundColor(.primary)

              if task.score != nil {
                Text("Raw Score Data:")
                  .font(.caption)
                  .foregroundColor(.secondary)

                RawScoreDisplay(task: task)
              }

              Divider()
            }
            .padding(.vertical, 4)
          }
        }
        .padding()
        .background(
          RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemGray6))
        )
        .transition(.opacity.combined(with: .scale))
      }
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    )
  }
}

struct RawScoreDisplay: View {
  let task: Task
  @ObservedObject private var sessionManager = SessionManager.shared

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      switch task.id {
      case "speech":
        if let score = sessionManager.getTaskScore(task.id, as: SpeechScore.self) {
          Text("• Raw Probability: \(String(format: "%.6f", score.probability))")
            .font(.caption2)
            .foregroundColor(.secondary)
          Text("• Percentage: \(String(format: "%.2f%%", score.probability * 100))")
            .font(.caption2)
            .foregroundColor(.secondary)
        }
      default:
        if let score = sessionManager.getTaskScore(task.id, as: GenericScore.self) {
          Text("• Value: \(score.value)")
            .font(.caption2)
            .foregroundColor(.secondary)
          if let details = score.details {
            ForEach(Array(details.keys.sorted()), id: \.self) { key in
              Text("• \(key): \(details[key] ?? "N/A")")
                .font(.caption2)
                .foregroundColor(.secondary)
            }
          }
        }
      }
    }
  }
}
