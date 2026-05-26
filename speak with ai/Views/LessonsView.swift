//
//  LessonsView.swift
//  speak with ai
//

import SwiftUI

struct LessonsView: View {
    @EnvironmentObject var aiService: AIService
    @EnvironmentObject var speechService: SpeechService
    @EnvironmentObject var progressManager: ProgressManager
    @Binding var language: Language
    @Binding var level: ProficiencyLevel
    
    @State private var selectedCategory: LessonCategory = .vocabulary
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category Picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(LessonCategory.allCases) { category in
                            CategoryChip(
                                category: category,
                                isSelected: selectedCategory == category,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                
                Divider()
                
                // Content based on category
                ScrollView {
                    switch selectedCategory {
                    case .vocabulary:
                        VocabularyLessonView(language: $language, level: $level)
                    case .grammar:
                        GrammarLessonView(language: $language, level: $level)
                    case .conversation:
                        ConversationTipsView(language: $language, level: $level)
                    case .pronunciation:
                        PronunciationView(language: $language, level: $level)
                    case .reading:
                        ReadingPracticeView(language: $language, level: $level)
                    case .writing:
                        WritingPracticeView(language: $language, level: $level)
                    case .culture:
                        CultureLessonView(language: $language, level: $level)
                    }
                }
            }
            .navigationTitle("Lessons")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let category: LessonCategory
    let isSelected: Bool
    let action: () -> Void
    
    var chipColor: Color {
        switch category.color {
        case "blue": return .blue
        case "purple": return .purple
        case "green": return .green
        case "orange": return .orange
        case "indigo": return .indigo
        case "pink": return .pink
        case "teal": return .teal
        default: return .blue
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.caption)
                Text(category.rawValue)
                    .font(.caption.bold())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? chipColor : chipColor.opacity(0.1))
            )
            .foregroundStyle(isSelected ? .white : chipColor)
        }
    }
}

// MARK: - Vocabulary Lesson

struct VocabularyLessonView: View {
    @EnvironmentObject var aiService: AIService
    @EnvironmentObject var speechService: SpeechService
    @EnvironmentObject var progressManager: ProgressManager
    @Binding var language: Language
    @Binding var level: ProficiencyLevel
    
    @State private var words: [VocabularyWord] = []
    @State private var isLoading = false
    @State private var selectedCategory = "Common Phrases"
    @State private var errorMessage: String?
    
    private let categories = [
        "Common Phrases", "Numbers & Counting", "Food & Drinks",
        "Family", "Colors", "Animals", "Body Parts",
        "Clothing", "Weather", "Emotions", "Travel",
        "Time & Days", "Professions", "Nature"
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            // Category selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories, id: \.self) { cat in
                        Button(action: {
                            selectedCategory = cat
                            loadVocabulary()
                        }) {
                            Text(cat)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(selectedCategory == cat ? Color.blue : Color.blue.opacity(0.1))
                                )
                                .foregroundStyle(selectedCategory == cat ? .white : .blue)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            if isLoading {
                VStack(spacing: 12) {
                    SwiftUI.ProgressView()
                    Text("Generating vocabulary...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 60)
            } else if let error = errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Try Again") { loadVocabulary() }
                        .buttonStyle(.borderedProminent)
                }
                .padding()
            } else if words.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "character.book.closed")
                        .font(.system(size: 50))
                        .foregroundStyle(.blue.opacity(0.5))
                    Text("Tap a category to generate vocabulary")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Generate Words") { loadVocabulary() }
                        .buttonStyle(.borderedProminent)
                }
                .padding(.top, 60)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(words) { word in
                        VocabularyCard(word: word, language: language)
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding(.top)
    }
    
    private func loadVocabulary() {
        guard aiService.hasAPIKey else {
            errorMessage = "Please add your API key in Settings."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let result = try await aiService.generateVocabulary(
                    language: language,
                    level: level,
                    category: selectedCategory
                )
                await MainActor.run {
                    words = result
                    isLoading = false
                    if !result.isEmpty {
                        progressManager.addWordsLearned(for: language, count: result.count)
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
}

// MARK: - Vocabulary Card

struct VocabularyCard: View {
    let word: VocabularyWord
    let language: Language
    @EnvironmentObject var speechService: SpeechService
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(word.word)
                        .font(.headline)
                    Text(word.translation)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    speechService.speak(text: word.word, language: language)
                }) {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundStyle(.blue)
                        .padding(8)
                        .background(Circle().fill(.blue.opacity(0.1)))
                }
                
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                }
            }
            
            if isExpanded {
                Divider()
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "waveform")
                            .foregroundStyle(.orange)
                        Text(word.pronunciation)
                            .font(.caption)
                            .italic()
                    }
                    
                    HStack(alignment: .top) {
                        Image(systemName: "text.quote")
                            .foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(word.exampleSentence)
                                .font(.subheadline)
                            Text(word.exampleTranslation)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Button(action: {
                        speechService.speak(text: word.exampleSentence, language: language)
                    }) {
                        Label("Listen to example", systemImage: "play.circle")
                            .font(.caption)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
    }
}

