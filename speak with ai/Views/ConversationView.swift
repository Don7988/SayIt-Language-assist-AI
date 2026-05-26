//
//  ConversationView.swift
//  speak with ai
//

import SwiftUI

struct ConversationView: View {
    @EnvironmentObject var aiService: AIService
    @EnvironmentObject var speechService: SpeechService
    @EnvironmentObject var progressManager: ProgressManager
    @Binding var language: Language
    @Binding var level: ProficiencyLevel
    
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false
    @State private var showTopicPicker = false
    @State private var selectedTopic: String?
    @State private var autoSpeak = false
    @State private var failedMessageId: UUID?
    
    private let topics = [
        "Greetings & Introductions",
        "At a Restaurant",
        "Shopping",
        "Asking for Directions",
        "At the Doctor",
        "Travel & Transportation",
        "Weather & Seasons",
        "Hobbies & Interests",
        "Family & Friends",
        "Work & Career",
        "Food & Cooking",
        "Free Conversation"
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Topic Banner
                if let topic = selectedTopic {
                    topicBanner(topic)
                }
                
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                VStack(spacing: 4) {
                                    MessageBubble(
                                        message: message,
                                        language: language,
                                        onSpeak: {
                                            let firstLine = message.content.components(separatedBy: "\n").first ?? message.content
                                            speechService.speak(text: firstLine, language: language)
                                        }
                                    )
                                    
                                    // Retry button on failed message
                                    if message.isUser && failedMessageId == message.id {
                                        HStack {
                                            Spacer()
                                            Button(action: { retryLastMessage() }) {
                                                HStack(spacing: 6) {
                                                    Image(systemName: "exclamationmark.circle.fill")
                                                        .foregroundStyle(.red)
                                                    Text("Failed to send")
                                                        .font(.caption)
                                                        .foregroundStyle(.red)
                                                    Text("• Retry")
                                                        .font(.caption.bold())
                                                        .foregroundStyle(.blue)
                                                }
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(
                                                    Capsule()
                                                        .fill(Color.red.opacity(0.08))
                                                )
                                            }
                                            
                                            // User avatar spacer to align with bubble
                                            Color.clear.frame(width: 46)
                                        }
                                    }
                                }
                            }
                            
                            if isLoading {
                                TypingIndicator()
                                    .padding(.horizontal)
                                    .id("loading")
                            }
                            
                            // Invisible anchor at the bottom
                            Color.clear
                                .frame(height: 1)
                                .id("bottom")
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _, _ in
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: isLoading) { _, _ in
                        scrollToBottom(proxy: proxy)
                    }
                }
                
                // Input Area
                inputArea
            }
            .navigationTitle("Conversation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { showTopicPicker = true }) {
                        Image(systemName: "text.bubble")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: { autoSpeak.toggle() }) {
                            Image(systemName: autoSpeak ? "speaker.wave.2.fill" : "speaker.slash")
                                .foregroundStyle(autoSpeak ? .blue : .secondary)
                        }
                        
                        Button(action: clearConversation) {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .sheet(isPresented: $showTopicPicker) {
                TopicPickerSheet(topics: topics, selectedTopic: $selectedTopic)
            }
            .onAppear {
                if messages.isEmpty {
                    addWelcomeMessage()
                }
            }
            .onChange(of: language) { _, _ in
                clearConversation()
            }
        }
    }
    
    // MARK: - Topic Banner
    
    private func topicBanner(_ topic: String) -> some View {
        HStack {
            Image(systemName: "bubble.left.and.text.bubble.right")
                .foregroundStyle(.blue)
            Text("Topic: \(topic)")
                .font(.caption.bold())
            Spacer()
            Button(action: { selectedTopic = nil }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.blue.opacity(0.08))
    }
    
    // MARK: - Input Area
    
    private var inputArea: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                // Text Field
                TextField("Type in \(language.rawValue) or English...", text: $inputText)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemGray6))
                    )
                    .onSubmit {
                        sendMessage()
                    }
                
                // Microphone Button
                Button(action: toggleListening) {
                    Image(systemName: speechService.isListening ? "mic.fill" : "mic")
                        .font(.title3)
                        .foregroundStyle(speechService.isListening ? .red : .blue)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(speechService.isListening ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                        )
                }
                
                // Send Button
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(inputText.isEmpty ? .gray : .blue)
                }
                .disabled(inputText.isEmpty || isLoading)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            
            // Speech recognition text
            if speechService.isListening {
                HStack {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                    Text(speechService.recognizedText.isEmpty ? "Listening..." : speechService.recognizedText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Actions
    
    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        let userMessage = ChatMessage(content: text, isUser: true)
        messages.append(userMessage)
        inputText = ""
        failedMessageId = nil
        isLoading = true
        
        Task {
            do {
                let response = try await aiService.getConversationResponse(
                    language: language,
                    level: level,
                    messages: messages,
                    topic: selectedTopic
                )
                
                await MainActor.run {
                    let aiMessage = ChatMessage(content: response, isUser: false)
                    messages.append(aiMessage)
                    isLoading = false
                    progressManager.updateStreak(for: language)
                    
                    if autoSpeak {
                        let firstLine = response.components(separatedBy: "\n").first ?? response
                        speechService.speak(text: firstLine, language: language)
                    }
                }
            } catch {
                await MainActor.run {
                    failedMessageId = userMessage.id
                    isLoading = false
                }
            }
        }
    }
    
    private func retryLastMessage() {
        guard let failedId = failedMessageId,
              let failedMessage = messages.first(where: { $0.id == failedId }) else { return }
        
        failedMessageId = nil
        isLoading = true
        
        Task {
            do {
                let response = try await aiService.getConversationResponse(
                    language: language,
                    level: level,
                    messages: messages,
                    topic: selectedTopic
                )
                
                await MainActor.run {
                    let aiMessage = ChatMessage(content: response, isUser: false)
                    messages.append(aiMessage)
                    isLoading = false
                    progressManager.updateStreak(for: language)
                    
                    if autoSpeak {
                        let firstLine = response.components(separatedBy: "\n").first ?? response
                        speechService.speak(text: firstLine, language: language)
                    }
                }
            } catch {
                await MainActor.run {
                    failedMessageId = failedMessage.id
                    isLoading = false
                }
            }
        }
    }
    
    private func toggleListening() {
        if speechService.isListening {
            speechService.stopListening()
            if !speechService.recognizedText.isEmpty {
                inputText = speechService.recognizedText
            }
        } else {
            speechService.startListening(language: language)
        }
    }
    
    private func clearConversation() {
        messages.removeAll()
        addWelcomeMessage()
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
    }
    
    private func addWelcomeMessage() {
        let welcome = ChatMessage(
            content: "\(language.greeting) I'm your \(language.rawValue) conversation partner! You can type or speak in \(language.rawValue) or English. I'll help you practice and correct any mistakes. What would you like to talk about?",
            isUser: false
        )
        messages.append(welcome)
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage
    let language: Language
    let onSpeak: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if message.isUser {
                Spacer(minLength: 50)
            } else {
                // AI Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                    
                    Text("AI")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 6) {
                // Sender label
                if !message.isUser {
                    Text("\(language.rawValue) Teacher")
                        .font(.caption2.bold())
                        .foregroundStyle(.purple)
                }
                
                // Message content
                Text(message.content)
                    .font(.body)
                    .foregroundStyle(message.isUser ? .white : .primary)
                    .lineSpacing(4)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        BubbleShape(isUser: message.isUser)
                            .fill(message.isUser
                                  ? AnyShapeStyle(LinearGradient(
                                      colors: [Color.blue, Color.blue.opacity(0.85)],
                                      startPoint: .topLeading,
                                      endPoint: .bottomTrailing))
                                  : AnyShapeStyle(Color(.systemGray6))
                            )
                    )
                    .shadow(color: .black.opacity(0.04), radius: 3, y: 2)
                
                // Action bar for AI messages
                if !message.isUser {
                    HStack(spacing: 16) {
                        Button(action: onSpeak) {
                            HStack(spacing: 4) {
                                Image(systemName: "speaker.wave.2.fill")
                                Text("Listen")
                            }
                            .font(.caption2.bold())
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(Color.blue.opacity(0.1))
                            )
                        }
                        
                        Button(action: {
                            UIPasteboard.general.string = message.content
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.on.doc")
                                Text("Copy")
                            }
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(Color(.systemGray5))
                            )
                        }
                        
                        Text(message.timestamp, style: .time)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.top, 2)
                } else {
                    // Timestamp for user messages
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            
            if !message.isUser {
                Spacer(minLength: 50)
            } else {
                // User Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                }
            }
        }
        .id(message.id)
    }
}

