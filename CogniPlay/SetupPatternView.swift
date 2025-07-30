import Darwin
import SwiftUI

// MARK: - Setup Pattern Game View
struct SetupPatternView: View {
  @Binding var currentView: ContentView.AppView
  @Binding var currentPattern: [Int]
  @ObservedObject private var sessionManager = SessionManager.shared

  @State private var availableShapes: [ShapeItem] = []
  @State private var patternOrder: [ShapeItem] = []
  @State private var draggedShape: ShapeItem?
  @State private var hoveredSlot: Int?
  @State private var selectedShape: ShapeItem?

  private var isPatternComplete: Bool {
    patternOrder.count == 5 && !patternOrder.contains { $0.id == -1 }
  }

  var body: some View {
    VStack(spacing: 0) {
      // Header with title
      VStack(spacing: 20) {
        Text("Ordering")
          .font(.largeTitle)
          .fontWeight(.bold)
          .foregroundColor(.black)

        Text("Drag & Drop or Tap Object then Tap Slot")
          .font(.title2)
          .fontWeight(.medium)
          .foregroundColor(.black)
      }
      .padding(.top, 40)
      .padding(.bottom, 20)

      Spacer()

      // Pattern Order Area - Main drop zones
      VStack(spacing: 20) {
        // Top row - 3 slots
        HStack(spacing: 20) {
          ForEach(0..<3) { index in
            PatternDropSlot(
              shape: index < patternOrder.count
                ? patternOrder[index] : nil,
              index: index,
              isHovered: hoveredSlot == index,
              selectedShape: selectedShape,
              onRemove: { removeFromPattern(at: index) },
              onDrop: { shape in
                handleDropInSlot(shape: shape, at: index)
              },
              onTap: {
                if let selectedShape = selectedShape {
                  handleDropInSlot(
                    shape: selectedShape,
                    at: index
                  )
                  self.selectedShape = nil
                }
              }
            )
          }
        }

        // Bottom row - 2 slots
        HStack(spacing: 20) {
          ForEach(3..<5) { index in
            PatternDropSlot(
              shape: index < patternOrder.count
                ? patternOrder[index] : nil,
              index: index,
              isHovered: hoveredSlot == index,
              selectedShape: selectedShape,
              onRemove: { removeFromPattern(at: index) },
              onDrop: { shape in
                handleDropInSlot(shape: shape, at: index)
              },
              onTap: {
                if let selectedShape = selectedShape {
                  handleDropInSlot(
                    shape: selectedShape,
                    at: index
                  )
                  self.selectedShape = nil
                }
              }
            )
          }
        }
      }
      .padding(.horizontal, 40)
      .padding(.bottom, 20)

      Spacer()

      // Available Shapes
      VStack(alignment: .leading, spacing: 15) {
        Text("Available Shapes:")
          .font(.headline)
          .padding(.horizontal, 40)

        LazyVGrid(
          columns: Array(
            repeating: GridItem(.flexible(), spacing: 10),
            count: 4
          ),
          spacing: 15
        ) {
          ForEach(availableShapes, id: \.id) { shape in
            DraggableShapeView(
              shape: shape,
              isAlreadyInPattern: patternOrder.contains(where: {
                $0.id == shape.id
              }),
              isSelected: selectedShape?.id == shape.id,
              onDragStart: {
                // Only allow drag if not already in pattern
                if !patternOrder.contains(where: { $0.id == shape.id }) {
                  draggedShape = shape
                  selectedShape = nil  // Clear selection when dragging
                }
              },
              onDragEnd: { draggedShape = nil },
              onTap: {
                // Only allow selection if not already in pattern
                if !patternOrder.contains(where: { $0.id == shape.id }) {
                  selectedShape = selectedShape?.id == shape.id ? nil : shape
                }
              }
            )
          }
        }
        .padding(.horizontal, 40)
      }
      .padding(.bottom, 20)

      // Control Buttons
      HStack(spacing: 20) {
        Button("Clear All") {
          clearPattern()
        }
        .font(.title2)
        .fontWeight(.medium)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(Color.red.opacity(0.7))
        .cornerRadius(10)

        Button("Done") {
          if isPatternComplete {
            savePattern()
            sessionManager.completeTask("setup")
            currentView = .sessionChecklist
          }
        }
        .font(.title2)
        .fontWeight(.medium)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(isPatternComplete ? Color.green.opacity(0.7) : Color.green.opacity(0.3))
        .cornerRadius(10)
        .disabled(!isPatternComplete)
      }
      .padding(.horizontal, 40)
      .padding(.bottom, 50)
    }
    .background(Color.white)
    .onAppear {
      setupShapes()
      loadCurrentPattern()
    }
    .onTapGesture {
      // Clear selection when tapping outside
      selectedShape = nil
    }
  }

