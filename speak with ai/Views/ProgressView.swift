//
//  ProgressView.swift
//  speak with ai
//

import SwiftUI

struct LearningProgressView: View {
    @EnvironmentObject var progressManager: ProgressManager
    @Binding var language: Language
    
    var progress: UserProgress {
        progressManager.getProgress(for: language)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Language Header
                    languageHeader
                    
                    // Streak Card
                    streakCard
                    
                    // Stats Grid
                    statsGrid
                    
                    // Quiz Performance
                    quizPerformanceCard
                    
                    // Level Progress
                    levelProgressCard
                    
                    // All Languages Overview
                    allLanguagesCard
                }
                .padding()
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Language Header
    
    private var languageHeader: some View {
        HStack {
            Text(language.flag)
                .font(.system(size: 40))
            
            VStack(alignment: .leading) {
                Text(language.rawValue)
                    .font(.title2.bold())
                Text(progress.level.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: progress.level.icon)
                .font(.title)
                .foregroundStyle(.blue)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Streak Card
    
    private var streakCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.title)
                    .foregroundStyle(.orange)
                
                VStack(alignment: .leading) {
                    Text("\(progress.streak) Day Streak")
                        .font(.title3.bold())
                    Text(streakMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            // Week view
            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { day in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(day < progress.streak % 7 ? Color.orange : Color(.systemGray5))
                            .frame(width: 28, height: 28)
                            .overlay(
                                day < progress.streak % 7 ?
                                Image(systemName: "checkmark")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.white) : nil
                            )
                        
                        Text(dayLabel(day))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(0.08))
        )
    }
    
    // MARK: - Stats Grid
    
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ProgressStatCard(
                icon: "book.fill",
                title: "Words Learned",
                value: "\(progress.wordsLearned)",
                color: .blue
            )
            
            ProgressStatCard(
                icon: "checkmark.circle.fill",
                title: "Lessons Done",
                value: "\(progress.lessonsCompleted)",
                color: .green
            )
            
            ProgressStatCard(
                icon: "clock.fill",
                title: "Study Time",
                value: formatTime(progress.totalStudyMinutes),
                color: .purple
            )
            
            ProgressStatCard(
                icon: "percent",
                title: "Avg Quiz Score",
                value: "\(Int(progress.averageScore))%",
                color: .orange
            )
        }
    }
    
    // MARK: - Quiz Performance
    
    private var quizPerformanceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quiz Performance")
                .font(.headline)
            
            if progress.quizScores.isEmpty {
                Text("Complete quizzes to see your performance here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 20)
            } else {
                // Simple bar chart of recent scores
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(Array(progress.quizScores.suffix(10).enumerated()), id: \.offset) { index, score in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(scoreBarColor(score))
                                .frame(width: 24, height: max(CGFloat(score) / 100 * 80, 8))
                            
                            Text("\(Int(score))")
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .frame(height: 100)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Level Progress
    
    private var levelProgressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Level Progress")
                .font(.headline)
            
            ForEach(ProficiencyLevel.allCases) { level in
                HStack {
                    Image(systemName: level.icon)
                        .foregroundStyle(progress.level == level ? .blue : .gray)
                    
                    Text(level.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(progress.level == level ? .primary : .secondary)
                    
                    Spacer()
                    
                    if progress.level == level {
                        Text("Current")
                            .font(.caption.bold())
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.blue.opacity(0.1))
                            )
                    } else if ProficiencyLevel.allCases.firstIndex(of: level)! < ProficiencyLevel.allCases.firstIndex(of: progress.level)! {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - All Languages
    
    private var allLanguagesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Languages")
                .font(.headline)
            
            let activeLanguages = progressManager.allProgress.filter { $0.value.wordsLearned > 0 || $0.value.lessonsCompleted > 0 }
            
            if activeLanguages.isEmpty {
                Text("Start learning to see your progress across languages.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(activeLanguages.keys).sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { lang in
                    if let prog = activeLanguages[lang] {
                        HStack {
                            Text(lang.flag)
                                .font(.title3)
                            
                            VStack(alignment: .leading) {
                                Text(lang.rawValue)
                                    .font(.subheadline.bold())
                                Text("\(prog.wordsLearned) words • \(prog.lessonsCompleted) lessons")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(prog.level.rawValue)
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Helpers
    
    private var streakMessage: String {
        if progress.streak == 0 { return "Start studying to build your streak!" }
        if progress.streak < 7 { return "Keep going! You're building momentum." }
        if progress.streak < 30 { return "Great consistency! Keep it up!" }
        return "Amazing dedication! You're on fire! 🔥"
    }
    
    private func dayLabel(_ index: Int) -> String {
        let days = ["M", "T", "W", "T", "F", "S", "S"]
        return days[index]
    }
    
    private func formatTime(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        let mins = minutes % 60
        return "\(hours)h \(mins)m"
    }
    
    private func scoreBarColor(_ score: Double) -> Color {
        if score >= 80 { return .green }
        if score >= 60 { return .orange }
        return .red
    }
}

// MARK: - Progress Stat Card

struct ProgressStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }
            
            Text(value)
                .font(.title2.bold())
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.08))
        )
    }
}

#Preview {
    LearningProgressView(language: .constant(.spanish))
        .environmentObject(ProgressManager())
}