// MARK: - Grammar Lesson

struct GrammarLessonView: View {
    @EnvironmentObject var aiService: AIService
    @Binding var language: Language
    @Binding var level: ProficiencyLevel
    
    @State private var grammarRule: GrammarRule?
    @State private var isLoading = false
    @State private var selectedTopic = ""
    @State private var errorMessage: String?
    
    private var grammarTopics: [String] {
        switch level {
        case .beginner:
            return ["Basic sentence structure", "Present tense", "Articles", "Pronouns", "Basic adjectives", "Plurals", "Negation"]
        case .elementary:
            return ["Past tense", "Future tense", "Prepositions", "Possessives", "Comparatives", "Question formation"]
        case .intermediate:
            return ["Subjunctive mood", "Conditional tense", "Relative clauses", "Passive voice", "Reported speech"]
        case .upperIntermediate:
            return ["Complex conditionals", "Advanced subjunctive", "Idiomatic expressions", "Formal vs informal register"]
        case .advanced:
            return ["Literary tenses", "Rhetorical devices", "Regional variations", "Nuanced conjunctions", "Advanced syntax"]
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Topic selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(grammarTopics, id: \.self) { topic in
                        Button(action: {
                            selectedTopic = topic
                            loadGrammar(topic: topic)
                        }) {
                            Text(topic)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(selectedTopic == topic ? Color.purple : Color.purple.opacity(0.1))
                                )
                                .foregroundStyle(selectedTopic == topic ? .white : .purple)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            if isLoading {
                VStack(spacing: 12) {
                    SwiftUI.ProgressView()
                    Text("Preparing grammar lesson...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 60)
            } else if let rule = grammarRule {
                VStack(alignment: .leading, spacing: 16) {
                    Text(rule.title)
                        .font(.title2.bold())
                    
                    Text(rule.explanation)
                        .font(.body)
                        .foregroundStyle(.secondary)
                    
                    if !rule.examples.isEmpty {
                        Text("Examples")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        ForEach(rule.examples) { example in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(example.sentence)
                                    .font(.body.bold())
                                Text(example.translation)
                                    .font(.subheadline)
                                    .foregroundStyle(.blue)
                                Text(example.breakdown)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.purple.opacity(0.05))
                            )
                        }
                    }
                }
                .padding(.horizontal)
            } else if let error = errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "text.book.closed")
                        .font(.system(size: 50))
                        .foregroundStyle(.purple.opacity(0.5))
                    Text("Select a grammar topic to start learning")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 60)
            }
            
