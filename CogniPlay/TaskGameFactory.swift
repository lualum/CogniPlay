import SwiftUI

enum TaskGameFactory {
  static func makeView(for task: Task, currentView: Binding<ContentView.AppView>) -> some View {
    switch task.id {
    case "speech":
      return AnyView(SpeechView(currentView: currentView))
    case "srtt":
      return AnyView(SRTTView(currentView: currentView))
    case "corsi":
      return AnyView(CorsiBlockView(currentView: currentView))
    case "clock":
      return AnyView(ClockView(currentView: currentView))
    default:
      return AnyView(
        Text("Task not implemented")
          .font(.title)
          .foregroundColor(.red)
      )
    }
  }
}
