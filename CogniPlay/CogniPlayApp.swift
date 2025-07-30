import SwiftUI

@main
struct CogniPlayApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
        .statusBar(hidden: true)
    }
  }
}

// MARK: Preview
struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
