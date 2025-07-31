import SwiftUI

struct HomeView: View {
  @Binding var showingTerms: Bool
  @Binding var termsAccepted: Bool
  @Binding var currentView: ContentView.AppView

  @ObservedObject private var sessionManager = SessionManager.shared
  @State private var hasExistingSession = false

  var body: some View {
    VStack(spacing: 0) {
      Spacer()

      // App Title
      Text("CogniPlay")
        .font(.largeTitle)
        .fontWeight(.bold)
        .foregroundColor(.black)  // Ensure text is visible
        .padding(.bottom, 40)

      VStack(spacing: 20) {
        // Check if a session exists
        if hasExistingSession {
          // Continue Session Button
          Button(action: {
            currentView = .sessionChecklist
          }) {
            VStack(spacing: 5) {
              Text("Continue Session")
                .font(.title2)
                .fontWeight(.medium)
              Text("Resume in progress")
                .font(.caption)
                .opacity(0.8)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(Color.green.opacity(0.8))
            .cornerRadius(12)
          }

          // Reset Session Button
          Button(action: {
            sessionManager.createNewSession()
            hasExistingSession = true  // Update state
            currentView = .sessionChecklist
          }) {
            VStack(spacing: 5) {
              Text("Reset Session")
                .font(.title2)
                .fontWeight(.medium)
              Text("Start a new assessment")
                .font(.caption)
                .opacity(0.8)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(Color.red.opacity(0.8))
            .cornerRadius(12)
          }

        } else {
          // New Session Button
          Button(action: {
            if termsAccepted {
              sessionManager.createNewSession()
              hasExistingSession = true  // Update state
              currentView = .sessionChecklist
            } else {
              showingTerms = true
            }
          }) {
            VStack(spacing: 5) {
              Text("New Session")
                .font(.title2)
                .fontWeight(.medium)
              Text("Start cognitive assessment")
                .font(.caption)
                .opacity(0.8)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(Color.blue.opacity(0.8))
            .cornerRadius(12)
          }
        }

        // Results History Button
        Button(action: {
          // Navigate to results history (implement later)
          print("Results History tapped")  // Debug action
          //currentView = .results
        }) {
          VStack(spacing: 5) {
            Text("Results History")
              .font(.title2)
              .fontWeight(.medium)
            Text("View past sessions")
              .font(.caption)
              .opacity(0.8)
          }
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .frame(height: 70)
          .background(Color.purple.opacity(0.8))
          .cornerRadius(12)
        }

        // Info Button
        Button(action: {
          print("Info tapped")  // Debug action
        }) {
          HStack {
            Image(systemName: "info.circle.fill")
              .font(.title2)
            Text("About CogniPlay")
              .font(.title3)
              .fontWeight(.medium)
          }
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .frame(height: 50)
          .background(Color.gray.opacity(0.6))
          .cornerRadius(10)
        }
      }
      .padding(.horizontal, 30)

      Spacer()
    }
    .background(Color.white)
    .onAppear {
      // Load sessions when view appears, not in body
      hasExistingSession = sessionManager.loadSessions()
    }
    .environmentObject(sessionManager)
  }
}
