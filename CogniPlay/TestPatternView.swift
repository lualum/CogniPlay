//
//  TestPatternView.swift
//  CogniPlay
//
//  Created by Lucas Lum on 7/28/25.
//
/*
import SwiftUI
import Darwin

// MARK: - Test Pattern Game View
struct TestPatternView: View {
    @Binding var currentView: ContentView.AppView
    @Binding var currentPattern: [Int]

    @State private var availableShapes: [ShapeItem] = []
    @State private var userPattern: [ShapeItem] = []
    @State private var draggedShape: ShapeItem?
    @State private var hoveredSlot: Int?
    @State private var selectedShape: ShapeItem?
    @State private var isSelectionMode: Bool = false
    @State private var showResults = false
    @State private var testResults: TestResults?
    @State private var isTestCompleted = false

    var body: some View {
        VStack(spacing: 0) {
            // Header with title
            VStack(spacing: 20) {
                Text("Testing")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)

                if currentPattern.isEmpty {
                    Text("No pattern set!")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                } else {
                    Text("Recreate the Pattern")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                }

                // Mode toggle for simulator testing
                if !currentPattern.isEmpty && !isTestCompleted {
                    HStack {
                        Button(isSelectionMode ? "Switch to Drag Mode" : "Switch to Tap Mode") {
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

                    if isSelectionMode {
                        Text("Tap a shape, then tap a slot")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.top, 40)
            .padding(.bottom, 40)

            // Progress indicator
            if !currentPattern.isEmpty && !isTestCompleted {
                Text("Progress: \(userPattern.count)/\(currentPattern.count)")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.bottom, 20)
            }

            Spacer()

            // User's Pattern Area - Main drop zones
            VStack(spacing: 30) {
                // Top row - 3 slots
                HStack(spacing: 20) {
                    ForEach(0..<3) { index in
                        TestPatternSlot(
                            shape: index < userPattern.count ? userPattern[index] : nil,
                            index: index,
                            isCorrect: isTestCompleted ? (index < currentPattern.count && index < userPattern.count && userPattern[index].id == currentPattern[index]) : nil,
                            isHovered: hoveredSlot == index,
                            isSelectionMode: isSelectionMode,
                            onRemove: { removeFromUserPattern(at: index) },
                            onDrop: { shape in handleDropInSlot(shape: shape, at: index) },
                            onTap: {
                                if isSelectionMode, let selectedShape = selectedShape {
                                    handleDropInSlot(shape: selectedShape, at: index)
                                    self.selectedShape = nil
                                }
                            }
                        )
                    }
                }

                // Bottom row - 2 slots
                HStack(spacing: 20) {
                    ForEach(3..<5) { index in
                        TestPatternSlot(
                            shape: index < userPattern.count ? userPattern[index] : nil,
                            index: index,
                            isCorrect: isTestCompleted ? (index < currentPattern.count && index < userPattern.count && userPattern[index].id == currentPattern[index]) : nil,
                            isHovered: hoveredSlot == index,
                            isSelectionMode: isSelectionMode,
                            onRemove: { removeFromUserPattern(at: index) },
                            onDrop: { shape in handleDropInSlot(shape: shape, at: index) },
                            onTap: {
                                if isSelectionMode, let selectedShape = selectedShape {
                                    handleDropInSlot(shape: selectedShape, at: index)
                                    self.selectedShape = nil
                                }
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, 40)

            Spacer()

            // Results Section
            if showResults, let results = testResults {
                TestResultsView(results: results)
                    .transition(.opacity)
                    .padding(.bottom, 20)
            }

            // Available Shapes
            if !isTestCompleted {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Available Shapes:")
                        .font(.headline)
                        .padding(.horizontal, 40)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 15) {
                        ForEach(availableShapes, id: \.id) { shape in
                            TestDraggableShapeView(
                                shape: shape,
                                isAlreadyInPattern: userPattern.contains(where: { $0.id == shape.id }),
                                isSelected: selectedShape?.id == shape.id,
                                isSelectionMode: isSelectionMode,
                                onDragStart: { draggedShape = shape },
                                onDragEnd: { draggedShape = nil },
                                onTap: {
                                    if isSelectionMode {
                                        selectedShape = selectedShape?.id == shape.id ? nil : shape
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 40)
                }
                .padding(.bottom, 20)
            }

            // Action Button
            if !isTestCompleted {
                HStack(spacing: 20) {
                    Button("Clear All") {
                        clearUserPattern()
                    }
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.red.opacity(0.7))
                    .cornerRadius(10)

                    Button("Submit") {
                        submitTest()
                    }
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(userPattern.count == currentPattern.count ? Color.blue : Color.gray)
                    .cornerRadius(10)
                    .disabled(userPattern.count != currentPattern.count)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            } else {
                VStack(spacing: 15) {
                    Button("Test Again") {
                        resetTest()
                    }
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal, 40)

                    Button("Back to Home") {
                        currentView = .home
                    }
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.green.opacity(0.7))
                    .cornerRadius(10)
                    .padding(.horizontal, 40)
                }
                .padding(.bottom, 50)
            }
        }
        .background(Color.white)
        .onAppear {
            setupShapes()
            resetTest()
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
            ShapeItem(id: 8, sides: 10, color: .cyan, name: "Decagon")
        ]
    }

    private func resetTest() {
        userPattern.removeAll()
        showResults = false
        testResults = nil
        isTestCompleted = false
        selectedShape = nil
        hoveredSlot = nil
    }

    private func clearUserPattern() {
        userPattern.removeAll()
        selectedShape = nil
    }

    private func removeFromUserPattern(at index: Int) {
        if !isTestCompleted && index < userPattern.count {
            userPattern.remove(at: index)
        }
    }

    private func handleDropInSlot(shape: ShapeItem, at index: Int) {
        guard !isTestCompleted else { return }

        // Don't allow duplicate shapes in the pattern
        if userPattern.contains(where: { $0.id == shape.id }) {
            return
        }

        // Ensure the userPattern array is large enough
        while userPattern.count <= index {
            userPattern.append(ShapeItem(id: -1, sides: 0, color: .clear, name: "Empty"))
        }

        // If there's already a shape at this position and it's not empty, shift it
        if index < userPattern.count && userPattern[index].id != -1 {
            // Find the next empty slot or append at the end
            var nextEmptyIndex = -1
            for i in 0..<min(currentPattern.count, 5) {
                if i >= userPattern.count || userPattern[i].id == -1 {
                    nextEmptyIndex = i
                    break
                }
            }

            if nextEmptyIndex != -1 && nextEmptyIndex < min(currentPattern.count, 5) {
                while userPattern.count <= nextEmptyIndex {
                    userPattern.append(ShapeItem(id: -1, sides: 0, color: .clear, name: "Empty"))
                }
                userPattern[nextEmptyIndex] = userPattern[index]
            }
        }

        // Place the new shape
        userPattern[index] = shape

        // Remove empty placeholders at the end
        while userPattern.last?.id == -1 {
            userPattern.removeLast()
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard !isTestCompleted else { return false }
        guard let provider = providers.first else { return false }

        provider.loadObject(ofClass: NSString.self) { (object, error) in
            if let idString = object as? String,
               let id = Int(idString),
               let shape = availableShapes.first(where: { $0.id == id }) {
                DispatchQueue.main.async {
                    if userPattern.count < min(currentPattern.count, 5) && !userPattern.contains(where: { $0.id == id }) {
                        userPattern.append(shape)
                    }
                }
            }
        }
        return true
    }

    private func submitTest() {
        guard userPattern.count == currentPattern.count else { return }

        let results = gradeTest()
        testResults = results
        isTestCompleted = true

        withAnimation(.easeInOut(duration: 0.5)) {
            showResults = true
        }
    }

    // MARK: - Hamming Distance Grading Scheme

    private func gradeTest() -> TestResults {
        let targetPattern = currentPattern.compactMap { id in
            availableShapes.first { $0.id == id }
        }

        // Calculate Hamming distance (number of positions where shapes differ)
        var hammingDistance = 0
        var positionErrors: [Int] = []
        var shapeErrors: [Int] = []

        // Compare each position (guaranteed same length)
        for i in 0..<currentPattern.count {
            if userPattern[i].id != targetPattern[i].id {
                hammingDistance += 1
                positionErrors.append(i)

                // If user shape doesn't exist in target at all, it's also a shape error
                if !targetPattern.contains(where: { $0.id == userPattern[i].id }) {
                    shapeErrors.append(i)
                }
            }
        }

        // Calculate accuracy as percentage
        let accuracy = Double(currentPattern.count - hammingDistance) / Double(currentPattern.count)

        // Count correct positions and shapes for display
        let correctPositions = currentPattern.count - hammingDistance
        var correctShapes = 0
        for userShape in userPattern {
            if targetPattern.contains(where: { $0.id == userShape.id }) {
                correctShapes += 1
            }
        }

        return TestResults(
            totalShapes: currentPattern.count,
            correctPositions: correctPositions,
            correctShapes: correctShapes,
            positionAccuracy: accuracy,
            shapeAccuracy: Double(correctShapes) / Double(currentPattern.count),
            overallScore: accuracy, // Use Hamming-based accuracy as overall score
            positionErrors: positionErrors,
            shapeErrors: shapeErrors,
            userPattern: userPattern.map { $0.id },
            targetPattern: currentPattern
        )
    }
}

// MARK: - Supporting Views

struct TestPatternSlot: View {
    let shape: ShapeItem?
    let index: Int
    let isCorrect: Bool?
    let isHovered: Bool
    let isSelectionMode: Bool
    let onRemove: () -> Void
    let onDrop: (ShapeItem) -> Void
    let onTap: () -> Void

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(borderColor, lineWidth: borderWidth)
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
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

    private var borderColor: Color {
        if let isCorrect = isCorrect {
            return isCorrect ? .green : .red
        }
        return isHovered ? .blue : .black
    }

    private var borderWidth: CGFloat {
        if isCorrect != nil {
            return 3
        }
        return isHovered ? 3 : 2
    }

    private var backgroundColor: Color {
        if let isCorrect = isCorrect {
            return isCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.1)
        }
        return isHovered ? Color.blue.opacity(0.1) : Color.white
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadObject(ofClass: NSString.self) { (object, error) in
            if let idString = object as? String,
               let id = Int(idString),
               let shape = getShapeById(id) {
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
            ShapeItem(id: 8, sides: 10, color: .cyan, name: "Decagon")
        ]
        return shapes.first { $0.id == id }
    }
}

struct TestDraggableShapeView: View {
    let shape: ShapeItem
    let isAlreadyInPattern: Bool
    let isSelected: Bool
    let isSelectionMode: Bool
    let onDragStart: () -> Void
    let onDragEnd: () -> Void
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                PolygonShape(sides: shape.sides)
                    .fill(shape.color)
                    .frame(width: 60, height: 60)

                Text("\(shape.id)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            Text(shape.name)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .scaleEffect(0.9)
        .opacity(isAlreadyInPattern ? 0.5 : 1.0)
        .overlay(
            // Selection indicator
            isSelected ?
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.blue, lineWidth: 3)
                .background(Color.blue.opacity(0.2))
            :
            // Visual indicator if already used
            isAlreadyInPattern ?
            RoundedRectangle(cornerRadius: 8)
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

struct TestResultsView: View {
    let results: TestResults

    var body: some View {
        VStack(spacing: 15) {
            Text("Test Results")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 10) {
                HStack {
                    Text("Overall Score:")
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(Int(results.overallScore * 100))%")
                        .fontWeight(.bold)
                        .foregroundColor(scoreColor(results.overallScore))
                }

                HStack {
                    Text("Position Accuracy:")
                    Spacer()
                    Text("\(results.correctPositions)/\(results.totalShapes)")
                        .foregroundColor(.blue)
                }

                HStack {
                    Text("Shape Recognition:")
                    Spacer()
                    Text("\(results.correctShapes)/\(results.totalShapes)")
                        .foregroundColor(.green)
                }
            }

            // Performance indicator
            Text(performanceText(results.overallScore))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(scoreColor(results.overallScore))
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal, 40)
    }

    private func scoreColor(_ score: Double) -> Color {
        if score >= 0.9 { return .green }
        else if score >= 0.7 { return .blue }
        else if score >= 0.5 { return .orange }
        else { return .red }
    }

    private func performanceText(_ score: Double) -> String {
        if score >= 0.9 { return "Excellent!" }
        else if score >= 0.7 { return "Good Job!" }
        else if score >= 0.5 { return "Keep Practicing!" }
        else { return "Try Again!" }
    }
}

// MARK: - Data Models

struct TestResults {
    let totalShapes: Int
    let correctPositions: Int
    let correctShapes: Int
    let positionAccuracy: Double
    let shapeAccuracy: Double
    let overallScore: Double
    let positionErrors: [Int]
    let shapeErrors: [Int]
    let userPattern: [Int]
    let targetPattern: [Int]
}
*/
