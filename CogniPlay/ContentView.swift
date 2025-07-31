import SwiftUI

// MARK: - Main App Structure
struct ContentView: View {
  @State private var showingTerms = false
  @State private var termsAccepted = false
  @State private var currentView: AppView = .home

  @State private var currentPattern: [Int] = []
  @State private var whackAMoleScore: Double = 0
  @State private var simonScore: Int = 0

  @StateObject private var sessionManager = SessionManager.shared

  enum AppView {
    case home, sessionChecklist, setupPattern, speech, simon, whackAMole  //, testPattern
  }

  var body: some View {
    VStack(spacing: 0) {
      PersistentNavBar(currentView: $currentView)
      ZStack {
        // Background color that extends beyond safe area
        Color.white
          .ignoresSafeArea(.all)

        VStack(spacing: 0) {
          // Main Content with safe area padding
          Group {
            switch currentView {
            case .home:
              HomeView(
                showingTerms: $showingTerms,
                termsAccepted: $termsAccepted,
                currentView: $currentView
              )
            case .sessionChecklist:
              SessionChecklistView(
                currentView: $currentView
              )
            case .setupPattern:
              SetupPatternView(
                currentView: $currentView,
                currentPattern: $currentPattern
              )
            case .speech:
              SpeechView(currentView: $currentView)
            case .simon:
              SimonView(currentView: $currentView, simonScore: $simonScore)
            case .whackAMole:
              WhackAMoleView(
                currentView: $currentView,
                whackAMoleScore: $whackAMoleScore)
            /*case .testPattern:
             TestPatternView(currentView: $currentView, currentPattern: $currentPattern)*/
            }
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          // 1. Add a transition to specify the animation effect (fade)
          .transition(.opacity)
        }
      }
      // 2. Add an animation modifier that listens for changes to a specific value
      .animation(.easeInOut(duration: 0.2), value: currentView)
      .sheet(isPresented: $showingTerms) {
        TermsOfServiceView(
          showingTerms: $showingTerms,
          termsAccepted: $termsAccepted,
          currentView: $currentView
        )
        .buttonStyle(DefaultButtonStyle())
      }
    }
  }
}

// MARK: - Persistent Navigation Bar
struct PersistentNavBar: View {
  @Binding var currentView: ContentView.AppView

  var body: some View {
    HStack(alignment: .center) {
      Button(action: {
        currentView = .home
      }) {
        Image(systemName: "house.fill")
          .font(.title2)
          .foregroundColor(.black)
          .frame(width: 44, height: 44)  // Standard touch target size
      }
      .padding(.horizontal, 22)

      Spacer()

      Button(action: {
        // Settings action
      }) {
        Image(systemName: "gearshape.fill")
          .font(.title2)
          .foregroundColor(.black)
          .frame(width: 44, height: 44)  // Standard touch target size
      }
      .padding(.horizontal, 22)
    }
    .frame(height: 44)  // Consistent height
    .padding(.horizontal, 20)
    .padding(.top, 15)  // Add top padding to account for status bar and notch
    .padding(.bottom, 15)
    .background(Color.gray.opacity(0.15))
    .ignoresSafeArea(.container, edges: .top)  // Extend beyond safe area at top
  }
}
