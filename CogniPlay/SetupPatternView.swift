import Darwin
import SwiftUI

// MARK: - Setup Pattern Game View
struct SetupPatternView: View {
  @Binding var currentView: ContentView.AppView
  @Binding var currentPattern: [ShapeItem]
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

        Text("Drag & Drop")
          .font(.title3)
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
              shape: index < patternOrder.count ? patternOrder[index] : nil,
              index: index,
              isHovered: hoveredSlot == index,
              selectedShape: selectedShape,
              availableShapes: availableShapes,
              onRemove: { removeFromPattern(at: index) },
              onDrop: { shape in
                handleDropInSlot(shape: shape, at: index)
              },
              onTap: {
                if let selectedShape = selectedShape {
                  handleDropInSlot(shape: selectedShape, at: index)
                  self.selectedShape = nil
                }
              },
              onHoverChange: { isHovered in
                hoveredSlot = isHovered ? index : nil
              }
            )
          }
        }

        // Bottom row - 2 slots
        HStack(spacing: 20) {
          ForEach(3..<5) { index in
            PatternDropSlot(
              shape: index < patternOrder.count ? patternOrder[index] : nil,
              index: index,
              isHovered: hoveredSlot == index,
              selectedShape: selectedShape,
              availableShapes: availableShapes,
              onRemove: { removeFromPattern(at: index) },
              onDrop: { shape in
                handleDropInSlot(shape: shape, at: index)
              },
              onTap: {
                if let selectedShape = selectedShape {
                  handleDropInSlot(shape: selectedShape, at: index)
                  self.selectedShape = nil
                }
              },
              onHoverChange: { isHovered in
                hoveredSlot = isHovered ? index : nil
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
        Text("Available Objects:")
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
                $0.id == shape.id && $0.type == shape.type
              }),
              isSelected: selectedShape?.id == shape.id && selectedShape?.type == shape.type,
              isDragging: draggedShape?.id == shape.id && draggedShape?.type == shape.type,
              onDragStart: {
                if !patternOrder.contains(where: { $0.id == shape.id && $0.type == shape.type }) {
                  draggedShape = shape
                  selectedShape = nil
                }
              },
              onDragEnd: {
                draggedShape = nil
              },
              onTap: {
                if !patternOrder.contains(where: { $0.id == shape.id && $0.type == shape.type }) {
                  let isSameShape =
                    selectedShape?.id == shape.id && selectedShape?.type == shape.type
                  selectedShape = isSameShape ? nil : shape
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
      selectedShape = nil
    }
  }

  // MARK: - Helper Methods

  private func setupShapes() {
    availableShapes = generateRandomShapes()
  }

  private func generateRandomShapes() -> [ShapeItem] {
    let patternSets: [String: Int] = [
      "Animals": 59
    ]

    var shapes: [ShapeItem] = []
    var usedImageIDs: Set<String> = []  // Changed to String to store "type:id" combinations

    for i in 1...8 {
      let randomSetName = patternSets.keys.randomElement() ?? "Animals"
      let maxImages = patternSets[randomSetName] ?? 1

      // Keep trying until we find an unused image ID
      var randomImageID: Int
      var attempts = 0
      var uniqueKey: String

      repeat {
        randomImageID = Int.random(in: 1...maxImages)
        uniqueKey = "\(randomSetName):\(randomImageID)"
        attempts += 1

        // Safety check to prevent infinite loop if we run out of unique images
        if attempts > maxImages * 2 {
          // If we can't find a unique image, use a fallback
          randomImageID = Int.random(in: 1...maxImages)
          uniqueKey = "\(randomSetName):\(randomImageID)"
          break
        }
      } while usedImageIDs.contains(uniqueKey)

      usedImageIDs.insert(uniqueKey)

      shapes.append(
        ShapeItem(
          type: randomSetName,
          id: randomImageID
        ))
    }

    return shapes
  }

  private func loadCurrentPattern() {
    patternOrder = currentPattern
  }

  private func savePattern() {
    currentPattern = patternOrder
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
    if patternOrder.contains(where: { $0.id == shape.id && $0.type == shape.type }) {
      return
    }

    // Ensure the patternOrder array is large enough
    while patternOrder.count <= index {
      patternOrder.append(
        ShapeItem(type: "", id: -1)
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
            ShapeItem(type: "", id: -1)
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
  let availableShapes: [ShapeItem]
  let onRemove: () -> Void
  let onDrop: (ShapeItem) -> Void
  let onTap: () -> Void
  let onHoverChange: (Bool) -> Void

  @State private var isTargeted = false

  private var isTargetForSelection: Bool {
    selectedShape != nil && (shape == nil || shape?.id == -1)
  }

  var body: some View {
    RoundedRectangle(cornerRadius: 8)
      .stroke(
        isTargetForSelection ? Color.blue : (isHovered || isTargeted) ? Color.blue : Color.black,
        lineWidth: isTargetForSelection ? 3 : (isHovered || isTargeted) ? 3 : 2
      )
      .frame(width: 80, height: 80)
      .background(
        RoundedRectangle(cornerRadius: 8)
          .fill(
            isTargetForSelection
              ? Color.blue.opacity(0.1)
              : (isHovered || isTargeted) ? Color.blue.opacity(0.1) : Color.white
          )
      )
      .overlay(
        Group {
          if let shape = shape, shape.id != -1 {
            ZStack {
              Image(shape.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
          } else {
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
      .onDrop(of: [.text], isTargeted: $isTargeted) { providers in
        handleDrop(providers: providers)
      }
      .onChange(of: isTargeted) { _, targeted in
        onHoverChange(targeted)
      }
  }

  private func handleDrop(providers: [NSItemProvider]) -> Bool {
    guard let provider = providers.first else { return false }

    provider.loadObject(ofClass: NSString.self) { (object, error) in
      if let shapeString = object as? String {
        // Parse the shape string format "type:id"
        let components = shapeString.components(separatedBy: ":")
        if components.count == 2,
          let id = Int(components[1]),
          let shape = availableShapes.first(where: { $0.type == components[0] && $0.id == id })
        {
          DispatchQueue.main.async {
            onDrop(shape)
          }
        }
      }
    }
    return true
  }
}

struct DraggableShapeView: View {
  let shape: ShapeItem
  let isAlreadyInPattern: Bool
  let isSelected: Bool
  let isDragging: Bool
  let onDragStart: () -> Void
  let onDragEnd: () -> Void
  let onTap: () -> Void

  var body: some View {
    VStack(spacing: 5) {
      Image(shape.imageName)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 60, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    .scaleEffect(isDragging ? 0.8 : 0.9)
    .opacity(isAlreadyInPattern ? 0.3 : (isDragging ? 0.7 : 1.0))
    .overlay(
      // Selection indicator - only show when selected and not already in pattern
      isSelected && !isAlreadyInPattern
        ? RoundedRectangle(cornerRadius: 8)
          .stroke(Color.blue, lineWidth: 3)
          .background(Color.blue.opacity(0.2))
        : nil
    )
    .animation(.easeInOut(duration: 0.2), value: isDragging)
    .animation(.easeInOut(duration: 0.2), value: isSelected)
    .onTapGesture {
      if !isAlreadyInPattern {
        onTap()
      }
    }
    .draggable("\(shape.type):\(shape.id)") {
      // Drag preview
      DragPreview(shape: shape)
        .onAppear { onDragStart() }
        .onDisappear { onDragEnd() }
    }
  }
}

struct DragPreview: View {
  let shape: ShapeItem

  var body: some View {
    VStack(spacing: 5) {
      Image(shape.imageName)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 50, height: 50)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    .padding(8)
    .background(Color.white.opacity(0.9))
    .cornerRadius(8)
    .shadow(radius: 5)
  }
}

struct DraggableShape: View {
  let shape: ShapeItem

  var body: some View {
    VStack(spacing: 5) {
      Image(shape.imageName)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 60, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    .scaleEffect(0.9)
    .opacity(0.8)
  }
}

struct ShapeItem: Identifiable, Equatable, Codable {
  let type: String
  let id: Int

  var imageName: String {
    "\(type)/\(id)"
  }
}