  // MARK: - Helper Methods

  private func setupShapes() {
    // Generate random images from PatternSets
    availableShapes = generateRandomShapes()
  }

  private func generateRandomShapes() -> [ShapeItem] {
    let patternSets: [String: Int] = [
      "Animals": 59
    ]

    var shapes: [ShapeItem] = []

    for i in 1...8 {
      let randomSetName = patternSets.keys.randomElement() ?? "Animals"
      let maxImages = patternSets[randomSetName] ?? 1
      let randomImageNumber = Int.random(in: 1...maxImages)
      let imageName = "\(randomSetName)/\(randomImageNumber)"

      shapes.append(
        ShapeItem(
          id: i,
          imageName: imageName,
          color: Color.clear,
          name: "\(randomSetName) \(randomImageNumber)"
        ))
    }

    return shapes
  }

  private func loadCurrentPattern() {
    patternOrder = currentPattern.compactMap { id in
      availableShapes.first { $0.id == id }
    }
  }

  private func savePattern() {
    currentPattern = patternOrder.map { $0.id }
  }

  private func clearPattern() {
    patternOrder.removeAll()
    selectedShape = nil
  }

  private func removeFromPattern(at index: Int) {
    if index < patternOrder.count {
      patternOrder.remove(at: index)
    }
  }

  private func handleDropInSlot(shape: ShapeItem, at index: Int) {
    // Don't allow duplicate shapes in the pattern
    if patternOrder.contains(where: { $0.id == shape.id }) {
      return
    }

    // Ensure the patternOrder array is large enough
    while patternOrder.count <= index {
      patternOrder.append(
        ShapeItem(id: -1, imageName: "", color: .clear, name: "Empty")
      )
    }

    // If there's already a shape at this position and it's not empty, shift it
    if index < patternOrder.count && patternOrder[index].id != -1 {
      // Find the next empty slot or append at the end
      var nextEmptyIndex = -1
      for i in 0..<5 {
        if i >= patternOrder.count || patternOrder[i].id == -1 {
          nextEmptyIndex = i
          break
        }
      }

      if nextEmptyIndex != -1 && nextEmptyIndex < 5 {
        while patternOrder.count <= nextEmptyIndex {
          patternOrder.append(
            ShapeItem(
              id: -1,
              imageName: "",
              color: .clear,
              name: "Empty"
            )
          )
        }
        patternOrder[nextEmptyIndex] = patternOrder[index]
      }
    }

    // Place the new shape
    patternOrder[index] = shape

    // Remove empty placeholders at the end
    while patternOrder.last?.id == -1 {
      patternOrder.removeLast()
    }
  }
}

// MARK: - Supporting Views

struct PatternDropSlot: View {
  let shape: ShapeItem?
  let index: Int
  let isHovered: Bool
  let selectedShape: ShapeItem?
  let onRemove: () -> Void
  let onDrop: (ShapeItem) -> Void
  let onTap: () -> Void

  private var isTargetForSelection: Bool {
    selectedShape != nil && (shape == nil || shape?.id == -1)
  }

  var body: some View {
    RoundedRectangle(cornerRadius: 8)
      .stroke(
        isTargetForSelection ? Color.blue : isHovered ? Color.blue : Color.black,
        lineWidth: isTargetForSelection ? 3 : isHovered ? 3 : 2
      )
      .frame(width: 80, height: 80)
      .background(
        RoundedRectangle(cornerRadius: 8)
          .fill(
            isTargetForSelection
              ? Color.blue.opacity(0.1) : isHovered ? Color.blue.opacity(0.1) : Color.white)
      )
      .overlay(
        Group {
          if let shape = shape, shape.id != -1 {
            ZStack {
              if !shape.imageName.isEmpty {
                Image(shape.imageName)
                  .resizable()
                  .aspectRatio(contentMode: .fit)
                  .frame(width: 60, height: 60)
                  .clipShape(RoundedRectangle(cornerRadius: 4))
              }
            }
          } else {
            // Empty slot - no indicator
            EmptyView()
          }
        }
      )
      .onTapGesture {
        if selectedShape != nil {
          onTap()
        } else if shape != nil && shape?.id != -1 {
          onRemove()
        }
      }
      .onDrop(of: [.text], isTargeted: .constant(false)) { providers in
        handleDrop(providers: providers)
      }
  }

