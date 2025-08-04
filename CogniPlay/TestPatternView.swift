import Darwin
import SwiftUI

// MARK: - Test Pattern Game View
struct TestPatternView: View {
  @Binding var currentView: ContentView.AppView
  @Binding var currentPattern: [ShapeItem]
  @ObservedObject private var sessionManager = SessionManager.shared

  @State private var availableShapes: [ShapeItem] = []
  @State private var selectedOrder: [ShapeItem] = []
  @State private var draggedShape: ShapeItem?
  @State private var hoveredSlot: Int?
  @State private var selectedShape: ShapeItem?
  @State private var isTestComplete = false
  @State private var testResult: Int = 0  // Fixed: Added default value

  private var isSelectionComplete: Bool {
    selectedOrder.count == 5 && !selectedOrder.contains { $0.id == -1 }
  }

  var body: some View {
    VStack(spacing: 0) {
      // Header with title
      VStack(spacing: 20) {
        Text("Memory Test")
          .font(.largeTitle)
          .fontWeight(.bold)
          .foregroundColor(.black)

        Text("Recreate the pattern you just learned")
          .font(.title3)
          .fontWeight(.medium)
          .foregroundColor(.black)
      }
      .padding(.top, 40)
      .padding(.bottom, 20)

      Spacer()

      // Selected Order Area - Main drop zones
      VStack(spacing: 20) {
        // Top row - 3 slots
        HStack(spacing: 20) {
          ForEach(0..<3) { index in
            TestDropSlot(
              shape: index < selectedOrder.count ? selectedOrder[index] : nil,
              index: index,
              isHovered: hoveredSlot == index,
              selectedShape: selectedShape,
              availableShapes: availableShapes,
              correctShape: index < currentPattern.count ? currentPattern[index] : nil,
              showResult: isTestComplete,
              onRemove: { removeFromSelection(at: index) },
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
            TestDropSlot(
              shape: index < selectedOrder.count ? selectedOrder[index] : nil,
              index: index,
              isHovered: hoveredSlot == index,
              selectedShape: selectedShape,
              availableShapes: availableShapes,
              correctShape: index < currentPattern.count ? currentPattern[index] : nil,
              showResult: isTestComplete,
              onRemove: { removeFromSelection(at: index) },
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

      // Test Result Display
      if isTestComplete {
        VStack(spacing: 10) {
          Text("Test Complete!")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(getScoreColor(for: testResult))

          Text("Score: \(Int(Double(testResult) / 5.0 * 100))%")
            .font(.title3)
            .fontWeight(.medium)

          Text("\(testResult) out of 5 correct")
            .font(.body)
            .foregroundColor(.gray)
        }
        .padding(.bottom, 20)
      }

      // Available Shapes
      if !isTestComplete {
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
              TestDraggableShapeView(
                shape: shape,
                isAlreadySelected: selectedOrder.contains(where: {
                  $0.id == shape.id && $0.type == shape.type
                }),
                isSelected: selectedShape?.id == shape.id && selectedShape?.type == shape.type,
                isDragging: draggedShape?.id == shape.id && draggedShape?.type == shape.type,
                onDragStart: {
                  if !selectedOrder.contains(where: { $0.id == shape.id && $0.type == shape.type })
                  {
                    draggedShape = shape
                    selectedShape = nil
                  }
                },
                onDragEnd: {
                  draggedShape = nil
                },
                onTap: {
                  if !selectedOrder.contains(where: { $0.id == shape.id && $0.type == shape.type })
                  {
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
      }

      // Control Buttons
      HStack(spacing: 20) {
        if !isTestComplete {
          Button("Clear All") {
            clearSelection()
          }
          .font(.title2)
          .fontWeight(.medium)
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .frame(height: 50)
          .background(Color.red.opacity(0.7))
          .cornerRadius(10)

          Button("Submit") {
            if isSelectionComplete {
              submitTest()
            }
          }
          .font(.title2)
          .fontWeight(.medium)
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .frame(height: 50)
          .background(isSelectionComplete ? Color.blue.opacity(0.7) : Color.blue.opacity(0.3))
          .cornerRadius(10)
          .disabled(!isSelectionComplete)
        } else {
          Button("Continue") {
            sessionManager.completeTask("test")
            currentView = .sessionChecklist
          }
          .font(.title2)
          .fontWeight(.medium)
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .frame(height: 50)
          .background(Color.green.opacity(0.7))
          .cornerRadius(10)
        }
      }
      .padding(.horizontal, 40)
      .padding(.bottom, 50)
    }
    .background(Color.white)
    .onAppear {
      setupTestShapes()
    }
    .onTapGesture {
      if !isTestComplete {
        selectedShape = nil
      }
    }
  }

  // MARK: - Helper Methods

  private func getScoreColor(for score: Int) -> Color {
    let percentage = Double(score) / 5.0
    if percentage >= 0.8 {
      return .green
    } else if percentage >= 0.6 {
      return .orange
    } else {
      return .red
    }
  }

  private func setupTestShapes() {
    // Start with the 5 objects from currentPattern
    var testShapes = currentPattern

    // Generate 3 additional different shapes
    let additionalShapes = generateAdditionalShapes(excluding: currentPattern)
    testShapes.append(contentsOf: additionalShapes)

    // Shuffle the list
    availableShapes = testShapes.shuffled()
  }

  private func generateAdditionalShapes(excluding existingShapes: [ShapeItem]) -> [ShapeItem] {
    let patternSets: [String: Int] = [
      "Animals": 59
    ]

    var shapes: [ShapeItem] = []
    var usedImageIDs: Set<String> = Set(existingShapes.map { "\($0.type):\($0.id)" })
    var attempts = 0
    let maxAttempts = 100  // Safety check to prevent infinite loop

    while shapes.count < 3 && attempts < maxAttempts {
      let randomSetName = patternSets.keys.randomElement() ?? "Animals"
      let maxImages = patternSets[randomSetName] ?? 1
      let randomImageID = Int.random(in: 1...maxImages)
      let uniqueKey = "\(randomSetName):\(randomImageID)"

      if !usedImageIDs.contains(uniqueKey) {
        usedImageIDs.insert(uniqueKey)
        shapes.append(
          ShapeItem(
            type: randomSetName,
            id: randomImageID
          )
        )
      }
      attempts += 1
    }

    // If we couldn't generate 3 unique shapes, fill with fallback shapes
    while shapes.count < 3 {
      let fallbackShape = ShapeItem(
        type: "Animals",
        id: Int.random(in: 1...59)
      )
      if !usedImageIDs.contains("\(fallbackShape.type):\(fallbackShape.id)") {
        shapes.append(fallbackShape)
        usedImageIDs.insert("\(fallbackShape.type):\(fallbackShape.id)")
      }
    }

    return shapes
  }

  private func clearSelection() {
    selectedOrder.removeAll()
    selectedShape = nil
  }

  private func removeFromSelection(at index: Int) {
    if index < selectedOrder.count {
      selectedOrder.remove(at: index)
    }
  }

  private func handleDropInSlot(shape: ShapeItem, at index: Int) {
    // Don't allow duplicate shapes in the selection
    if selectedOrder.contains(where: { $0.id == shape.id && $0.type == shape.type }) {
      return
    }

    // Ensure the selectedOrder array is large enough
    while selectedOrder.count <= index {
      selectedOrder.append(
        ShapeItem(type: "", id: -1)
      )
    }

    // If there's already a shape at this position and it's not empty, shift it
    if index < selectedOrder.count && selectedOrder[index].id != -1 {
      // Find the next empty slot or append at the end
      var nextEmptyIndex = -1
      for i in 0..<5 {
        if i >= selectedOrder.count || selectedOrder[i].id == -1 {
          nextEmptyIndex = i
          break
        }
      }

      if nextEmptyIndex != -1 && nextEmptyIndex < 5 {
        while selectedOrder.count <= nextEmptyIndex {
          selectedOrder.append(
            ShapeItem(type: "", id: -1)
          )
        }
        selectedOrder[nextEmptyIndex] = selectedOrder[index]
      }
    }

    // Place the new shape
    selectedOrder[index] = shape

    // Remove empty placeholders at the end
    while selectedOrder.last?.id == -1 {
      selectedOrder.removeLast()
    }
  }

  private func submitTest() {
    testResult = evaluateTest()
    isTestComplete = true

    // Fixed: Create a proper score object or just pass the integer
    sessionManager.completeTask("test", withScore: TestPatternScore(score: testResult))
  }

  private func evaluateTest() -> Int {
    var correctCount = 0

    for (index, selectedShape) in selectedOrder.enumerated() {
      if index < currentPattern.count {
        let correctShape = currentPattern[index]
        if selectedShape.id == correctShape.id && selectedShape.type == correctShape.type {
          correctCount += 1
        }
      }
    }

    return correctCount
  }
}

struct TestDropSlot: View {
  let shape: ShapeItem?
  let index: Int
  let isHovered: Bool
  let selectedShape: ShapeItem?
  let availableShapes: [ShapeItem]
  let correctShape: ShapeItem?
  let showResult: Bool
  let onRemove: () -> Void
  let onDrop: (ShapeItem) -> Void
  let onTap: () -> Void
  let onHoverChange: (Bool) -> Void

  @State private var isTargeted = false

  private var isTargetForSelection: Bool {
    selectedShape != nil && (shape == nil || shape?.id == -1)
  }

  private var isCorrect: Bool {
    guard showResult, let shape = shape, let correctShape = correctShape else { return false }
    return shape.id == correctShape.id && shape.type == correctShape.type
  }

  private var borderColor: Color {
    if showResult {
      return isCorrect ? .green : .red
    }
    return isTargetForSelection ? .blue : (isHovered || isTargeted) ? .blue : .black
  }

  private var backgroundColor: Color {
    if showResult {
      return isCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.1)
    }
    return isTargetForSelection
      ? Color.blue.opacity(0.1) : (isHovered || isTargeted) ? Color.blue.opacity(0.1) : Color.white
  }

  var body: some View {
    RoundedRectangle(cornerRadius: 8)
      .stroke(
        borderColor,
        lineWidth: showResult ? 4 : (isTargetForSelection || isHovered || isTargeted) ? 3 : 2
      )
      .frame(width: 80, height: 80)
      .background(
        RoundedRectangle(cornerRadius: 8)
          .fill(backgroundColor)
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

              // Show correct/incorrect indicator
              if showResult {
                VStack {
                  Spacer()
                  HStack {
                    Spacer()
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                      .foregroundColor(isCorrect ? .green : .red)
                      .background(Color.white)
                      .clipShape(Circle())
                      .font(.system(size: 16))
                  }
                }
                .padding(4)
              }
            }
          } else {
            EmptyView()
          }
        }
      )
      .onTapGesture {
        if !showResult {
          if selectedShape != nil {
            onTap()
          } else if shape != nil && shape?.id != -1 {
            onRemove()
          }
        }
      }
      .onDrop(of: [.text], isTargeted: $isTargeted) { providers in
        showResult ? false : handleDrop(providers: providers)
      }
      .onChange(of: isTargeted) { _, targeted in
        if !showResult {
          onHoverChange(targeted)
        }
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

struct TestDraggableShapeView: View {
  let shape: ShapeItem
  let isAlreadySelected: Bool
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
    .opacity(isAlreadySelected ? 0.3 : (isDragging ? 0.7 : 1.0))
    .overlay(
      // Selection indicator - only show when selected and not already selected
      isSelected && !isAlreadySelected
        ? RoundedRectangle(cornerRadius: 8)
          .stroke(Color.blue, lineWidth: 3)
          .background(Color.blue.opacity(0.2))
        : nil
    )
    .animation(.easeInOut(duration: 0.2), value: isDragging)
    .animation(.easeInOut(duration: 0.2), value: isSelected)
    .onTapGesture {
      if !isAlreadySelected {
        onTap()
      }
    }
    .draggable("\(shape.type):\(shape.id)") {
      // Drag preview
      TestDragPreview(shape: shape)
        .onAppear { onDragStart() }
        .onDisappear { onDragEnd() }
    }
  }
}

struct TestDragPreview: View {
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
