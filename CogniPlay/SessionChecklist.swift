import SwiftUI

// MARK: - Session Checklist View
struct SessionChecklistView: View {
  @ObservedObject private var sessionManager = SessionManager.shared
  @Binding var currentView: ContentView.AppView

  var body: some View {
    VStack(spacing: 0) {
      VStack {
        if let session = sessionManager.currentSession {
          Text(session.sessionTitle)
            .font(.title)
            .fontWeight(.bold)
            .padding(.bottom, 30)
        }
      }

      ScrollView {
        VStack(spacing: 15) {
          if let session = sessionManager.currentSession {
            // Main Tasks
            ForEach(session.tasks.filter { !$0.isOptional }, id: \.id) { task in
              TaskRow(
                task: task,
                currentView: $currentView
              )
            }

            // Divider
            Rectangle()
              .fill(Color.gray.opacity(0.3))
              .frame(height: 1)
              .padding(.vertical, 5)
              .padding(.horizontal, 50)

            // Optional Tasks
            ForEach(session.tasks.filter { $0.isOptional }, id: \.id) { task in
              TaskRow(
                task: task,
                currentView: $currentView,
                isOptional: true
              )
            }

            // Go to Results Button
            Button(action: {
              //currentView = .results
            }) {
              Text("Go to Results")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(session.isCompleted ? Color.green : Color.green.opacity(0.5))
                .cornerRadius(10)
            }
            .padding(.top, 30)
            .padding(.horizontal, 30)
            .disabled(!session.isCompleted)
          }
        }
        .padding(.horizontal, 30)
      }

      Spacer()
    }
    .background(Color.white)
    .navigationBarTitleDisplayMode(.inline)
    .navigationBarBackButtonHidden(true)
    .toolbar {
      ToolbarItem(placement: .navigationBarLeading) {
        Button("Home") {
          currentView = .home
        }
      }
    }
  }
}

// MARK: - Task Row Component
struct TaskRow: View {
  let task: SessionTask
  @ObservedObject private var sessionManager = SessionManager.shared
  @Binding var currentView: ContentView.AppView
  let isOptional: Bool

  @State private var isAnimatingCompletion = false
  @State private var showCompletionEffect = false

  init(
    task: SessionTask,
    currentView: Binding<ContentView.AppView>,
    isOptional: Bool = false
  ) {
    self.task = task
    self._currentView = currentView
    self.isOptional = isOptional
  }

  var body: some View {
    HStack(spacing: 15) {
      // Checkbox with animation
      ZStack {
        if task.isCompleted {
          RoundedRectangle(cornerRadius: 3)
            .fill(Color.green.opacity(0.3))
            .frame(width: 22, height: 22)
            .scaleEffect(showCompletionEffect ? 1.2 : 1.0)
            .opacity(showCompletionEffect ? 0.3 : 1.0)
        } else {
          // Uncompleted state - stroke only
          RoundedRectangle(cornerRadius: 3)
            .stroke(task.isLocked ? Color.gray : Color.black, lineWidth: 2)
            .frame(width: 20, height: 20)
        }

        Image(systemName: "checkmark")
          .font(.system(size: 12, weight: .bold))
          .foregroundColor(.white)
          .scaleEffect(task.isCompleted ? (isAnimatingCompletion ? 1.3 : 1.0) : 0.0)
          .opacity(task.isCompleted ? 0.7 : 0)
          .animation(.spring(response: 0.4, dampingFraction: 0.6), value: task.isCompleted)
      }

      // Task Info
      VStack(alignment: .leading, spacing: 2) {
        HStack {
          Text(task.name)
            .font(.body)
            .fontWeight(.medium)
            .foregroundColor(task.isLocked ? .gray : .primary)
            .opacity(task.isCompleted ? 0.3 : 1.0)

          if !task.duration.isEmpty {
            Text(task.duration)
              .font(.body)
              .foregroundColor(.gray)
              .opacity(task.isCompleted ? 0.3 : 1.0)
          }

          Spacer()
        }

        if isOptional {
          Text(
            "(optional, \(task.name.contains("Apple Watch") ? "Apple Watch required" : "sign in with Google"))"
          )
          .font(.caption)
          .foregroundColor(.gray)
          .opacity(task.isCompleted ? 0.3 : 1.0)
        }
      }

      // Action Button with enhanced animations
      ZStack {
        if task.isLocked {
          Image(systemName: "lock.fill")
            .font(.title2)
            .foregroundColor(.gray)
            .frame(width: 28, height: 28)
        } else if !task.isCompleted {
          Button(action: {
            navigateToTask(task.id)
          }) {
            Image(systemName: task.isOptional ? "star.fill" : "arrow.right.circle.fill")
              .font(.title2)
              .foregroundColor(task.isOptional ? .orange : .green)
              .frame(width: 28, height: 28)
              .scaleEffect(1.0)
              .animation(.easeInOut(duration: 0.1), value: task.isCompleted)
          }
        }
      }
      .alignmentGuide(.firstTextBaseline) { d in d[VerticalAlignment.center] }
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 8)
    .scaleEffect(isAnimatingCompletion ? 1.02 : 1.0)
    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isAnimatingCompletion)
    .onChange(of: task.isCompleted) { oldValue, newValue in
      if !oldValue && newValue {
        triggerCompletionAnimation()
      }
    }
  }

  private func triggerCompletionAnimation() {
    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
      isAnimatingCompletion = true
      showCompletionEffect = true
    }

    // Reset animation states
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
      withAnimation(.easeOut(duration: 0.2)) {
        isAnimatingCompletion = false
        showCompletionEffect = false
      }
    }
  }

  private func navigateToTask(_ taskId: String) {
    switch taskId {
    case "setup":
      currentView = .setupPattern
    case "whack":
      currentView = .whackAMole
    case "simon":
      currentView = .simon
    case "speechSpeed", "speechImage":
      currentView = .speech
    //case "test":
    //currentView = .testPattern
    case "heartbeat", "previous":
      // Handle optional tasks
      sessionManager.completeTask(taskId)
    default:
      break
    }
  }
}
