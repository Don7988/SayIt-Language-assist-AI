//
//  AIService.swift
//  speak with ai
//

import Foundation
import SwiftUI
import Combine

class AIService: ObservableObject {
    @Published var isLoading = false
    @Published var selectedProvider: AIProvider = .gemma
    
    init() {
        if let saved = UserDefaults.standard.string(forKey: "selectedAIProvider"),
           let provider = AIProvider(rawValue: saved) {
            self.selectedProvider = provider
        }
        
        // Migrate old key format if needed
        if let oldKey = UserDefaults.standard.string(forKey: "gemma_api_key"), !oldKey.isEmpty {
            if getAPIKey(for: .gemma).isEmpty {
                setAPIKey(oldKey, for: .gemma)
            }
            UserDefaults.standard.removeObject(forKey: "gemma_api_key")
        }
    }
    
    func setProvider(_ provider: AIProvider) {
        selectedProvider = provider
        UserDefaults.standard.set(provider.rawValue, forKey: "selectedAIProvider")
    }
    
    // MARK: - Key Management
    
    // Custom URLSession that handles connection drops better
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        config.httpMaximumConnectionsPerHost = 2
        return URLSession(configuration: config)
    }()
    
    func setAPIKey(_ key: String, for provider: AIProvider) {
        UserDefaults.standard.set(key, forKey: provider.storageKey)
    }
    
    func getAPIKey(for provider: AIProvider) -> String {
        UserDefaults.standard.string(forKey: provider.storageKey) ?? ""
    }
    
    var currentAPIKey: String {
        getAPIKey(for: selectedProvider)
    }
    
    var hasAPIKey: Bool {
        !currentAPIKey.isEmpty
    }
    
    // MARK: - Connection Test
    
    /// Tests the API connection with a minimal request and prints result to console
    func testConnection() async -> (success: Bool, message: String) {
        let key = currentAPIKey
        print("[AIService] Provider: \(selectedProvider.rawValue)")
        print("[AIService] Key present: \(!key.isEmpty) (length: \(key.count))")
        print("[AIService] Key prefix: \(String(key.prefix(10)))...")
        print("[AIService] Model: \(selectedProvider.defaultModel)")
        
        guard !key.isEmpty else {
            let msg = "No API key set for \(selectedProvider.rawValue)"
            print("[AIService] ❌ \(msg)")
            return (false, msg)
        }
        
        print("[AIService] 🔄 Testing connection...")
        
        do {
            let response = try await sendSimpleRequest(
                system: "Reply with exactly one word: OK",
                user: "Say OK"
            )
            let msg = "\(selectedProvider.rawValue) connected"
            print("[AIService] ✅ Success! Response: \(response.prefix(80))")
            return (true, msg)
        } catch {
            let msg = "\(error.localizedDescription)"
            print("[AIService] ❌ Failed: \(msg)")
            return (false, msg)
        }
    }
    
    // MARK: - Conversation Practice
    
    func getConversationResponse(
        language: Language,
        level: ProficiencyLevel,
        messages: [ChatMessage],
        topic: String? = nil
    ) async throws -> String {
        let systemPrompt = """
        Reply as a friendly \(language.rawValue) texting partner.

        Rules:
        - Output ONLY 2 lines
        - Line 1 = \(language.rawValue)
        - Line 2 = English translation in parentheses
        - No explanations
        - No labels
        - No markdown
        - No reasoning
        - No extra text

        Keep it short and natural.
        \(level.rawValue) level \(language.rawValue).
        \(topic != nil ? "Topic: \(topic!)" : "")
        """
        
        let contents = buildConversationMessages(system: systemPrompt, history: messages)
        let response = try await sendRequest(system: systemPrompt, messages: contents)
        return cleanResponse(response)
    }
    
    // MARK: - Vocabulary Generation
    
    func generateVocabulary(
        language: Language,
        level: ProficiencyLevel,
        category: String,
        count: Int = 10
    ) async throws -> [VocabularyWord] {
        let systemPrompt = """
        You are a \(language.rawValue) language teacher. Generate exactly \(count) vocabulary words \
        for a \(level.rawValue) level student in the category: \(category).
        
        Return ONLY a JSON array with this exact format (no other text):
        [
            {
                "word": "word in \(language.rawValue)",
                "translation": "English translation",
                "pronunciation": "phonetic pronunciation guide",
                "exampleSentence": "example sentence in \(language.rawValue)",
                "exampleTranslation": "English translation of example"
            }
        ]
        """
        
        let userMessage = "Generate \(count) \(category) vocabulary words for \(level.rawValue) level."
        let response = try await sendSimpleRequest(system: systemPrompt, user: userMessage)
        return parseVocabularyResponse(response)
    }
    
    // MARK: - Grammar Lessons
    
    func generateGrammarLesson(
        language: Language,
        level: ProficiencyLevel,
        topic: String
    ) async throws -> GrammarRule {
        let systemPrompt = """
        You are a \(language.rawValue) grammar teacher. Explain the grammar topic clearly \
        for a \(level.rawValue) level student.
        
        Return ONLY a JSON object with this exact format (no other text):
        {
            "title": "Grammar topic title",
            "explanation": "Clear explanation of the rule with tips",
            "examples": [
                {
                    "sentence": "Example in \(language.rawValue)",
                    "translation": "English translation",
                    "breakdown": "Word-by-word breakdown explaining the grammar"
                }
            ]
        }
        Provide 3-5 examples.
        """
        
        let response = try await sendSimpleRequest(system: systemPrompt, user: "Teach me about: \(topic)")
        return parseGrammarResponse(response, topic: topic)
    }
    
    // MARK: - Quiz Generation
    
    func generateQuiz(
        language: Language,
        level: ProficiencyLevel,
        category: LessonCategory,
        questionCount: Int = 5
    ) async throws -> [QuizQuestion] {
        let systemPrompt = """
        You are a \(language.rawValue) language quiz master. Create a \(category.rawValue) quiz \
        for a \(level.rawValue) level student.
        
        Return ONLY a JSON array with this exact format (no other text):
        [
            {
                "question": "The question text",
                "options": ["option1", "option2", "option3", "option4"],
                "correctAnswer": 0,
                "explanation": "Why this answer is correct"
            }
        ]
        Generate exactly \(questionCount) questions. correctAnswer is the 0-based index of the correct option.
        Mix question types: translations, fill-in-the-blank, grammar corrections, etc.
        """
        
        let response = try await sendSimpleRequest(system: systemPrompt, user: "Generate a \(category.rawValue) quiz with \(questionCount) questions.")
        return parseQuizResponse(response)
    }
    
    func generateTypedQuiz(
        language: Language,
        level: ProficiencyLevel,
        quizType: QuizType,
        questionCount: Int = 5
    ) async throws -> [QuizQuestion] {
        let systemPrompt = """
        You are a \(language.rawValue) language quiz master. Create a quiz for a \(level.rawValue) level student.
        
        Quiz type: \(quizType.rawValue)
        Instructions: \(quizType.promptInstruction)
        
        Return ONLY a JSON array with this exact format (no other text):
        [
            {
                "question": "The question text",
                "options": ["option1", "option2", "option3", "option4"],
                "correctAnswer": 0,
                "explanation": "Why this answer is correct"
            }
        ]
        Generate exactly \(questionCount) questions. correctAnswer is the 0-based index of the correct option.
        Make questions fun and engaging for the \(quizType.rawValue) format.
        """
        
        let response = try await sendSimpleRequest(system: systemPrompt, user: "Generate a \(quizType.rawValue) quiz with \(questionCount) questions for \(level.rawValue) level \(language.rawValue).")
        return parseQuizResponse(response)
    }
    
    // MARK: - Pronunciation Help
    
    func getPronunciationGuide(
        language: Language,
        text: String
    ) async throws -> String {
        let systemPrompt = """
        You are a \(language.rawValue) pronunciation coach. Provide a detailed pronunciation guide \
        for the given text. Include:
        1. Phonetic transcription (IPA if applicable)
        2. Syllable breakdown
        3. Stress patterns
        4. Common mistakes to avoid
        5. Tips for native English speakers
        Keep it concise and practical.
        """
        
        return try await sendSimpleRequest(system: systemPrompt, user: "How do I pronounce: \(text)")
    }
    
    // MARK: - Translation
    
    func translate(
        text: String,
        from: Language,
        toEnglish: Bool = true
    ) async throws -> String {
        let direction = toEnglish ? "from \(from.rawValue) to English" : "from English to \(from.rawValue)"
        let systemPrompt = "You are a translator. Translate the following text \(direction). Return ONLY the translation, nothing else."
        
        return try await sendSimpleRequest(system: systemPrompt, user: text)
    }
    
    // MARK: - Sentence Correction
    
    func correctSentence(
        language: Language,
        sentence: String
    ) async throws -> String {
        let systemPrompt = """
        You are a \(language.rawValue) language teacher. The student wrote a sentence in \(language.rawValue). \
        Please:
        1. Identify any errors (grammar, spelling, word choice)
        2. Provide the corrected version
        3. Explain each correction briefly
        4. Rate the sentence (Excellent/Good/Needs Work)
        If the sentence is perfect, congratulate them!
        """
        
        return try await sendSimpleRequest(system: systemPrompt, user: sentence)
    }
    
    // MARK: - Daily Challenge
    
    func getDailyChallenge(
        language: Language,
        level: ProficiencyLevel
    ) async throws -> String {
        let systemPrompt = """
        You are a \(language.rawValue) language teacher. Create a fun daily challenge for a \(level.rawValue) student. \
        The challenge should include:
        1. A phrase of the day with translation and usage context
        2. A mini translation challenge (2-3 sentences)
        3. A cultural tip related to \(language.rawValue)-speaking countries
        Format it nicely with emojis and clear sections.
        """
        
        return try await sendSimpleRequest(system: systemPrompt, user: "Give me today's challenge!")
    }
    
    // MARK: - Response Cleaner
    
    func cleanResponse(_ text: String) -> String {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if let translationIndex = lines.lastIndex(where: {
            $0.hasPrefix("(") && $0.hasSuffix(")")
        }), translationIndex > 0 {
            let message = lines[translationIndex - 1]
            let translation = lines[translationIndex]
            return "\(message)\n\(translation)"
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Private: Message Building
    
    private func buildConversationMessages(system: String, history: [ChatMessage]) -> [[String: String]] {
        var messages: [[String: String]] = []
        for msg in history {
            messages.append([
                "role": msg.isUser ? "user" : "assistant",
                "content": msg.content
            ])
        }
        return messages
    }
    
    private func sendSimpleRequest(system: String, user: String) async throws -> String {
        let messages: [[String: String]] = [
            ["role": "user", "content": user]
        ]
        return try await sendRequest(system: system, messages: messages)
    }
    
    // MARK: - Private: Unified Request Dispatcher
    
    private func sendRequest(system: String, messages: [[String: String]]) async throws -> String {
        guard !currentAPIKey.isEmpty else {
            throw AIError.noAPIKey
        }
        
        var lastError: Error = AIError.invalidResponse
        
        for attempt in 1...3 {
            do {
                switch selectedProvider {
                case .gemma, .gemini:
                    return try await sendGoogleRequest(system: system, messages: messages)
                case .openAI:
                    return try await sendOpenAIRequest(system: system, messages: messages)
                case .claude:
                    return try await sendClaudeRequest(system: system, messages: messages)
                }
            } catch AIError.apiError(let code, _) where code == 404 {
                lastError = AIError.apiError(statusCode: code, message: "Model not available")
                break
            } catch let error as URLError {
                lastError = AIError.networkError(underlying: error)
                if attempt < 3 {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                }
            } catch {
                lastError = error
                if attempt < 3 {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                } else {
                    break
                }
            }
        }
        
        throw lastError
    }
    
    // MARK: - Google (Gemma / Gemini)
    
    private func sendGoogleRequest(system: String, messages: [[String: String]]) async throws -> String {
        let models = selectedProvider.models
        var lastError: Error = AIError.invalidResponse
        
        for model in models {
            do {
                let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(currentAPIKey)"
                guard let url = URL(string: urlString) else { throw AIError.invalidURL }
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.timeoutInterval = 30
                
                // Build contents — embed system in first user message for Gemma, use systemInstruction for Gemini
                var contents: [[String: Any]] = []
                var systemEmbedded = false
                
                for msg in messages {
                    let role = msg["role"] == "user" ? "user" : "model"
                    var text = msg["content"] ?? ""
                    
                    if role == "user" && !systemEmbedded && selectedProvider == .gemma {
                        text = "\(system)\n\n\(text)"
                        systemEmbedded = true
                    }
                    
                    contents.append([
                        "role": role,
                        "parts": [["text": text]]
                    ])
                }
                
                if !systemEmbedded && selectedProvider == .gemma {
                    contents.insert(["role": "user", "parts": [["text": system]]], at: 0)
                }
                
                var body: [String: Any] = [
                    "contents": contents,
                    "generationConfig": [
                        "temperature": 0.7,
                        "maxOutputTokens": 2048,
                        "topP": 0.95,
                        "topK": 40
                    ]
                ]
                
                // Gemini supports systemInstruction natively
                if selectedProvider == .gemini {
                    body["systemInstruction"] = ["parts": [["text": system]]]
                }
                
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                
                let (data, response) = try await session.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else { throw AIError.invalidResponse }
                
                guard httpResponse.statusCode == 200 else {
                    let errorBody = String(data: data, encoding: .utf8) ?? ""
                    if httpResponse.statusCode == 404 {
                        lastError = AIError.apiError(statusCode: 404, message: "Model \(model) not found")
                        continue
                    }
                    throw AIError.apiError(statusCode: httpResponse.statusCode, message: errorBody)
                }
                
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let candidates = json["candidates"] as? [[String: Any]],
                      let firstCandidate = candidates.first,
                      let content = firstCandidate["content"] as? [String: Any],
                      let parts = content["parts"] as? [[String: Any]],
                      let firstPart = parts.first,
                      let text = firstPart["text"] as? String else {
                    throw AIError.parsingError
                }
                
                return text.trimmingCharacters(in: .whitespacesAndNewlines)
                
            } catch AIError.apiError(let code, _) where code == 404 {
                lastError = AIError.apiError(statusCode: code, message: "Model not available")
                continue
            }
        }
        
        throw lastError
    }
    
    // MARK: - OpenAI
    
    private func sendOpenAIRequest(system: String, messages: [[String: String]]) async throws -> String {
        let urlString = "https://api.openai.com/v1/chat/completions"
        guard let url = URL(string: urlString) else { throw AIError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(currentAPIKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        var chatMessages: [[String: String]] = [
            ["role": "system", "content": system]
        ]
        chatMessages.append(contentsOf: messages)
        
        let body: [String: Any] = [
            "model": selectedProvider.defaultModel,
            "messages": chatMessages,
            "temperature": 0.7,
            "max_tokens": 2048
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw AIError.invalidResponse }
        
        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? ""
            throw AIError.apiError(statusCode: httpResponse.statusCode, message: errorBody)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIError.parsingError
        }
        
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Claude (Anthropic)
    
    private func sendClaudeRequest(system: String, messages: [[String: String]]) async throws -> String {
        let urlString = "https://api.anthropic.com/v1/messages"
        guard let url = URL(string: urlString) else { throw AIError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(currentAPIKey, forHTTPHeaderField: "x-api-key")
        request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        let claudeMessages: [[String: String]] = messages.map { msg in
            ["role": msg["role"] == "assistant" ? "assistant" : "user", "content": msg["content"] ?? ""]
        }
        
        let body: [String: Any] = [
            "model": selectedProvider.defaultModel,
            "max_tokens": 2048,
            "system": system,
            "messages": claudeMessages
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw AIError.invalidResponse }
        
        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? ""
            throw AIError.apiError(statusCode: httpResponse.statusCode, message: errorBody)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstBlock = content.first,
              let text = firstBlock["text"] as? String else {
            throw AIError.parsingError
        }
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Response Parsers
    
    private func parseVocabularyResponse(_ response: String) -> [VocabularyWord] {
        let cleaned = extractJSON(from: response)
        
        guard let data = cleaned.data(using: .utf8),
              let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] else {
            return []
        }
        
        return jsonArray.compactMap { dict in
            guard let word = dict["word"],
                  let translation = dict["translation"],
                  let pronunciation = dict["pronunciation"],
                  let example = dict["exampleSentence"],
                  let exampleTrans = dict["exampleTranslation"] else {
                return nil
            }
            return VocabularyWord(
                word: word,
                translation: translation,
                pronunciation: pronunciation,
                exampleSentence: example,
                exampleTranslation: exampleTrans
            )
        }
    }
    
    private func parseGrammarResponse(_ response: String, topic: String) -> GrammarRule {
        let cleaned = extractJSON(from: response)
        
        guard let data = cleaned.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return GrammarRule(title: topic, explanation: response, examples: [])
        }
        
        let title = json["title"] as? String ?? topic
        let explanation = json["explanation"] as? String ?? ""
        let examplesArray = json["examples"] as? [[String: String]] ?? []
        
        let examples = examplesArray.map { dict in
            GrammarExample(
                sentence: dict["sentence"] ?? "",
                translation: dict["translation"] ?? "",
                breakdown: dict["breakdown"] ?? ""
            )
        }
        
        return GrammarRule(title: title, explanation: explanation, examples: examples)
    }
    
    private func parseQuizResponse(_ response: String) -> [QuizQuestion] {
        let cleaned = extractJSON(from: response)
        
        guard let data = cleaned.data(using: .utf8),
              let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        
        return jsonArray.compactMap { dict in
            guard let question = dict["question"] as? String,
                  let options = dict["options"] as? [String],
                  let correctAnswer = dict["correctAnswer"] as? Int,
                  let explanation = dict["explanation"] as? String else {
                return nil
            }
            return QuizQuestion(
                question: question,
                options: options,
                correctAnswer: correctAnswer,
                explanation: explanation
            )
        }
    }
    
    private func extractJSON(from text: String) -> String {
        var cleaned = text
        if cleaned.contains("```json") {
            cleaned = cleaned.replacingOccurrences(of: "```json", with: "")
        }
        if cleaned.contains("```") {
            cleaned = cleaned.replacingOccurrences(of: "```", with: "")
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum AIError: LocalizedError {
    case noAPIKey
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case networkError(underlying: URLError)
    case parsingError
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No API key configured. Please add your API key in Settings."
        case .invalidURL:
            return "Invalid API URL."
        case .invalidResponse:
            return "Invalid response from server."
        case .apiError(let code, let message):
            return "API Error (\(code)): \(message)"
        case .networkError(let error):
            switch error.code {
            case .notConnectedToInternet:
                return "No internet connection. Please check your Wi-Fi or cellular data."
            case .timedOut:
                return "Request timed out. Please try again."
            case .networkConnectionLost:
                return "Connection lost. Please check your network and try again."
            default:
                return "Network error: \(error.localizedDescription)"
            }
        case .parsingError:
            return "Failed to parse response."
        }
    }
}
