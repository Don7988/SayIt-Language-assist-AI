//
//  ProgressManager.swift
//  speak with ai
//

import Foundation
import SwiftUI
import Combine

class ProgressManager: ObservableObject {
    @Published var currentProgress: UserProgress?
    @Published var allProgress: [Language: UserProgress] = [:]
    
    private let userDefaultsKey = "languageProgress"
    
    init() {
        loadProgress()
    }
    
    func getProgress(for language: Language) -> UserProgress {
        if let progress = allProgress[language] {
            return progress
        }
        let newProgress = UserProgress(
            language: language,
            level: .beginner,
            lessonsCompleted: 0,
            wordsLearned: 0,
            streak: 0,
            lastStudyDate: nil,
            totalStudyMinutes: 0,
            quizScores: []
        )
        allProgress[language] = newProgress
        return newProgress
    }
    
    func updateStreak(for language: Language) {
        var progress = getProgress(for: language)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastDate = progress.lastStudyDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            let daysDiff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            
            if daysDiff == 1 {
                progress.streak += 1
            } else if daysDiff > 1 {
                progress.streak = 1
            }
            // Same day - no change
        } else {
            progress.streak = 1
        }
        
        progress.lastStudyDate = Date()
        allProgress[language] = progress
        saveProgress()
    }
    
    func addLessonCompleted(for language: Language) {
        var progress = getProgress(for: language)
        progress.lessonsCompleted += 1
        allProgress[language] = progress
        updateStreak(for: language)
        saveProgress()
    }
    
    func addWordsLearned(for language: Language, count: Int) {
        var progress = getProgress(for: language)
        progress.wordsLearned += count
        allProgress[language] = progress
        saveProgress()
    }
    
    func addQuizScore(for language: Language, score: Double) {
        var progress = getProgress(for: language)
        progress.quizScores.append(score)
        allProgress[language] = progress
        saveProgress()
    }
    
    func addStudyTime(for language: Language, minutes: Int) {
        var progress = getProgress(for: language)
        progress.totalStudyMinutes += minutes
        allProgress[language] = progress
        saveProgress()
    }
    
    func updateLevel(for language: Language, to level: ProficiencyLevel) {
        var progress = getProgress(for: language)
        progress.level = level
        allProgress[language] = progress
        saveProgress()
    }
    
    // MARK: - Persistence
    
    private func saveProgress() {
        let encoder = JSONEncoder()
        var dict: [String: Data] = [:]
        
        for (language, progress) in allProgress {
            if let data = try? encoder.encode(progress) {
                dict[language.rawValue] = data
            }
        }
        
        UserDefaults.standard.set(dict, forKey: userDefaultsKey)
    }
    
    private func loadProgress() {
        guard let dict = UserDefaults.standard.dictionary(forKey: userDefaultsKey) as? [String: Data] else {
            return
        }
        
        let decoder = JSONDecoder()
        for (key, data) in dict {
            if let language = Language(rawValue: key),
               let progress = try? decoder.decode(UserProgress.self, from: data) {
                allProgress[language] = progress
            }
        }
    }
}
