//
//  QuizGeneratorView.swift
//  StudyBuddy
//
//  Created by Arihant Marwaha on 12/07/25.
//

import SwiftUI
struct QuizGeneratorView: View {
    @EnvironmentObject var notesManager: NotesManager
    @EnvironmentObject var aiService: AIService
    @Environment(\.dismiss) private var dismiss
    
    private var note: Note {
        notesManager.selectedNote ?? Note()
    }
    
    @State private var quiz: Quiz?
    @State private var questionCount = 5
    @State private var selectedQuestionTypes: Set<QuizQuestion.QuestionType> = [.multipleChoice, .trueFalse]
    @State private var difficulty = Difficulty.medium
    @State private var isGenerating = false
    @State private var showingQuizPreview = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                QuizGeneratorHeader()
                
                // Settings Section
                ScrollView {
                    VStack(spacing: 24) {
                        // Question Count
                        QuestionCountSection(questionCount: $questionCount)
                        
                        // Question Types
                        QuestionTypesSection(selectedTypes: $selectedQuestionTypes)
                        
                        // Difficulty Level
                        DifficultySection(difficulty: $difficulty)
                        
                        // Source Preview
                        SourcePreviewSection(note: note)
                    }
                    .padding()
                }
                
                // Generate Button
                VStack {
                    if isGenerating {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Generating quiz with AI...")
                                .font(.callout)
                        }
                        .padding()
                    } else {
                        Button(action: generateQuiz) {
                            Label("Generate Quiz", systemImage: "brain")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(selectedQuestionTypes.isEmpty)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
            }
            .frame(width: 600, height: 700)
            .navigationTitle("Quiz Generator")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingQuizPreview) {
            if let quiz = quiz {
                QuizPreviewView(quiz: quiz) {
                    saveQuiz()
                }
            }
        }
    }
    
    // MARK: - Actions
    private func generateQuiz() {
        isGenerating = true
        
        Task {
            // Generate quiz using AI
            let generatedQuiz = await aiService.generateQuiz(
                from: note,
                questionCount: questionCount
            )
            
            // Filter by selected question types
            var filteredQuestions = generatedQuiz.questions.filter { question in
                selectedQuestionTypes.contains(question.type)
            }
            
            // Ensure we have the requested number of questions
            if filteredQuestions.count > questionCount {
                filteredQuestions = Array(filteredQuestions.prefix(questionCount))
            }
            
            quiz = Quiz(
                title: generatedQuiz.title,
                questions: filteredQuestions,
                sourceNoteId: note.id
            )
            
            isGenerating = false
            showingQuizPreview = true
        }
    }
    
    private func saveQuiz() {
        guard let quiz = quiz else { return }
        
        // Save quiz to note
        var updatedNote = note
        // In a real app, you'd add a quizzes array to the Note model
        // For now, we'll add it to the content
        updatedNote.content += "\n\n## Generated Quiz: \(quiz.title)\n"
        updatedNote.content += "Questions: \(quiz.questions.count)\n"
        updatedNote.content += "Created: \(quiz.createdAt.formatted())\n"
        
        notesManager.updateNote(updatedNote)
        dismiss()
    }
}

// MARK: - Quiz Generator Header
struct QuizGeneratorHeader: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain")
                .font(.system(size: 50))
                .foregroundColor(.purple)
                .symbolRenderingMode(.multicolor)
                .symbolEffect(.pulse)
            
            Text("AI Quiz Generator")
                .font(.title2.bold())
            
            Text("Create a custom quiz from your notes")
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.1), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - Question Count Section
struct QuestionCountSection: View {
    @Binding var questionCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Number of Questions", systemImage: "number.circle")
                .font(.headline)
            
