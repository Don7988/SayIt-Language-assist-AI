//
//  QuizType.swift
//  speak with ai
//

import SwiftUI

enum QuizType: String, CaseIterable, Identifiable {
    case translation = "Translation"
    case fillInBlank = "Fill in the Blank"
    case listening = "Listening"
    case matching = "Matching"
    case trueFalse = "True or False"
    case sentenceBuilder = "Sentence Builder"
    case pictureWord = "Picture & Word"
    case conversation = "Conversation"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .translation: return "arrow.left.arrow.right"
        case .fillInBlank: return "text.insert"
        case .listening: return "ear.fill"
        case .matching: return "rectangle.on.rectangle.angled"
        case .trueFalse: return "checkmark.circle"
        case .sentenceBuilder: return "text.word.spacing"
        case .pictureWord: return "photo.fill"
        case .conversation: return "quote.bubble.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .translation: return .blue
        case .fillInBlank: return .purple
        case .listening: return .orange
        case .matching: return .green
        case .trueFalse: return .red
        case .sentenceBuilder: return .indigo
        case .pictureWord: return .pink
        case .conversation: return .teal
        }
    }
    
    var description: String {
        switch self {
        case .translation: return "Translate words and phrases"
        case .fillInBlank: return "Complete the missing word"
        case .listening: return "Identify what you hear"
        case .matching: return "Match pairs together"
        case .trueFalse: return "Is the statement correct?"
        case .sentenceBuilder: return "Arrange words in order"
        case .pictureWord: return "Match image to word"
        case .conversation: return "Choose the right reply"
        }
    }
    
    var promptInstruction: String {
        switch self {
        case .translation:
            return "Create translation questions. Show a word/phrase and ask for the correct translation."
        case .fillInBlank:
            return "Create fill-in-the-blank questions. Show a sentence with a blank (___) and ask which word completes it."
        case .listening:
            return "Create listening comprehension questions. Provide a sentence and ask what it means or what word was used."
        case .matching:
            return "Create matching questions. Give a word and ask which option is its correct match/translation."
        case .trueFalse:
            return "Create true/false questions about grammar rules, translations, or word meanings. Options should be True/False with two distractors."
        case .sentenceBuilder:
            return "Create sentence ordering questions. Show a jumbled sentence and ask for the correct word order."
        case .pictureWord:
            return "Create vocabulary identification questions. Describe a common object/scene and ask which word matches it."
        case .conversation:
            return "Create conversational response questions. Show a dialogue prompt and ask which reply is most appropriate."
        }
    }
}
