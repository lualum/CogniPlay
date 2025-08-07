import SwiftUI

// MARK: - Main App Structure
struct ContentView: View {
  @State private var showingTerms = false

  // Persistent state variables using @AppStorage
  @AppStorage("termsAccepted") private var termsAccepted = false

  @AppStorage("currentPatternData") private var currentPatternData: Data = Data()

  @State private var currentView: AppView = .home
  @StateObject private var sessionManager = SessionManager.shared
  // State variable for the current pattern that syncs with AppStorage
  @State private var currentPattern: [ShapeItem] = []

  enum AppView {
    case home, sessionChecklist, about, setupPattern, speech, simon, whackAMole, testPattern,
      results
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
              SessionChecklistView(currentView: $currentView)
            case .about:
              AboutView(currentView: $currentView)
            case .setupPattern:
              SetupPatternView(
                currentView: $currentView,
                currentPattern: $currentPattern
              )
            case .speech:
              SpeechView(currentView: $currentView)
            case .simon:
              SimonView(currentView: $currentView)
            case .whackAMole:
              WhackAMoleView(currentView: $currentView)
            case .testPattern:
              TestPatternView(currentView: $currentView, currentPattern: $currentPattern)
            case .results:
              ResultsView(currentView: $currentView)
            }
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .transition(.opacity)
        }
      }
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
    .onAppear {
      loadCurrentPattern()
    }
    .onChange(of: currentPattern) { _ in
      saveCurrentPattern()
    }
  }

  // MARK: - Pattern Persistence Methods
  private func loadCurrentPattern() {
    guard !currentPatternData.isEmpty else {
      currentPattern = []
      return
    }

    do {
      currentPattern = try JSONDecoder().decode([ShapeItem].self, from: currentPatternData)
    } catch {
      currentPattern = []
      currentPatternData = Data()
    }
  }

  private func saveCurrentPattern() {
    do {
      currentPatternData = try JSONEncoder().encode(currentPattern)
    } catch {
      print("Failed to encode current pattern: \(error)")
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
          .frame(width: 44, height: 44)
      }
      .padding(.horizontal, 22)

      Spacer()

      Button(action: {
        // Settings action
      }) {
        Image(systemName: "gearshape.fill")
          .font(.title2)
          .foregroundColor(.black)
          .frame(width: 44, height: 44)
      }
      .padding(.horizontal, 22)
    }
    .frame(height: 44)
    .padding(.horizontal, 20)
    .padding(.top, 15)
    .padding(.bottom, 15)
    .background(Color.gray.opacity(0.15))
    .ignoresSafeArea(.container, edges: .top)
  }
}
