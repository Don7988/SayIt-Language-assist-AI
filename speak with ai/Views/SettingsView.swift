//
//  SettingsView.swift
//  speak with ai
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var aiService: AIService
    @EnvironmentObject var progressManager: ProgressManager
    @Environment(\.dismiss) var dismiss
    
    @State private var apiKey = ""
    @State private var showAPIKey = false
    @State private var showResetAlert = false
    @State private var keySaved = false
    @State private var isTesting = false
    @State private var testResult: String?
    @State private var testSuccess: Bool?
    
    var body: some View {
        NavigationStack {
            List {
                // AI Provider Selection
                Section {
                    ForEach(AIProvider.allCases) { provider in
                        Button(action: {
                            aiService.setProvider(provider)
                            apiKey = aiService.getAPIKey(for: provider)
                        }) {
                            HStack {
                                Image(systemName: provider.icon)
                                    .foregroundStyle(.blue)
                                    .frame(width: 28)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(provider.rawValue)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    Text(provider.defaultModel)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                if aiService.selectedProvider == provider {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                                
                                // Key status indicator
                                if !aiService.getAPIKey(for: provider).isEmpty {
                                    Circle()
                                        .fill(.green)
                                        .frame(width: 8, height: 8)
                                }
                            }
                        }
                    }
                } header: {
                    Text("AI Model")
                } footer: {
                    Text("Select your preferred AI provider. A green dot means a key is saved.")
                }
                
                // API Key for selected provider
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(aiService.selectedProvider.rawValue) API Key")
                            .font(.subheadline.bold())
                        
                        HStack {
                            if showAPIKey {
                                TextField(aiService.selectedProvider.keyPlaceholder, text: $apiKey)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(.body, design: .monospaced))
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            } else {
                                SecureField(aiService.selectedProvider.keyPlaceholder, text: $apiKey)
                                    .textFieldStyle(.roundedBorder)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            }
                            
                            Button(action: { showAPIKey.toggle() }) {
                                Image(systemName: showAPIKey ? "eye.slash" : "eye")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Button(action: saveAPIKey) {
                            HStack {
                                Image(systemName: keySaved ? "checkmark.circle.fill" : "key.fill")
                                Text(keySaved ? "Saved!" : "Save Key")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(keySaved ? .green : .blue)
                        
                        // Connection test result
                        if isTesting {
                            HStack(spacing: 8) {
                                SwiftUI.ProgressView()
                                    .scaleEffect(0.8)
                                Text("Testing connection...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 4)
                        } else if let result = testResult, let success = testSuccess {
                            HStack(spacing: 6) {
                                Image(systemName: success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(success ? .green : .red)
                                Text(success ? "Connection successful" : "Connection failed")
                                    .font(.caption.bold())
                                    .foregroundStyle(success ? .green : .red)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("API Key")
                } footer: {
                    Text(aiService.selectedProvider.keyHint)
                }
                
                // App Info
                Section("About") {
                    HStack {
                        Text("App")
                        Spacer()
                        Text("AI Language Teacher")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Active Model")
                        Spacer()
                        Text(aiService.selectedProvider.defaultModel)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Supported Languages
                Section("Supported Languages") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(Language.allCases) { language in
                            HStack {
                                Text(language.flag)
                                Text(language.rawValue)
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Reset
                Section {
                    Button(role: .destructive, action: { showResetAlert = true }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Reset All Progress")
                        }
                    }
                } footer: {
                    Text("This will permanently delete all your learning progress.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Reset Progress", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    resetProgress()
                }
            } message: {
                Text("Are you sure you want to reset all your learning progress? This cannot be undone.")
            }
            .onAppear {
                apiKey = aiService.getAPIKey(for: aiService.selectedProvider)
            }
            .onChange(of: aiService.selectedProvider) { _, newProvider in
                apiKey = aiService.getAPIKey(for: newProvider)
                keySaved = false
                showAPIKey = false
            }
        }
    }
    
    private func saveAPIKey() {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        aiService.setAPIKey(trimmed, for: aiService.selectedProvider)
        keySaved = true
        
        // Auto-test the connection
        isTesting = true
        testResult = nil
        testSuccess = nil
        
        Task {
            let result = await aiService.testConnection()
            await MainActor.run {
                testResult = result.message
                testSuccess = result.success
                isTesting = false
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            keySaved = false
        }
    }
    
    private func resetProgress() {
        UserDefaults.standard.removeObject(forKey: "languageProgress")
        progressManager.allProgress = [:]
    }
}

#Preview {
    SettingsView()
        .environmentObject(AIService())
        .environmentObject(ProgressManager())
}
