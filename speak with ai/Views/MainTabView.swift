//
//  MainTabView.swift
//  speak with ai
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var aiService = AIService()
    @StateObject private var speechService = SpeechService()
    @StateObject private var progressManager = ProgressManager()
    @State private var selectedLanguage: Language = {
        if let saved = UserDefaults.standard.string(forKey: "lastSelectedLanguage"),
           let language = Language(rawValue: saved) {
            return language
        }
        return .spanish
    }()
    @State private var selectedLevel: ProficiencyLevel = {
        if let saved = UserDefaults.standard.string(forKey: "lastSelectedLevel"),
           let level = ProficiencyLevel(rawValue: saved) {
            return level
        }
        return .beginner
    }()
    
    var body: some View {
        TabView {
            HomeView(
                selectedLanguage: $selectedLanguage,
                selectedLevel: $selectedLevel
            )
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            
            ConversationView(
                language: $selectedLanguage,
                level: $selectedLevel
            )
            .tabItem {
                Label("Chat", systemImage: "bubble.left.and.bubble.right.fill")
            }
            
            LessonsView(
                language: $selectedLanguage,
                level: $selectedLevel
            )
            .tabItem {
                Label("Learn", systemImage: "book.fill")
            }
            
            QuizView(
                language: $selectedLanguage,
                level: $selectedLevel
            )
            .tabItem {
                Label("Quiz", systemImage: "questionmark.circle.fill")
            }
            
            LearningProgressView(
                language: $selectedLanguage
            )
            .tabItem {
                Label("Progress", systemImage: "chart.bar.fill")
            }
            
            DailyChallengeView(
                language: $selectedLanguage,
                level: $selectedLevel
            )
            .tabItem {
                Label("Challenge", systemImage: "star.fill")
            }
        }
        .environmentObject(aiService)
        .environmentObject(speechService)
        .environmentObject(progressManager)
        .tint(.blue)
        .onChange(of: selectedLanguage) { _, newValue in
            UserDefaults.standard.set(newValue.rawValue, forKey: "lastSelectedLanguage")
        }
        .onChange(of: selectedLevel) { _, newValue in
            UserDefaults.standard.set(newValue.rawValue, forKey: "lastSelectedLevel")
        }
    }
}

#Preview {
    MainTabView()
}
