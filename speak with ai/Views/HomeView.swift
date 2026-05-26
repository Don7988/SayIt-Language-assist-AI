//
//  HomeView.swift
//  speak with ai
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var aiService: AIService
    @EnvironmentObject var progressManager: ProgressManager
    @Binding var selectedLanguage: Language
    @Binding var selectedLevel: ProficiencyLevel
    @State private var showLanguagePicker = false
    @State private var showSettings = false
    @State private var showDailyChallenge = false
    
    var progress: UserProgress {
        progressManager.getProgress(for: selectedLanguage)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Language Selector Card
                    languageSelectorCard
                    
                    // Stats Overview
                    statsOverview
                    
                    // Daily Challenge Navigation
                    dailyChallengeCard
                    
                    // Quick Actions
                    quickActionsGrid
                }
                .padding()
            }
            .navigationTitle("AI Language Teacher")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showLanguagePicker) {
                LanguagePickerView(
                    selectedLanguage: $selectedLanguage,
                    selectedLevel: $selectedLevel
                )
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
    
    // MARK: - Language Selector
    
    private var languageSelectorCard: some View {
        Button(action: { showLanguagePicker = true }) {
            HStack {
                Text(selectedLanguage.flag)
                    .font(.system(size: 44))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedLanguage.rawValue)
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    
                    Text(selectedLevel.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack {
                    Text(selectedLanguage.greeting)
                        .font(.headline)
                        .foregroundStyle(.blue)
                    
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Stats Overview
    
    private var statsOverview: some View {
        HStack(spacing: 12) {
            StatCard(
                icon: "flame.fill",
                value: "\(progress.streak)",
                label: "Streak",
                color: .orange
            )
            
            StatCard(
                icon: "book.fill",
                value: "\(progress.wordsLearned)",
                label: "Words",
                color: .blue
            )
            
            StatCard(
                icon: "checkmark.circle.fill",
                value: "\(progress.lessonsCompleted)",
                label: "Lessons",
                color: .green
            )
            
            StatCard(
                icon: "clock.fill",
                value: "\(progress.totalStudyMinutes)m",
                label: "Time",
                color: .purple
            )
        }
    }
    
    // MARK: - Daily Challenge
    
    private var dailyChallengeCard: some View {
        NavigationLink(destination: DailyChallengeView(language: $selectedLanguage, level: $selectedLevel)) {
            HStack {
                Image(systemName: "star.circle.fill")
                    .foregroundStyle(.yellow)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Challenge")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("Test yourself with today's challenge")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Quick Actions
    
    private var quickActionsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Start")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionCard(
                    icon: "bubble.left.and.bubble.right.fill",
                    title: "Practice Speaking",
                    subtitle: "Have a conversation",
                    color: .green
                )
                
                QuickActionCard(
                    icon: "character.book.closed",
                    title: "New Vocabulary",
                    subtitle: "Learn new words",
                    color: .blue
                )
                
                QuickActionCard(
                    icon: "text.book.closed.fill",
                    title: "Grammar",
                    subtitle: "Master the rules",
                    color: .purple
                )
                
                QuickActionCard(
                    icon: "waveform",
                    title: "Pronunciation",
                    subtitle: "Sound like a native",
                    color: .orange
                )
            }
        }
    }
    
    // MARK: - Actions
}

// MARK: - Supporting Views

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(value)
                .font(.headline.bold())
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(title)
                .font(.subheadline.bold())
                .lineLimit(1)
            
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    HomeView(
        selectedLanguage: .constant(.spanish),
        selectedLevel: .constant(.beginner)
    )
    .environmentObject(AIService())
    .environmentObject(ProgressManager())
}
