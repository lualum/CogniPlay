import SwiftUI

struct ContentView: View {
  @State private var showingTerms = false

  @AppStorage("termsAccepted") private var termsAccepted = false

  @State private var currentView: AppView = .home
  @StateObject private var sessionManager = SessionManager.shared

  enum AppView {
    case home, sessionChecklist, about, speech, srtt, corsi, clock,
      results
  }

  var body: some View {
    VStack(spacing: 0) {
      PersistentNavBar(currentView: $currentView)
      ZStack {
        Color.white
          .ignoresSafeArea(.all)
        VStack(spacing: 0) {
          Group {
            switch currentView {
            case .home:
              HomeView(
                termsAccepted: $termsAccepted,
                currentView: $currentView
              )
            case .sessionChecklist:
              SessionChecklistView(currentView: $currentView)
            case .about:
              AboutView(currentView: $currentView)
            case .speech:
              SpeechView(currentView: $currentView)
            case .srtt:
              SRTTView(currentView: $currentView)
            case .corsi:
              CorsiBlockView(currentView: $currentView)
            case .clock:
              ClockView(currentView: $currentView)
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
        TermsView(
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