            HStack {
                Stepper(value: $questionCount, in: 1...20) {
                    HStack {
                        Text("\(questionCount)")
                            .font(.title3.monospacedDigit())
                            .frame(minWidth: 30)
                        Text(questionCount == 1 ? "question" : "questions")
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Quick select buttons
                ForEach([5, 10, 15, 20], id: \.self) { count in
                    Button("\(count)") {
                        withAnimation {
                            questionCount = count
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Question Types Section
struct QuestionTypesSection: View {
    @Binding var selectedTypes: Set<QuizQuestion.QuestionType>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Question Types", systemImage: "list.bullet.rectangle")
                .font(.headline)
            
            VStack(spacing: 8) {
                ForEach(QuizQuestion.QuestionType.allCases, id: \.self) { type in
                    QuestionTypeRow(
                        type: type,
                        isSelected: selectedTypes.contains(type),
                        onToggle: {
                            if selectedTypes.contains(type) {
                                selectedTypes.remove(type)
                            } else {
                                selectedTypes.insert(type)
                            }
                        }
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Question Type Row
struct QuestionTypeRow: View {
    let type: QuizQuestion.QuestionType
    let isSelected: Bool
    let onToggle: () -> Void
    
    var iconName: String {
        switch type {
        case .multipleChoice: return "list.bullet.circle"
        case .trueFalse: return "checkmark.circle"
        case .shortAnswer: return "text.alignleft"
        case .fillInBlank: return "text.badge.minus"
        }
    }
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                
                Image(systemName: iconName)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                Text(type.rawValue)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Difficulty Section
struct DifficultySection: View {
    @Binding var difficulty: Difficulty
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Difficulty Level", systemImage: "speedometer")
                .font(.headline)
            
            Picker("Difficulty", selection: $difficulty) {
                ForEach(Difficulty.allCases, id: \.self) { level in
                    Label(level.rawValue, systemImage: level.icon)
                        .tag(level)
                }
            }
            .pickerStyle(.segmented)
            
            Text(difficulty.description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Source Preview Section
struct SourcePreviewSection: View {
    let note: Note
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Source Note", systemImage: "doc.text")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(note.title)
                    .font(.subheadline.bold())
                
                if isExpanded {
                    Text(note.content)
                        .font(.caption)
                        .lineLimit(10)
                        .foregroundColor(.secondary)
                } else {
                    Text(note.content)
                        .font(.caption)
                        .lineLimit(3)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Label("\(note.content.split(separator: " ").count) words", systemImage: "text.word.spacing")
                    
                    if !note.aiKeyPoints.isEmpty {
                        Label("\(note.aiKeyPoints.count) key points", systemImage: "brain")
                    }
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Quiz Preview View
struct QuizPreviewView: View {
    let quiz: Quiz
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswers: [UUID: String] = [:]
    @State private var showingResults = false
    
    var body: some View {
        NavigationStack {
            VStack {
                // Progress Bar
                ProgressView(value: Double(currentQuestionIndex + 1), total: Double(quiz.questions.count))
                    .padding()
                
                // Question Display
                if currentQuestionIndex < quiz.questions.count {
                    QuestionView(
                        question: quiz.questions[currentQuestionIndex],
                        selectedAnswer: selectedAnswers[quiz.questions[currentQuestionIndex].id],
                        onAnswerSelected: { answer in
                            selectedAnswers[quiz.questions[currentQuestionIndex].id] = answer
                        }
                    )
                    .padding()
                }
                
                Spacer()
                
                // Navigation
                HStack {
                    Button("Previous") {
                        withAnimation {
                            currentQuestionIndex = max(0, currentQuestionIndex - 1)
                        }
                    }
                    .disabled(currentQuestionIndex == 0)
                    
                    Spacer()
                    
                    Text("Question \(currentQuestionIndex + 1) of \(quiz.questions.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(currentQuestionIndex == quiz.questions.count - 1 ? "Finish" : "Next") {
                        withAnimation {
                            if currentQuestionIndex < quiz.questions.count - 1 {
                                currentQuestionIndex += 1
                            } else {
                                showingResults = true
                            }
                        }
                    }
                }
                .padding()
            }
            .frame(width: 600, height: 500)
            .navigationTitle(quiz.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save Quiz") {
                        onSave()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}

// MARK: - Question View
struct QuestionView: View {
    let question: QuizQuestion
    let selectedAnswer: String?
    let onAnswerSelected: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(question.question)
                .font(.title3)
                .fontWeight(.semibold)
            
            switch question.type {
            case .multipleChoice:
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(question.options, id: \.self) { option in
                        AnswerButton(
                            text: option,
                            isSelected: selectedAnswer == option,
                            onSelect: { onAnswerSelected(option) }
                        )
                    }
                }
                
            case .trueFalse:
                HStack(spacing: 20) {
                    AnswerButton(
                        text: "True",
                        isSelected: selectedAnswer == "True",
                        onSelect: { onAnswerSelected("True") }
                    )
                    AnswerButton(
                        text: "False",
                        isSelected: selectedAnswer == "False",
                        onSelect: { onAnswerSelected("False") }
                    )
                }
                
            case .shortAnswer, .fillInBlank:
                TextField("Your answer", text: .constant(selectedAnswer ?? ""))
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: selectedAnswer ?? "") { newValue in
                        onAnswerSelected(newValue)
                    }
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Answer Button
struct AnswerButton: View {
    let text: String
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                
                Text(text)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Supporting Types
enum Difficulty: String, CaseIterable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    
    var icon: String {
        switch self {
        case .easy: return "1.circle"
        case .medium: return "2.circle"
        case .hard: return "3.circle"
        }
    }
    
    var description: String {
        switch self {
        case .easy: return "Basic recall and understanding"
        case .medium: return "Application and analysis"
        case .hard: return "Synthesis and evaluation"
        }
    }
}

