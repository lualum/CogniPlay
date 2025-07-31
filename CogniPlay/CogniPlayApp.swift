import SwiftUI

struct DefaultButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .opacity(configuration.isPressed ? 0.85 : 1.0)
      .offset(y: configuration.isPressed ? 4 : 0)
      .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
  }
}

@main
struct CogniPlayApp: App {
  init() {
    UIButton.appearance().showsMenuAsPrimaryAction = false  // Optional UIKit fallback
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .buttonStyle(DefaultButtonStyle())
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
