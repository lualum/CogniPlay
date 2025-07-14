//
//  SetupPattern.swift
//  CogniPlay
//
//  Created by Lucas Lum on 6/29/25.
//

import Darwin
import SwiftUI

// MARK: - Setup Pattern Game View
struct SetupPatternView: View {
    @Binding var currentView: ContentView.AppView
    @Binding var currentPattern: [Int]

    @State private var availableShapes: [ShapeItem] = []
    @State private var patternOrder: [ShapeItem] = []
    @State private var draggedShape: ShapeItem?
    @State private var hoveredSlot: Int?
    @State private var selectedShape: ShapeItem?
    @State private var isSelectionMode: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Header with title
            VStack(spacing: 20) {
                Text("Ordering")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                if isSelectionMode {
                    Text("Tap Object, then Tap Slot")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                else {
                    Text("Drag and Drop")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                }

                // Mode toggle for simulator testing
                HStack {
                    Button(
                        isSelectionMode
                            ? "Switch to Drag Mode" : "Switch to Tap Mode"
                    ) {
                        isSelectionMode.toggle()
                        selectedShape = nil
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
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
                            isSelectionMode: isSelectionMode,
                            onRemove: { removeFromPattern(at: index) },
                            onDrop: { shape in
                                handleDropInSlot(shape: shape, at: index)
                            },
                            onTap: {
                                if isSelectionMode,
                                    let selectedShape = selectedShape
                                {
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
                            isSelectionMode: isSelectionMode,
                            onRemove: { removeFromPattern(at: index) },
                            onDrop: { shape in
                                handleDropInSlot(shape: shape, at: index)
                            },
                            onTap: {
                                if isSelectionMode,
                                    let selectedShape = selectedShape
                                {
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
                            isSelectionMode: isSelectionMode,
                            onDragStart: { draggedShape = shape },
                            onDragEnd: { draggedShape = nil },
                            onTap: {
                                if isSelectionMode {
                                    selectedShape =
                                        selectedShape?.id == shape.id
                                        ? nil : shape
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
                    savePattern()
                    currentView = .home
                }
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.green.opacity(0.7))
                .cornerRadius(10)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
        .background(Color.white)
        .onAppear {
            setupShapes()
            loadCurrentPattern()
        }
    }

    // MARK: - Helper Methods

    private func setupShapes() {
        availableShapes = [
            ShapeItem(id: 1, sides: 3, color: .red, name: "Triangle"),
            ShapeItem(id: 2, sides: 4, color: .blue, name: "Square"),
            ShapeItem(id: 3, sides: 5, color: .green, name: "Pentagon"),
            ShapeItem(id: 4, sides: 6, color: .orange, name: "Hexagon"),
            ShapeItem(id: 5, sides: 7, color: .purple, name: "Heptagon"),
            ShapeItem(id: 6, sides: 8, color: .pink, name: "Octagon"),
            ShapeItem(id: 7, sides: 9, color: .yellow, name: "Nonagon"),
            ShapeItem(id: 8, sides: 10, color: .cyan, name: "Decagon"),
        ]
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
                ShapeItem(id: -1, sides: 0, color: .clear, name: "Empty")
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
                            sides: 0,
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
    let isSelectionMode: Bool
    let onRemove: () -> Void
    let onDrop: (ShapeItem) -> Void
    let onTap: () -> Void

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(
                isHovered ? Color.blue : Color.black,
                lineWidth: isHovered ? 3 : 2
            )
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color.blue.opacity(0.1) : Color.white)
            )
            .overlay(
                Group {
                    if let shape = shape, shape.id != -1 {
                        ZStack {
                            PolygonShape(sides: shape.sides)
                                .fill(shape.color)
                                .frame(width: 60, height: 60)

                            Text("\(shape.id)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    } else {
                        // Empty slot indicator
                        Text("\(index + 1)")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .opacity(0.5)
                    }
                }
            )
            .onTapGesture {
                if isSelectionMode {
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
        let shapes = [
            ShapeItem(id: 1, sides: 3, color: .red, name: "Triangle"),
            ShapeItem(id: 2, sides: 4, color: .blue, name: "Square"),
            ShapeItem(id: 3, sides: 5, color: .green, name: "Pentagon"),
            ShapeItem(id: 4, sides: 6, color: .orange, name: "Hexagon"),
            ShapeItem(id: 5, sides: 7, color: .purple, name: "Heptagon"),
            ShapeItem(id: 6, sides: 8, color: .pink, name: "Octagon"),
            ShapeItem(id: 7, sides: 9, color: .yellow, name: "Nonagon"),
            ShapeItem(id: 8, sides: 10, color: .cyan, name: "Decagon"),
        ]
        return shapes.first { $0.id == id }
    }
}

struct DraggableShapeView: View {
    let shape: ShapeItem
    let isAlreadyInPattern: Bool
    let isSelected: Bool
    let isSelectionMode: Bool
    let onDragStart: () -> Void
    let onDragEnd: () -> Void
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 5) {
            PolygonShape(sides: shape.sides)
                .fill(shape.color)
                .frame(width: 60, height: 60)
        }
        .scaleEffect(0.9)
        .opacity(isAlreadyInPattern ? 0.5 : 1.0)
        .overlay(
            // Selection indicator
            isSelected
                ? RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue, lineWidth: 3)
                    .background(Color.blue.opacity(0.2))
                : // Visual indicator if already used
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
            PolygonShape(sides: shape.sides)
                .fill(shape.color)
                .frame(width: 60, height: 60)

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
    let sides: Int
    let color: Color
    let name: String
}

// MARK: - Custom Polygon Shape

struct PolygonShape: Shape {
    let sides: Int

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let radius = min(rect.width, rect.height) / 2

        var path = Path()

        for i in 0..<sides {
            let angle = (Double(i) * 2 * .pi / Double(sides)) - .pi / 2
            let point = CGPoint(
                x: center.x + radius * Darwin.cos(angle),
                y: center.y + radius * Darwin.sin(angle)
            )

            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        path.closeSubpath()
        return path
    }
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
                // This is a workaround - in a real app you'd want a better drag end detection
                onDragEnd()
            }
    }
}
