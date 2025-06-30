//
//  HomeView.swift
//  CogniPlay
//
//  Created by Lucas Lum on 6/29/25.
//

import SwiftUI

// MARK: - Home View
struct HomeView: View {
    @Binding var showingTerms: Bool
    @Binding var termsAccepted: Bool
    @Binding var currentView: ContentView.AppView
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // App Title
            Text("CogniPlay")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 40)
            
            VStack(spacing: 20) {
                // Speech Button
                Button(action: {
                    if termsAccepted {
                        currentView = .speech
                    } else {
                        showingTerms = true
                    }
                }) {
                    Text("Speech")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue.opacity(0.7))
                        .cornerRadius(10)
                }
                
                // Simon Button
                Button(action: {
                    if termsAccepted {
                        currentView = .simon
                    } else {
                        showingTerms = true
                    }
                }) {
                    Text("Simon")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.purple.opacity(0.7))
                        .cornerRadius(10)
                }
                
                // Whack-a-Mole Button
                Button(action: {
                    if termsAccepted {
                        currentView = .whackAMole
                    } else {
                        showingTerms = true
                    }
                }) {
                    Text("Whack-a-Mole")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.orange.opacity(0.7))
                        .cornerRadius(10)
                }
                
                // Results Button
                Button(action: {
                    // Results action
                }) {
                    Text("Results")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.red.opacity(0.6))
                        .cornerRadius(10)
                }
                
                // Info Button
                Button(action: {
                    // Info action
                }) {
                    Image(systemName: "info.circle.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.green.opacity(0.7))
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .background(Color.white)
    }
}
