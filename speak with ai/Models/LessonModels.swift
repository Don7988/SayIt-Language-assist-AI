//
//  LessonModels.swift
//  speak with ai
//

import Foundation

enum ProficiencyLevel: String, CaseIterable, Identifiable, Codable {
    case beginner = "Beginner"
    case elementary = "Elementary"
    case intermediate = "Intermediate"
    case upperIntermediate = "Upper Intermediate"
    case advanced = "Advanced"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .beginner: return "leaf"
        case .elementary: return "leaf.fill"
        case .intermediate: return "flame"
        case .upperIntermediate: return "flame.fill"
        case .advanced: return "star.fill"
        }
    }
}

enum LessonCategory: String, CaseIterable, Identifiable, Codable {
    case vocabulary = "Vocabulary"
    case grammar = "Grammar"
    case conversation = "Conversation"
    case pronunciation = "Pronunciation"
    case reading = "Reading"
    case writing = "Writing"
    case culture = "Culture"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .vocabulary: return "character.book.closed"
        case .grammar: return "text.book.closed"
        case .conversation: return "bubble.left.and.bubble.right"
        case .pronunciation: return "waveform"
        case .reading: return "book"
        case .writing: return "pencil.and.outline"
        case .culture: return "globe"
        }
    }
    
    var color: String {
        switch self {
        case .vocabulary: return "blue"
        case .grammar: return "purple"
        case .conversation: return "green"
        case .pronunciation: return "orange"
        case .reading: return "indigo"
        case .writing: return "pink"
        case .culture: return "teal"
        }
    }
}

struct VocabularyWord: Identifiable, Codable {
    let id: UUID
    let word: String
    let translation: String
    let pronunciation: String
    let exampleSentence: String
    let exampleTranslation: String
    var mastered: Bool
    
    init(id: UUID = UUID(), word: String, translation: String, pronunciation: String, exampleSentence: String, exampleTranslation: String, mastered: Bool = false) {
        self.id = id
        self.word = word
        self.translation = translation
        self.pronunciation = pronunciation
        self.exampleSentence = exampleSentence
        self.exampleTranslation = exampleTranslation
        self.mastered = mastered
    }
}

struct GrammarRule: Identifiable, Codable {
    let id: UUID
    let title: String
    let explanation: String
    let examples: [GrammarExample]
    
    init(id: UUID = UUID(), title: String, explanation: String, examples: [GrammarExample]) {
        self.id = id
        self.title = title
        self.explanation = explanation
        self.examples = examples
    }
}

struct GrammarExample: Identifiable, Codable {
    let id: UUID
    let sentence: String
    let translation: String
    let breakdown: String
    
    init(id: UUID = UUID(), sentence: String, translation: String, breakdown: String) {
        self.id = id
        self.sentence = sentence
        self.translation = translation
        self.breakdown = breakdown
    }
}

struct QuizQuestion: Identifiable {
    let id = UUID()
    let question: String
    let options: [String]
    let correctAnswer: Int
    let explanation: String
}

struct UserProgress: Codable {
    var language: Language
    var level: ProficiencyLevel
    var lessonsCompleted: Int
    var wordsLearned: Int
    var streak: Int
    var lastStudyDate: Date?
    var totalStudyMinutes: Int
    var quizScores: [Double]
    
    var averageScore: Double {
        guard !quizScores.isEmpty else { return 0 }
        return quizScores.reduce(0, +) / Double(quizScores.count)
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
    var translation: String?
    
    init(content: String, isUser: Bool, timestamp: Date = Date(), translation: String? = nil) {
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.translation = translation
    }
}
