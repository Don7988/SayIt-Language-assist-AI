//
//  SplashScreenView.swift
//  speak with ai
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var flagsOpacity: Double = 0
    
    private let flags = ["🇪🇸", "🇫🇷", "🇯🇵", "🇩🇪", "🇰🇷", "🇮🇹"]
    
    var body: some View {
        if isActive {
            ContentView()
        } else {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 28) {
                    Spacer()
                    
                    // Logo
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .shadow(color: .blue.opacity(0.25), radius: 12, y: 4)
                        
                        Image(systemName: "waveform.and.mic")
                            .font(.system(size: 40))
                            .foregroundStyle(.white)
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    
                    // Title
                    VStack(spacing: 8) {
                        Text("Speak with AI")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        
                        Text("Your AI Language Teacher")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .opacity(titleOpacity)
                    
                    // Flags row
                    HStack(spacing: 12) {
                        ForEach(flags, id: \.self) { flag in
                            Text(flag)
                                .font(.title2)
                        }
                    }
                    .opacity(flagsOpacity)
                    
                    Spacer()
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) {
                    logoScale = 1.0
                    logoOpacity = 1.0
                }
                withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
                    titleOpacity = 1.0
                }
                withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
                    flagsOpacity = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