            Spacer()
        }
        .padding(.top)
    }
    
    private func loadGrammar(topic: String) {
        guard aiService.hasAPIKey else {
            errorMessage = "Please add your API key in Settings."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let result = try await aiService.generateGrammarLesson(
                    language: language,
                    level: level,
                    topic: topic
                )
                await MainActor.run {
                    grammarRule = result
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Pronunciation View

struct PronunciationView: View {
    @EnvironmentObject var aiService: AIService
    @EnvironmentObject var speechService: SpeechService
    @Binding var language: Language
    @Binding var level: ProficiencyLevel
    
    @State private var inputText = ""
    @State private var pronunciationGuide: String?
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Enter a word or phrase to get pronunciation help:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack {
                    TextField("Type a word or phrase...", text: $inputText)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Guide") {
                        getPronunciation()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(inputText.isEmpty || isLoading)
                }
                
                HStack(spacing: 12) {
                    Button(action: {
                        speechService.speak(text: inputText, language: language)
                    }) {
                        Label("Normal", systemImage: "play.fill")
                            .font(.caption)
                    }
                    .disabled(inputText.isEmpty)
                    
                    Button(action: {
                        speechService.speakSlowly(text: inputText, language: language)
                    }) {
                        Label("Slow", systemImage: "tortoise.fill")
                            .font(.caption)
                    }
                    .disabled(inputText.isEmpty)
                }
                .padding(.top, 4)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            )
            
            if isLoading {
                SwiftUI.ProgressView("Analyzing pronunciation...")
            } else if let guide = pronunciationGuide {
                ScrollView {
                    Text(guide)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange.opacity(0.05))
                        )
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func getPronunciation() {
        guard aiService.hasAPIKey else { return }
        isLoading = true
        
        Task {
            do {
                let guide = try await aiService.getPronunciationGuide(
                    language: language,
                    text: inputText
                )
                await MainActor.run {
                    pronunciationGuide = guide
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    pronunciationGuide = "Error: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Placeholder Views for other categories

struct ConversationTipsView: View {
    @EnvironmentObject var aiService: AIService
    @Binding var language: Language
    @Binding var level: ProficiencyLevel
    @State private var tips: String?
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 16) {
            if isLoading {
                SwiftUI.ProgressView("Loading conversation tips...")
                    .padding(.top, 60)
            } else if let tips = tips {
                Text(tips)
                    .font(.body)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 50))
                        .foregroundStyle(.green.opacity(0.5))
                    Text("Get conversation tips and common phrases")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Load Tips") { loadTips() }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                }
                .padding(.top, 60)
            }
            Spacer()
        }
    }
    
    private func loadTips() {
        guard aiService.hasAPIKey else { return }
        isLoading = true
        Task {
            do {
                let response = try await aiService.getConversationResponse(
                    language: language,
                    level: level,
                    messages: [ChatMessage(content: "Give me useful conversation starters and common phrases for everyday situations. Format with emojis and categories.", isUser: true)],
                    topic: "Conversation Tips"
                )
                await MainActor.run {
                    tips = response
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    tips = "Error loading tips: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

struct ReadingPracticeView: View {
    @EnvironmentObject var aiService: AIService
    @Binding var language: Language
    @Binding var level: ProficiencyLevel
    @State private var readingText: String?
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 16) {
            if isLoading {
                SwiftUI.ProgressView("Generating reading material...")
                    .padding(.top, 60)
            } else if let text = readingText {
                Text(text)
                    .font(.body)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "book")
                        .font(.system(size: 50))
                        .foregroundStyle(.indigo.opacity(0.5))
                    Text("Get a reading passage with comprehension questions")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Generate Reading") { loadReading() }
                        .buttonStyle(.borderedProminent)
                        .tint(.indigo)
                }
                .padding(.top, 60)
            }
            Spacer()
        }
    }
    
    private func loadReading() {
        guard aiService.hasAPIKey else { return }
        isLoading = true
        Task {
            do {
                let response = try await aiService.getConversationResponse(
                    language: language,
                    level: level,
                    messages: [ChatMessage(content: "Create a short reading passage in \(language.rawValue) appropriate for my level, followed by its English translation and 3 comprehension questions.", isUser: true)],
                    topic: "Reading Practice"
                )
                await MainActor.run {
                    readingText = response
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    readingText = "Error: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

struct WritingPracticeView: View {
    @EnvironmentObject var aiService: AIService
    @Binding var language: Language
    @Binding var level: ProficiencyLevel
    @State private var userWriting = ""
    @State private var feedback: String?
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Write something in \(language.rawValue) and get feedback:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                TextEditor(text: $userWriting)
                    .frame(minHeight: 100, maxHeight: 150)
                    .padding(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                
                Button("Check My Writing") { checkWriting() }
                    .buttonStyle(.borderedProminent)
                    .tint(.pink)
                    .disabled(userWriting.isEmpty || isLoading)
            }
            .padding()
            
            if isLoading {
                SwiftUI.ProgressView("Analyzing your writing...")
            } else if let feedback = feedback {
                Text(feedback)
                    .font(.body)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.pink.opacity(0.05))
                    )
                    .padding(.horizontal)
            }
            
            Spacer()
        }
    }
    
    private func checkWriting() {
        guard aiService.hasAPIKey else { return }
        isLoading = true
        Task {
            do {
                let response = try await aiService.correctSentence(
                    language: language,
                    sentence: userWriting
                )
                await MainActor.run {
                    feedback = response
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    feedback = "Error: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

struct CultureLessonView: View {
    @EnvironmentObject var aiService: AIService
    @Binding var language: Language
    @Binding var level: ProficiencyLevel
    @State private var cultureInfo: String?
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 16) {
            if isLoading {
                SwiftUI.ProgressView("Loading cultural insights...")
                    .padding(.top, 60)
            } else if let info = cultureInfo {
                Text(info)
                    .font(.body)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "globe")
                        .font(.system(size: 50))
                        .foregroundStyle(.teal.opacity(0.5))
                    Text("Learn about culture, customs, and etiquette")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Explore Culture") { loadCulture() }
                        .buttonStyle(.borderedProminent)
                        .tint(.teal)
                }
                .padding(.top, 60)
            }
            Spacer()
        }
    }
    
    private func loadCulture() {
        guard aiService.hasAPIKey else { return }
        isLoading = true
        Task {
            do {
                let response = try await aiService.getConversationResponse(
                    language: language,
                    level: level,
                    messages: [ChatMessage(content: "Tell me interesting cultural facts, customs, etiquette tips, and social norms for \(language.rawValue)-speaking countries. Include useful cultural phrases. Format with emojis.", isUser: true)],
                    topic: "Culture"
                )
                await MainActor.run {
                    cultureInfo = response
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    cultureInfo = "Error: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    LessonsView(
        language: .constant(.spanish),
        level: .constant(.beginner)
    )
    .environmentObject(AIService())
    .environmentObject(SpeechService())
    .environmentObject(ProgressManager())
}
