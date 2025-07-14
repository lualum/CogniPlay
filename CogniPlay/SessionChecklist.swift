//
//  SessionChecklist.swift
//  CogniPlay
//
//  Session checklist for tracking cognitive tests
//

import SwiftUI

// MARK: - Session Data Models
struct SessionTask {
    let id: String
    let name: String
    let duration: String
    let colorName: String // Store color as string instead of Color
    var isCompleted: Bool = false
    var isLocked: Bool = true
    var isOptional: Bool = false
    
    // Computed property to get Color from string
    var color: Color {
        switch colorName {
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "blue": return .blue
        case "red": return .red
        default: return .gray
        }
    }
}

class SessionManager: ObservableObject {
    @Published var currentSession: Session?
    @Published var sessions: [Session] = []
    
    func createNewSession() {
        let newSession = Session(
            id: UUID().uuidString,
            date: Date(),
            tasks: createDefaultTasks()
        )
        currentSession = newSession
        sessions.append(newSession)
        saveSession()
    }
    
    func completeTask(_ taskId: String) {
        guard let sessionIndex = sessions.firstIndex(where: { $0.id == currentSession?.id }),
              let taskIndex = sessions[sessionIndex].tasks.firstIndex(where: { $0.id == taskId }) else { return }
        
        sessions[sessionIndex].tasks[taskIndex].isCompleted = true
        currentSession = sessions[sessionIndex]
        updateTaskLocks()
        saveSession()
    }
    
    private func updateTaskLocks() {
        guard let sessionIndex = sessions.firstIndex(where: { $0.id == currentSession?.id }) else { return }
        
        // Unlock first task if locked
        if !sessions[sessionIndex].tasks.isEmpty {
            sessions[sessionIndex].tasks[0].isLocked = false
        }
        
        // Unlock next task when previous is completed
        for i in 0..<sessions[sessionIndex].tasks.count - 1 {
            if sessions[sessionIndex].tasks[i].isCompleted {
                sessions[sessionIndex].tasks[i + 1].isLocked = false
            }
        }
        
        currentSession = sessions[sessionIndex]
    }
    
    private func createDefaultTasks() -> [SessionTask] {
        return [
            SessionTask(id: "setup", name: "Setup Pattern", duration: "(0:30)", colorName: "green", isLocked: false),
            SessionTask(id: "whack", name: "Whack-a-Mole", duration: "(1:00)", colorName: "orange"),
            SessionTask(id: "simon", name: "Simon Memory", duration: "(1:30)", colorName: "purple"),
            SessionTask(id: "speechSpeed", name: "Speech (Speed)", duration: "(1:00)", colorName: "blue"),
            SessionTask(id: "speechImage", name: "Speech (Image)", duration: "(1:00)", colorName: "blue"),
            SessionTask(id: "test", name: "Test Pattern", duration: "(0:30)", colorName: "green"),
            SessionTask(id: "heartbeat", name: "Link Watch Heartbeat Data", duration: "", colorName: "orange", isOptional: true),
            SessionTask(id: "previous", name: "Link Previous Data", duration: "", colorName: "orange", isOptional: true)
        ]
    }
    
    private func saveSession() {
        // Implement UserDefaults or Core Data persistence
        if let encoded = try? JSONEncoder().encode(currentSession) {
            UserDefaults.standard.set(encoded, forKey: "currentSession")
        }
    }
    
    func loadSession() {
        if let data = UserDefaults.standard.data(forKey: "currentSession"),
           let session = try? JSONDecoder().decode(Session.self, from: data) {
            currentSession = session
        }
    }
}

struct Session: Codable, Identifiable {
    let id: String
    let date: Date
    var tasks: [SessionTask]
    
    var sessionTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        return "Session \(formatter.string(from: date))"
    }
    
    var isCompleted: Bool {
        return tasks.filter { !$0.isOptional }.allSatisfy { $0.isCompleted }
    }
}

extension SessionTask: Codable {}

// MARK: - Session Checklist View
struct SessionChecklistView: View {
    @ObservedObject var sessionManager: SessionManager
    @Binding var currentView: ContentView.AppView
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack {
                if let session = sessionManager.currentSession {
                    Text(session.sessionTitle)
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 20)
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
                                sessionManager: sessionManager,
                                currentView: $currentView
                            )
                        }
                        
                        // Divider
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                            .padding(.vertical, 20)
                            .padding(.horizontal, 50)
                        
                        // Optional Tasks
                        ForEach(session.tasks.filter { $0.isOptional }, id: \.id) { task in
                            TaskRow(
                                task: task,
                                sessionManager: sessionManager,
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
    @ObservedObject var sessionManager: SessionManager
    @Binding var currentView: ContentView.AppView
    let isOptional: Bool
    
    init(task: SessionTask, sessionManager: SessionManager, currentView: Binding<ContentView.AppView>, isOptional: Bool = false) {
        self.task = task
        self.sessionManager = sessionManager
        self._currentView = currentView
        self.isOptional = isOptional
    }
    
    var body: some View {
        HStack(spacing: 15) {
            // Checkbox
            RoundedRectangle(cornerRadius: 3)
                .fill(task.isCompleted ? task.color : Color.clear)
                .frame(width: 20, height: 20)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(task.isLocked ? Color.gray : task.color, lineWidth: 2)
                )
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(task.isCompleted ? 1 : 0)
                )
            
            // Task Info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(task.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(task.isLocked ? .gray : .primary)
                        .strikethrough(task.isCompleted)
                    
                    if !task.duration.isEmpty {
                        Text(task.duration)
                            .font(.body)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                
                if isOptional {
                    Text("(optional, \(task.name.contains("Apple Watch") ? "Apple Watch required" : "sign in with Google"))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // Action Button
            if !task.isLocked {
                Button(action: {
                    navigateToTask(task.id)
                }) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "arrow.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(task.isCompleted ? .green : task.color)
                }
            } else {
                Image(systemName: "lock.fill")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(task.isLocked ? Color.gray.opacity(0.1) : Color.clear)
        )
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
        case "test":
            currentView = .testPattern
        case "heartbeat", "previous":
            // Handle optional tasks
            sessionManager.completeTask(taskId)
        default:
            break
        }
    }
}
