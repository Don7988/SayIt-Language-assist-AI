# SayIt - Language Assist AI

An iOS app that uses AI to teach multiple languages through conversation, vocabulary, grammar, quizzes, and speech — built with SwiftUI.

## Features

- **AI Conversation Partner** — Chat in 12+ languages with an AI that adapts to your level
- **Vocabulary Builder** — AI-generated word lists with pronunciation and examples
- **Grammar Lessons** — Clear explanations with real-world examples
- **8 Quiz Types** — Translation, fill-in-the-blank, listening, matching, true/false, sentence builder, picture & word, conversation
- **Speech-to-Text** — Practice speaking with mic input
- **Text-to-Speech** — Hear proper pronunciation instantly
- **Progress Tracking** — Streaks, words learned, quiz scores, study time
- **Multi-Model Support** — Works with Gemma, Gemini, OpenAI, and Claude

## Supported Languages

🇪🇸 Spanish • 🇫🇷 French • 🇩🇪 German • 🇮🇹 Italian • 🇧🇷 Portuguese • 🇯🇵 Japanese • 🇰🇷 Korean • 🇨🇳 Mandarin • 🇮🇳 Hindi • 🇸🇦 Arabic • 🇷🇺 Russian • 🇳🇱 Dutch

## Setup

1. Open `speak with ai.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Run on a device or simulator
4. Go to Settings → Select an AI provider → Paste your API key

## API Keys

| Provider | Get Key At |
|----------|-----------|
| Gemma / Gemini | [aistudio.google.com](https://aistudio.google.com) |
| OpenAI | [platform.openai.com](https://platform.openai.com) |
| Claude | [console.anthropic.com](https://console.anthropic.com) |

## Tech Stack

- SwiftUI
- AVFoundation (Text-to-Speech)
- Speech Framework (Speech-to-Text)
- Google Generative AI API / OpenAI API / Anthropic API
- UserDefaults for persistence

## Requirements

- iOS 17.0+
- Xcode 15+
- An API key from any supported provider
