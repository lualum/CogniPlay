// TaskFlowView.swift
import SwiftUI

struct TaskFlowView: View {
  let task: Task
  @Binding var currentView: ContentView.AppView
  @ObservedObject var sessionManager = SessionManager.shared

  @State private var showTutorial = true
  @State private var gameStarted = false

  var body: some View {
    if showTutorial && !task.tutorialSteps.isEmpty {
      TutorialView(steps: task.tutorialSteps) {
        showTutorial = false
        gameStarted = true
      }
    } else if gameStarted || task.tutorialSteps.isEmpty {
      TaskGameFactory.makeView(for: task, currentView: $currentView)
    }
  }
}

struct TutorialView: View {
  let steps: [TutorialStep]
  let onComplete: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      Text("Instructions")
        .font(.title)
        .fontWeight(.bold)

      VStack(alignment: .leading, spacing: 15) {
        ForEach(steps) { step in
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
  }
}