  private func handleDrop(providers: [NSItemProvider]) -> Bool {
    guard let provider = providers.first else { return false }

    provider.loadObject(ofClass: NSString.self) { (object, error) in
      if let idString = object as? String,
        let id = Int(idString),
        let shape = getShapeById(id)
      {
        DispatchQueue.main.async {
          onDrop(shape)
        }
      }
    }
    return true
  }

  private func getShapeById(_ id: Int) -> ShapeItem? {
    let patternSets: [String: Int] = [
      "Animals": 59
    ]

    let randomSetName = patternSets.keys.randomElement() ?? "Animals"
    let maxImages = patternSets[randomSetName] ?? 1
    let randomImageNumber = Int.random(in: 1...maxImages)
    let imageName = "\(randomSetName)/\(randomImageNumber)"

    return ShapeItem(
      id: id,
      imageName: imageName,
      color: Color.clear,
      name: "\(randomSetName) \(randomImageNumber)"
    )
  }
}

struct DraggableShapeView: View {
  let shape: ShapeItem
  let isAlreadyInPattern: Bool
  let isSelected: Bool
  let onDragStart: () -> Void
  let onDragEnd: () -> Void
  let onTap: () -> Void

  var body: some View {
    VStack(spacing: 5) {
      if !shape.imageName.isEmpty {
        Image(shape.imageName)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 60, height: 60)
          .clipShape(RoundedRectangle(cornerRadius: 8))
      } else {
        RoundedRectangle(cornerRadius: 8)
          .fill(Color.gray.opacity(0.3))
          .frame(width: 60, height: 60)
          .overlay(
            Text("No Image")
              .font(.caption2)
              .foregroundColor(.gray)
          )
      }
    }
    .scaleEffect(0.9)
    .opacity(isAlreadyInPattern ? 0.5 : 1.0)
    .overlay(
      // Selection indicator
      isSelected
        ? RoundedRectangle(cornerRadius: 8)
          .stroke(Color.blue, lineWidth: 3)
          .background(Color.blue.opacity(0.2))
        :  // Visual indicator if already used
        isAlreadyInPattern
          ? RoundedRectangle(cornerRadius: 8)
            .stroke(Color.gray, lineWidth: 2)
            .background(Color.gray.opacity(0.3))
          : nil
    )
    .onTapGesture {
      onTap()
    }
    .onDrag {
      onDragStart()
      return NSItemProvider(object: "\(shape.id)" as NSString)
    }
    .onDragEnd {
      onDragEnd()
    }
  }
}

struct DraggableShape: View {
  let shape: ShapeItem

  var body: some View {
    VStack(spacing: 5) {
      if !shape.imageName.isEmpty {
        Image(shape.imageName)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 60, height: 60)
          .clipShape(RoundedRectangle(cornerRadius: 8))
      }

      Text(shape.name)
        .font(.caption)
        .foregroundColor(.primary)
    }
    .scaleEffect(0.9)
    .opacity(0.8)
  }
}

// MARK: - Data Models

struct ShapeItem: Identifiable, Equatable {
  let id: Int
  let imageName: String
  let color: Color
  let name: String
}

// MARK: - View Extensions

extension View {
  func onDragEnd(_ action: @escaping () -> Void) -> some View {
    self.onEnded(action)
  }

  private func onEnded(_ action: @escaping () -> Void) -> some View {
    self.background(
      DragEndDetector(onDragEnd: action)
    )
  }
}

struct DragEndDetector: View {
  let onDragEnd: () -> Void

  var body: some View {
    Rectangle()
      .fill(Color.clear)
      .frame(width: 0, height: 0)
      .onReceive(
        NotificationCenter.default.publisher(
          for: .NSManagedObjectContextObjectsDidChange
        )
      ) { _ in
        onDragEnd()
      }
  }
}
