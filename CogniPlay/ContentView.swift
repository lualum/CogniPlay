//
//  ContentView.swift
//  CogniPlay
//
//  Created by Lucas Lum on 6/28/25.
//

import SwiftUI

// MARK: - Main App Structure
struct ContentView: View {
    @State private var showingTerms = false
    @State private var termsAccepted = false
    @State private var currentView: AppView = .home
    
    enum AppView {
        case home, speech, simon, whackAMole
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Persistent Navigation Bar
            PersistentNavBar(currentView: $currentView)
            
            // Main Content
            Group {
                switch currentView {
                case .home:
                    HomeView(
                        showingTerms: $showingTerms,
                        termsAccepted: $termsAccepted,
                        currentView: $currentView
                    )
                case .speech:
                    SpeechView(currentView: $currentView)
                case .simon:
                    SimonView(currentView: $currentView)
                case .whackAMole:
                    WhackAMoleView(currentView: $currentView)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .sheet(isPresented: $showingTerms) {
            TermsOfServiceView(
                showingTerms: $showingTerms,
                termsAccepted: $termsAccepted
            )
        }
    }
}

// MARK: - Persistent Navigation Bar
struct PersistentNavBar: View {
    @Binding var currentView: ContentView.AppView
    
    var body: some View {
        HStack {
            Button(action: {
                currentView = .home
            }) {
                Image(systemName: "house.fill")
                    .font(.title2)
                    .foregroundColor(.black)
            }
            
            Spacer()
            
            Button(action: {
                // Settings action
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(.black)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(Color.gray.opacity(0.15))
    }
}



// MARK: - Terms of Service View
struct TermsOfServiceView: View {
    @Binding var showingTerms: Bool
    @Binding var termsAccepted: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Navigation
            HStack {
                Button(action: {
                    // Home action
                }) {
                    Image(systemName: "house.fill")
                        .font(.title2)
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                Button(action: {
                    // Settings action
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundColor(.black)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(Color.gray.opacity(0.15))
            
            // Terms Content
            VStack(spacing: 20) {
                Text("Terms of Service")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                // Terms content area (placeholder)
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(
                        Text("Terms of Service content would appear here...")
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    )
                
                // Action Buttons
                HStack(spacing: 15) {
                    Button(action: {
                        showingTerms = false
                    }) {
                        Text("Cancel")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.red.opacity(0.6))
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        termsAccepted = true
                        showingTerms = false
                    }) {
                        Text("Agree &\nContinue")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.green.opacity(0.7))
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
}

