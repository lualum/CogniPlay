//
//  SpeechView.swift
//  CogniPlay
//
//  Created by Lucas Lum on 6/29/25.
//

import SwiftUI

// MARK: - Speech View
struct SpeechView: View {
    @Binding var currentView: ContentView.AppView
    @State private var isRecording = false
    @State private var recordingTime = "XX / 1:00"
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Title
            VStack(spacing: 5) {
                Text("Speech")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Talk About Image")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
            }
            .padding(.bottom, 30)
            
            // Image placeholder
            Rectangle()
                .fill(Color.white)
                .stroke(Color.black, lineWidth: 1)
                .frame(width: 280, height: 200)
                .overlay(
                    // Placeholder for the actual image content
                    VStack {
                        Text("Image content would appear here")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("(Kitchen scene with family)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                )
                .padding(.bottom, 40)
            
            // Recording controls
            VStack(spacing: 20) {
                // Microphone button
                Button(action: {
                    isRecording.toggle()
                }) {
                    Image(systemName: isRecording ? "mic.fill" : "mic")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .frame(width: 80, height: 80)
                        .background(Color.black)
                        .clipShape(Circle())
                }
                
                // Timer
                Text(recordingTime)
                    .font(.title2)
                    .fontWeight(.medium)
                
                // Submit button
                Button(action: {
                    currentView = .home
                }) {
                    Text("Submit")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.green.opacity(0.7))
                        .cornerRadius(10)
                }
                .padding(.horizontal, 30)
            }
            
            Spacer()
        }
        .background(Color.white)
    }
}