// Custom bubble shape with tail
struct BubbleShape: Shape {
    let isUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 18
        let tailSize: CGFloat = 6
        
        var path = Path()
        
        if isUser {
            // User bubble — tail on right
            path.addRoundedRect(in: CGRect(x: rect.minX, y: rect.minY, width: rect.width - tailSize, height: rect.height), cornerSize: CGSize(width: radius, height: radius))
            
            // Tail
            path.move(to: CGPoint(x: rect.maxX - tailSize, y: rect.maxY - 20))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 14))
            path.addLine(to: CGPoint(x: rect.maxX - tailSize, y: rect.maxY - 8))
        } else {
            // AI bubble — tail on left
            path.addRoundedRect(in: CGRect(x: rect.minX + tailSize, y: rect.minY, width: rect.width - tailSize, height: rect.height), cornerSize: CGSize(width: radius, height: radius))
            
            // Tail
            path.move(to: CGPoint(x: rect.minX + tailSize, y: rect.maxY - 20))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - 14))
            path.addLine(to: CGPoint(x: rect.minX + tailSize, y: rect.maxY - 8))
        }
        
        return path
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var dotOffsets: [CGFloat] = [0, 0, 0]
    
    private let dotSize: CGFloat = 10
    private let spacing: CGFloat = 8
    private let bounceHeight: CGFloat = 10
    private let animationDuration: Double = 1.0
    
    var body: some View {
        HStack(spacing: 10) {
            // AI Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                
                Text("AI")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            // Dots
            HStack(spacing: spacing) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.purple.opacity(0.6))
                        .frame(width: dotSize, height: dotSize)
                        .offset(y: dotOffsets[index])
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.systemGray6))
            )
            .shadow(color: .black.opacity(0.04), radius: 3, y: 2)
            
            Spacer()
        }
        .onAppear { startAnimation() }
    }
    
    private func startAnimation() {
        for index in 0..<3 {
            let delay = Double(index) * (animationDuration / 3.0)
            
            withAnimation(
                .easeInOut(duration: animationDuration / 2)
                .repeatForever(autoreverses: true)
                .delay(delay)
            ) {
                dotOffsets[index] = -bounceHeight
            }
        }
    }
}

// MARK: - Topic Picker

struct TopicPickerSheet: View {
    let topics: [String]
    @Binding var selectedTopic: String?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List(topics, id: \.self) { topic in
                Button(action: {
                    selectedTopic = topic
                    dismiss()
                }) {
                    HStack {
                        Text(topic)
                        Spacer()
                        if selectedTopic == topic {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Choose a Topic")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    ConversationView(
        language: .constant(.spanish),
        level: .constant(.beginner)
    )
    .environmentObject(AIService())
    .environmentObject(SpeechService())
    .environmentObject(ProgressManager())
}
