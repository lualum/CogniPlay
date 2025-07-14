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
    @State private var currentPattern: [Int] = []
    @StateObject private var sessionManager = SessionManager()
    
    enum AppView {
        case home, sessionChecklist, setupPattern, speech, simon, whackAMole, testPattern
    }
    
    var body: some View {
        ZStack {
            // Background color that extends beyond safe area
            Color.white
                .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                // Persistent Navigation Bar - extends beyond safe area
                PersistentNavBar(currentView: $currentView)
                
                // Main Content with safe area padding
                Group {
                    switch currentView {
                    case .home:
                        UpdatedHomeView(
                            showingTerms: $showingTerms,
                            termsAccepted: $termsAccepted,
                            currentView: $currentView,
                            sessionManager: sessionManager
                        )
                    case .sessionChecklist:
                        SessionChecklistView(sessionManager: sessionManager, currentView: $currentView)
                    case .setupPattern:
                        SetupPatternView(currentView: $currentView, currentPattern: $currentPattern)
                    case .speech:
                        SpeechView(currentView: $currentView)
                    case .simon:
                        SimonView(currentView: $currentView)
                    case .whackAMole:
                        WhackAMoleView(currentView: $currentView)
                    case .testPattern:
                        TestPatternView(currentView: $currentView, currentPattern: $currentPattern)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
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
        HStack(alignment: .center) {
            Button(action: {
                currentView = .home
            }) {
                Image(systemName: "house.fill")
                    .font(.title2)
                    .foregroundColor(.black)
                    .frame(width: 44, height: 44) // Standard touch target size
            }
            
            Spacer()
            
            Button(action: {
                // Settings action
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(.black)
                    .frame(width: 44, height: 44) // Standard touch target size
            }
        }
        .frame(height: 44) // Consistent height
        .padding(.horizontal, 20)
        .padding(.top, 15) // Add top padding to account for status bar and notch
        .padding(.bottom, 15)
        .background(Color.gray.opacity(0.15))
        .ignoresSafeArea(.container, edges: .top) // Extend beyond safe area at top
    }
}

// MARK: - Terms of Service View
struct TermsOfServiceView: View {
    @Binding var showingTerms: Bool
    @Binding var termsAccepted: Bool
    
    var body: some View {
        VStack(spacing: 0) {
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

