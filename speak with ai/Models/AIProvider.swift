//
//  AIProvider.swift
//  speak with ai
//

import Foundation

enum AIProvider: String, CaseIterable, Identifiable, Codable {
    case gemma = "Gemma (Google)"
    case gemini = "Gemini (Google)"
    case openAI = "OpenAI"
    case claude = "Claude (Anthropic)"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .gemma: return "brain.head.profile"
        case .gemini: return "sparkles"
        case .openAI: return "bubble.left.and.bubble.right"
        case .claude: return "text.bubble"
        }
    }
    
    var keyPlaceholder: String {
        switch self {
        case .gemma, .gemini: return "AIzaSy..."
        case .openAI: return "sk-..."
        case .claude: return "sk-ant-..."
        }
    }
    
    var keyHint: String {
        switch self {
        case .gemma, .gemini: return "Get your key at aistudio.google.com (Gemini API Key)"
        case .openAI: return "Get your key at platform.openai.com"
        case .claude: return "Get your key at console.anthropic.com"
        }
    }
    
    var storageKey: String {
        switch self {
        case .gemma: return "api_key_gemini"
        case .gemini: return "api_key_gemini"
        case .openAI: return "api_key_openai"
        case .claude: return "api_key_claude"
        }
    }
    
    var models: [String] {
        switch self {
        case .gemma: return ["gemma-4-26b-a4b-it", "gemma-4-31b-it", "gemma-3-27b-it"]
        case .gemini: return ["gemini-2.0-flash", "gemini-1.5-flash", "gemini-1.5-pro"]
        case .openAI: return ["gpt-4o-mini", "gpt-4o", "gpt-4-turbo"]
        case .claude: return ["claude-sonnet-4-20250514", "claude-3-5-haiku-20241022"]
        }
    }
    
    var defaultModel: String {
        models.first ?? ""
    }
}
