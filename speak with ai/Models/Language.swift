//
//  Language.swift
//  speak with ai
//

import Foundation

enum Language: String, CaseIterable, Identifiable, Codable {
    case spanish = "Spanish"
    case french = "French"
    case german = "German"
    case italian = "Italian"
    case portuguese = "Portuguese"
    case japanese = "Japanese"
    case korean = "Korean"
    case mandarin = "Mandarin Chinese"
    case hindi = "Hindi"
    case arabic = "Arabic"
    case russian = "Russian"
    case dutch = "Dutch"
    
    var id: String { rawValue }
    
    var flag: String {
        switch self {
        case .spanish: return "🇪🇸"
        case .french: return "🇫🇷"
        case .german: return "🇩🇪"
        case .italian: return "🇮🇹"
        case .portuguese: return "🇧🇷"
        case .japanese: return "🇯🇵"
        case .korean: return "🇰🇷"
        case .mandarin: return "🇨🇳"
        case .hindi: return "🇮🇳"
        case .arabic: return "🇸🇦"
        case .russian: return "🇷🇺"
        case .dutch: return "🇳🇱"
        }
    }
    
    var code: String {
        switch self {
        case .spanish: return "es"
        case .french: return "fr"
        case .german: return "de"
        case .italian: return "it"
        case .portuguese: return "pt"
        case .japanese: return "ja"
        case .korean: return "ko"
        case .mandarin: return "zh"
        case .hindi: return "hi"
        case .arabic: return "ar"
        case .russian: return "ru"
        case .dutch: return "nl"
        }
    }
    
    var greeting: String {
        switch self {
        case .spanish: return "¡Hola!"
        case .french: return "Bonjour!"
        case .german: return "Hallo!"
        case .italian: return "Ciao!"
        case .portuguese: return "Olá!"
        case .japanese: return "こんにちは!"
        case .korean: return "안녕하세요!"
        case .mandarin: return "你好!"
        case .hindi: return "नमस्ते!"
        case .arabic: return "مرحبا!"
        case .russian: return "Привет!"
        case .dutch: return "Hallo!"
        }
    }
}
