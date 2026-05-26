//
//  LanguagePickerView.swift
//  speak with ai
//

import SwiftUI

struct LanguagePickerView: View {
    @Binding var selectedLanguage: Language
    @Binding var selectedLevel: ProficiencyLevel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                // Language Selection
                Section("Choose a Language") {
                    ForEach(Language.allCases) { language in
                        Button(action: { selectedLanguage = language }) {
                            HStack {
                                Text(language.flag)
                                    .font(.title2)
                                
                                VStack(alignment: .leading) {
                                    Text(language.rawValue)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    Text(language.greeting)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                if selectedLanguage == language {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
                
                // Level Selection
                Section("Your Level") {
                    ForEach(ProficiencyLevel.allCases) { level in
                        Button(action: { selectedLevel = level }) {
                            HStack {
                                Image(systemName: level.icon)
                                    .foregroundStyle(.blue)
                                    .frame(width: 30)
                                
                                VStack(alignment: .leading) {
                                    Text(level.rawValue)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    Text(levelDescription(level))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                if selectedLevel == level {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Language & Level")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .bold()
                }
            }
        }
    }
    
    private func levelDescription(_ level: ProficiencyLevel) -> String {
        switch level {
        case .beginner:
            return "Just starting out, learning basics"
        case .elementary:
            return "Know basic phrases and simple sentences"
        case .intermediate:
            return "Can handle everyday conversations"
        case .upperIntermediate:
            return "Comfortable with complex topics"
        case .advanced:
            return "Near-native fluency"
        }
    }
}

#Preview {
    LanguagePickerView(
        selectedLanguage: .constant(.spanish),
        selectedLevel: .constant(.beginner)
    )
}
