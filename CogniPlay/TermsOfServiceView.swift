import SwiftUI

// MARK: - Terms of Service View
struct TermsOfServiceView: View {
  @Binding var showingTerms: Bool
  @Binding var termsAccepted: Bool
  @Binding var currentView: ContentView.AppView

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
            ScrollView {
              VStack(alignment: .leading, spacing: 16) {
                Text("Effective Date: July 27, 2025")
                  .font(.subheadline)
                  .foregroundColor(.gray)

                Group {
                  Text("1. Introduction")
                    .font(.headline)
                  Text(
                    "Welcome to CogniPlay, a mobile application designed to assist users in identifying potential early signs of dementia. Please read these Terms of Service (\"Terms\") carefully before using the App. By accessing or using the App, you agree to be bound by these Terms. If you do not agree to these Terms, you must not use the App."
                  )
                }

                Group {
                  Text("2. No Medical Advice")
                    .font(.headline)
                  Text(
                    "The App is intended for informational purposes only and does not provide a medical diagnosis. You should always consult with a qualified medical professional regarding any cognitive health concerns."
                  )
                }

                Group {
                  Text("3. Data Privacy and Consent")
                    .font(.headline)
                  Text(
                    "No personal data or health information is stored on external servers. All processing is done locally on your device. Data will only be used for training or research purposes if you provide explicit, informed consent and your healthcare provider approves."
                  )
                }

                Group {
                  Text("4. Limitation of Liability")
                    .font(.headline)
                  Text(
                    "CogniPlay is provided \"as is\" and \"as available\" without warranties of any kind. We are not liable for any damages arising from use of the App."
                  )
                }

                Group {
                  Text("5. Contact")
                    .font(.headline)
                  Text(
                    "If you have questions about these Terms, contact us at support@cogniplay.com."
                  )
                }
              }
              .padding()
              .foregroundColor(.primary)
            }
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
            currentView = .sessionChecklist
          }) {
            Text("Agree")
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
