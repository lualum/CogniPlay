import SwiftUI
import UIKit

extension UIColor {
  func components() -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
    var (r, g, b, a): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
    guard self.getRed(&r, green: &g, blue: &b, alpha: &a) else {
      return nil
    }
    return (r, g, b, a)
  }
}

func blendColors(_ color1: Color, _ color2: Color, weight: CGFloat) -> Color {
  let clampedWeight = max(0, min(1, weight))  // Ensure within [0,1]

  let uiColor1 = UIColor(color1)
  let uiColor2 = UIColor(color2)

  guard let c1 = uiColor1.components(), let c2 = uiColor2.components() else {
    return Color.black
  }

  let red = c1.red * clampedWeight + c2.red * (1 - clampedWeight)
  let green = c1.green * clampedWeight + c2.green * (1 - clampedWeight)
  let blue = c1.blue * clampedWeight + c2.blue * (1 - clampedWeight)
  let alpha = c1.alpha * clampedWeight + c2.alpha * (1 - clampedWeight)

  return Color(red: Double(red), green: Double(green), blue: Double(blue), opacity: Double(alpha))
}
