//
//  DailyChallengeView.swift
//  speak with ai
//

import SwiftUI

struct DailyChallengeView: View {
    @Binding var language: Language
    @Binding var level: ProficiencyLevel
    
    var body: some View {
        NavigationStack {
            Text("Coming Soon")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .navigationTitle("Daily Challenge")
        }
    }
}

#Preview {
    DailyChallengeView(
        language: .constant(.spanish),
        level: .constant(.beginner)
    )
}
