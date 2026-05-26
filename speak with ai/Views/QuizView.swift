//
//  QuizView.swift
//  speak with ai
//

import SwiftUI

struct QuizView: View {
    @EnvironmentObject var aiService: AIService
    @EnvironmentObject var progressManager: ProgressManager
    @Binding var language: Language
    @Binding var level: ProficiencyLevel
    
    @State private var questions: [QuizQuestion] = []
    @State private var currentIndex = 0
    @State private var selectedAnswer: Int?
    @State private var showExplanation = false
    @State private var score = 0
    @State private var quizCompleted = false
    @State private var isLoading = false
    @State private var selectedQuizType: QuizType = .translation
    @State private var errorMessage: String?
    @State private var quizStarted = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if !quizStarted {
                    quizSetupView
                } else if isLoading {
                    loadingView
                } else if quizCompleted {
                    quizResultsView
                } else if !questions.isEmpty {
                    quizQuestionView
                } else if let error = errorMessage {
                    errorView(error)
                }
            }
            .navigationTitle("Quiz")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Quiz Setup
    
    private var quizSetupView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 50))
                        .foregroundStyle(.blue)
                    
                    Text("Choose Quiz Type")
                        .font(.title2.bold())
                    
                    Text("Pick a challenge style")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)
                
                // Quiz Type Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(QuizType.allCases) { quizType in
                        QuizTypeCard(
                            quizType: quizType,
                            isSelected: selectedQuizType == quizType,
                            action: { selectedQuizType = quizType }
                        )
                    }
                }
                .padding(.horizontal)
                
                // Start Button
                Button(action: startQuiz) {
                    Label("Start Quiz", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(selectedQuizType.color)
                        )
                        .foregroundStyle(.white)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
    }
    
    // MARK: - Loading
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            Image(systemName: selectedQuizType.icon)
                .font(.system(size: 40))
                .foregroundStyle(selectedQuizType.color)
            
            SwiftUI.ProgressView()
                .scaleEffect(1.3)
            
            Text("Generating \(selectedQuizType.rawValue) quiz...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Question View
    
    private var quizQuestionView: some View {
        let question = questions[currentIndex]
        
        return VStack(spacing: 20) {
            // Progress header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: selectedQuizType.icon)
                        .foregroundStyle(selectedQuizType.color)
                    Text(selectedQuizType.rawValue)
                        .font(.caption.bold())
                        .foregroundStyle(selectedQuizType.color)
                }
                
                Spacer()
                
                Text("\(currentIndex + 1)/\(questions.count)")
                    .font(.subheadline.bold())
                
                Spacer()
                
                Text("Score: \(score)")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }
            .padding(.horizontal)
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(selectedQuizType.color)
                        .frame(width: geo.size.width * CGFloat(currentIndex + 1) / CGFloat(questions.count), height: 6)
                }
            }
            .frame(height: 6)
            .padding(.horizontal)
            
            // Question
            VStack(spacing: 12) {
                Image(systemName: selectedQuizType.icon)
                    .font(.title2)
                    .foregroundStyle(selectedQuizType.color)
                
                Text(question.question)
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            
            // Options
            VStack(spacing: 12) {
                ForEach(0..<question.options.count, id: \.self) { index in
                    Button(action: { selectAnswer(index) }) {
                        HStack {
                            Text(optionLetter(index))
                                .font(.headline)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(optionColor(index, correctAnswer: question.correctAnswer))
                                )
                                .foregroundStyle(.white)
                            
                            Text(question.options[index])
                                .font(.body)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                            
                            if showExplanation && index == question.correctAnswer {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else if showExplanation && index == selectedAnswer && index != question.correctAnswer {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(optionBackground(index, correctAnswer: question.correctAnswer))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(optionBorder(index, correctAnswer: question.correctAnswer), lineWidth: 2)
                                )
                        )
                    }
                    .disabled(showExplanation)
                }
            }
            .padding(.horizontal)
            
            // Explanation
            if showExplanation {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: selectedAnswer == question.correctAnswer ? "lightbulb.fill" : "info.circle.fill")
                            .foregroundStyle(selectedAnswer == question.correctAnswer ? .yellow : .blue)
                        Text(selectedAnswer == question.correctAnswer ? "Correct!" : "Not quite!")
                            .font(.headline)
                    }
                    
                    Text(question.explanation)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal)
                
                Button(action: nextQuestion) {
                    Text(currentIndex < questions.count - 1 ? "Next Question" : "See Results")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(selectedQuizType.color)
                        )
                        .foregroundStyle(.white)
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding(.top)
    }
    
    // MARK: - Results
    
    private var quizResultsView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: scoreIcon)
                .font(.system(size: 60))
                .foregroundStyle(scoreColor)
            
            Text(scoreMessage)
                .font(.title2.bold())
            
            Text("\(score) out of \(questions.count) correct")
                .font(.title3)
                .foregroundStyle(.secondary)
            
            Text("\(Int(Double(score) / Double(questions.count) * 100))%")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(scoreColor)
            
            VStack(spacing: 12) {
                Button(action: {
                    resetQuiz()
                    startQuiz()
                }) {
                    Label("Try Again", systemImage: "arrow.clockwise")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(selectedQuizType.color)
                        )
                        .foregroundStyle(.white)
                }
                
                Button(action: resetQuiz) {
                    Text("Choose Different Type")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    // MARK: - Error View
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text(error)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Try Again") { startQuiz() }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    // MARK: - Helpers
    
    private func optionLetter(_ index: Int) -> String {
        ["A", "B", "C", "D"][index]
    }
    
    private func optionColor(_ index: Int, correctAnswer: Int) -> Color {
        if !showExplanation {
            return selectedAnswer == index ? selectedQuizType.color : .gray
        }
        if index == correctAnswer { return .green }
        if index == selectedAnswer { return .red }
        return .gray
    }
    
    private func optionBackground(_ index: Int, correctAnswer: Int) -> Color {
        if !showExplanation { return Color(.systemBackground) }
        if index == correctAnswer { return .green.opacity(0.1) }
        if index == selectedAnswer && index != correctAnswer { return .red.opacity(0.1) }
        return Color(.systemBackground)
    }
    
    private func optionBorder(_ index: Int, correctAnswer: Int) -> Color {
        if !showExplanation {
            return selectedAnswer == index ? selectedQuizType.color : .clear
        }
        if index == correctAnswer { return .green }
        if index == selectedAnswer && index != correctAnswer { return .red }
        return .clear
    }
    
    private var scoreIcon: String {
        let percentage = Double(score) / Double(max(questions.count, 1))
        if percentage >= 0.8 { return "star.fill" }
        if percentage >= 0.6 { return "hand.thumbsup.fill" }
        return "arrow.up.heart.fill"
    }
    
    private var scoreColor: Color {
        let percentage = Double(score) / Double(max(questions.count, 1))
        if percentage >= 0.8 { return .yellow }
        if percentage >= 0.6 { return .green }
        return .orange
    }
    
    private var scoreMessage: String {
        let percentage = Double(score) / Double(max(questions.count, 1))
        if percentage >= 0.8 { return "Excellent! 🎉" }
        if percentage >= 0.6 { return "Good job! 👍" }
        return "Keep practicing! 💪"
    }
    
    // MARK: - Actions
    
    private func startQuiz() {
        guard aiService.hasAPIKey else {
            errorMessage = "Please add your API key in Settings."
            return
        }
        
        quizStarted = true
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let result = try await aiService.generateTypedQuiz(
                    language: language,
                    level: level,
                    quizType: selectedQuizType
                )
                await MainActor.run {
                    questions = result
                    isLoading = false
                    if result.isEmpty {
                        errorMessage = "Failed to generate questions. Please try again."
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func selectAnswer(_ index: Int) {
        selectedAnswer = index
        showExplanation = true
        
        if index == questions[currentIndex].correctAnswer {
            score += 1
        }
    }
    
    private func nextQuestion() {
        if currentIndex < questions.count - 1 {
            currentIndex += 1
            selectedAnswer = nil
            showExplanation = false
        } else {
            quizCompleted = true
            let scorePercentage = Double(score) / Double(questions.count) * 100
            progressManager.addQuizScore(for: language, score: scorePercentage)
            progressManager.addLessonCompleted(for: language)
        }
    }
    
    private func resetQuiz() {
        questions = []
        currentIndex = 0
        selectedAnswer = nil
        showExplanation = false
        score = 0
        quizCompleted = false
        quizStarted = false
        errorMessage = nil
    }
}

// MARK: - Quiz Type Card

struct QuizTypeCard: View {
    let quizType: QuizType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(quizType.color.opacity(isSelected ? 0.2 : 0.08))
                        .frame(height: 60)
                    
                    Image(systemName: quizType.icon)
                        .font(.system(size: 28))
                        .foregroundStyle(quizType.color)
                }
                
                Text(quizType.rawValue)
                    .font(.caption.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(quizType.description)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemBackground))
                    .shadow(color: isSelected ? quizType.color.opacity(0.3) : .black.opacity(0.05), radius: isSelected ? 6 : 3, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? quizType.color : .clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    QuizView(
        language: .constant(.spanish),
        level: .constant(.beginner)
    )
    .environmentObject(AIService())
    .environmentObject(ProgressManager())
}
