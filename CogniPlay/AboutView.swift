import SwiftUI

struct AboutView: View {
  @Binding var currentView: ContentView.AppView

  var body: some View {
    VStack(spacing: 0) {
      // ScrollView takes up all available space
      ScrollView {
        VStack(alignment: .center, spacing: 24) {
          // Header
          Text("About Our App")
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .center)

          // About Section
          VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "About", icon: "info.circle.fill")

            Text(
              "Our app is a non-invasive tool designed to screen for early signs of dementia using accessible data that is typically not seen in other tests—such as speech patterns, reaction time, and other biomarkers."
            )
            .font(.body)
            .lineSpacing(4)

            Text(
              "Unlike traditional screenings that rely on costly scans or invasive procedures, our app enables early detection in a user-friendly, low-barrier format."
            )
            .font(.body)
            .lineSpacing(4)

            Text(
              "Dementia is often diagnosed too late for effective intervention, largely because current tools like MRIs and PET scans are expensive, time-consuming, and not scalable for routine use. Our app bridges this gap by offering an accessible method of early screening, improving the chances for better outcomes and proactive care planning."
            )
            .font(.body)
            .lineSpacing(4)

            // Benefits Card
            VStack(alignment: .leading, spacing: 12) {
              Text("Who Benefits:")
                .font(.headline)
                .fontWeight(.semibold)

              BenefitRow(text: "Older adults at increased risk of cognitive decline")
              BenefitRow(
                text:
                  "Individuals who may be socially isolated or without regular medical oversight")
              BenefitRow(text: "Families and caregivers seeking early detection")
              BenefitRow(text: "Healthcare providers improving clinical efficiency")
              BenefitRow(text: "Underserved communities with limited access to neurological care")
            }
            .padding()
            .background(Color.blue.opacity(0.05))
            .cornerRadius(12)
          }

          // Grading/Results Section
          VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Grading & Results", icon: "chart.bar.fill")

            Text(
              "We convert the app's outputs into an estimated **MMSE (Mini-Mental State Examination)** score—a widely recognized 30-point scale for cognitive assessment."
            )
            .font(.body)
            .lineSpacing(4)

            // Process Steps
            VStack(alignment: .leading, spacing: 12) {
              ProcessStep(
                title: "Converting to MMSE:",
                description:
                  "Using data from clinical trials, we created a relation between game features (like time between inputs, accuracy, etc.) and an MMSE score."
              )

              ProcessStep(
                title: "Score Estimation:",
                description:
                  "A weighted average is calculated across all metrics to generate a final MMSE-equivalent score."
              )

              ProcessStep(
                title: "All Features:",
                description:
                  "See [View Details] in the results page to see all stats that were collected/used."
              )
            }
            .padding()
            .background(Color.green.opacity(0.05))
            .cornerRadius(12)

            // MMSE Score Interpretation
            VStack(alignment: .leading, spacing: 12) {
              Text("MMSE Score Interpretation:")
                .font(.headline)
                .fontWeight(.semibold)

              ScoreRange(range: "25 to 30", description: "is considered normal", color: .green)
              ScoreRange(
                range: "21 to 24", description: "may indicate mild cognitive impairment",
                color: .orange)
              ScoreRange(
                range: "20 or less",
                description: "suggests likelihood of dementia-related cognitive decline",
                color: .red)
            }
            .padding()
            .background(Color.purple.opacity(0.1))
            .cornerRadius(12)

            Text(
              "This model allows for continuous monitoring over time, giving users and clinicians a clearer picture of cognitive health—without the need for clinic visits or advanced imaging."
            )
            .font(.body)
            .lineSpacing(4)
          }
        }
        .padding(.horizontal)
        .padding(.bottom, 16)
      }
      .background(Color.clear)
      .clipShape(RoundedRectangle(cornerRadius: 10))
      .padding(.bottom, 16)

      // Fixed button at bottom
      Button(action: {
        currentView = .about
      }) {
        HStack {
          Image(systemName: "house.fill")
            .font(.title2)
          Button(action: {
            currentView = .home
          }) {
            Text("Return Home")
              .font(.title3)
              .fontWeight(.medium)
          }
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(Color.blue.opacity(0.6))
        .cornerRadius(10)
      }
      .padding(.horizontal)
      .padding(.bottom, 16)  // Add padding for safe area if needed
    }
  }
}

// MARK: - Supporting Views

struct SectionHeader: View {
  let title: String
  let icon: String

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: icon)
        .font(.title2)
        .foregroundColor(.blue)

      Text(title)
        .font(.title2)
        .fontWeight(.bold)
    }
  }
}

struct BenefitRow: View {
  let text: String

  var body: some View {
    HStack(alignment: .top, spacing: 8) {
      Image(systemName: "checkmark.circle.fill")
        .font(.caption)
        .foregroundColor(.blue)
        .padding(.top, 2)

      Text(text)
        .font(.body)
        .lineSpacing(2)
    }
  }
}

struct ProcessStep: View {
  let title: String
  let description: String

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .font(.headline)
        .fontWeight(.semibold)
        .foregroundColor(.green)

      Text(description)
        .font(.body)
        .lineSpacing(2)
    }
  }
}

struct ScoreRange: View {
  let range: String
  let description: String
  let color: Color

  var body: some View {
    HStack(alignment: .top, spacing: 8) {
      Text(range)
        .font(.body)
        .fontWeight(.bold)
        .foregroundColor(color)
        .frame(width: 80)
        .multilineTextAlignment(.center)

      Text(description)
        .font(.body)
        .lineSpacing(2)
        .multilineTextAlignment(.center)  // ensures multi-line center alignment
        .frame(maxWidth: .infinity)
    }
  }
}
