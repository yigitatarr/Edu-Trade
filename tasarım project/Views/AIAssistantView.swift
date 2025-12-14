//
//  AIAssistantView.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import SwiftUI

struct AIAssistantView: View {
    @StateObject private var viewModel = AIAssistantViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // API Key uyarısı - Sadece bilgilendirme amaçlı
                if !viewModel.checkAPIKey() {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("API Anahtarı Gerekli")
                                .font(.headline)
                            Spacer()
                        }
                        
                        Text("AI asistanını kullanmak için Hugging Face API anahtarı gereklidir. Lütfen geliştirici ile iletişime geçin.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .padding()
                }
                
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            if viewModel.messages.isEmpty {
                                WelcomeSection(viewModel: viewModel)
                            } else {
                                ForEach(viewModel.messages) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                }
                                
                                if viewModel.isLoading {
                                    HStack {
                                        ProgressView()
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                        Text("AI düşünüyor...")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }
                                    .id("loading")
                                }
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { oldValue, newValue in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: viewModel.isLoading) { oldValue, newValue in
                        if newValue {
                            withAnimation {
                                proxy.scrollTo("loading", anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Input Area
                VStack(spacing: 0) {
                    if let error = viewModel.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.orange.opacity(0.1))
                    }
                    
                    HStack(spacing: 12) {
                        TextField("Sorunuzu yazın...", text: $viewModel.inputText, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(1...4)
                            .disabled(!viewModel.checkAPIKey())
                            .onSubmit {
                                if viewModel.checkAPIKey() {
                                    viewModel.sendMessage(viewModel.inputText)
                                }
                            }
                        
                        Button(action: {
                            HapticFeedback.medium()
                            viewModel.sendMessage(viewModel.inputText)
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(
                                    viewModel.inputText.isEmpty || viewModel.isLoading || !viewModel.checkAPIKey() 
                                        ? .gray 
                                        : .blue
                                )
                        }
                        .disabled(viewModel.inputText.isEmpty || viewModel.isLoading || !viewModel.checkAPIKey())
                    }
                    .padding()
                    .background(Color(.systemBackground))
                }
            }
            .navigationTitle("AI Asistan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewModel.messages.isEmpty {
                        Button(action: {
                            viewModel.clearChat()
                        }) {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
        }
    }
}

struct WelcomeSection: View {
    @ObservedObject var viewModel: AIAssistantViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 8) {
                Text("AI Trading Asistanı")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Trading, kripto para ve teknik analiz konularında sorularınızı sorun")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if viewModel.checkAPIKey() {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Hızlı Sorular")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(viewModel.quickQuestions, id: \.self) { question in
                        Button(action: {
                            HapticFeedback.light()
                            viewModel.askQuickQuestion(question)
                        }) {
                            HStack {
                                Text(question)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .padding(.vertical, 40)
    }
}

struct MessageBubble: View {
    let message: AIMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(message.isUser ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(message.isUser ? Color.blue : Color(.systemGray5))
                    )
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.isUser ? .trailing : .leading)
            
            if !message.isUser {
                Spacer()
            }
        }
    }
}

#Preview {
    AIAssistantView()
}

