//
//  AIAssistantViewModel.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation
import Combine
import _Concurrency

class AIAssistantViewModel: ObservableObject {
    @Published var messages: [AIMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var inputText = ""
    
    private let aiService = AIService.shared
    private let dataManager = DataManager.shared
    
    // Hızlı sorular
    let quickQuestions = [
        "Bitcoin nedir?",
        "Stop Loss nasıl kullanılır?",
        "Portföy çeşitlendirme nedir?",
        "RSI göstergesi nedir?",
        "Risk yönetimi nasıl yapılır?",
        "Fibonacci retracement nedir?"
    ]
    
    init() {
        // API key kontrolü - Sadece bilgilendirme amaçlı
        // API key kod içinde tanımlı olmalı
        if !aiService.hasAPIKey() {
            errorMessage = "API anahtarı bulunamadı. Lütfen geliştirici ile iletişime geçin."
        }
    }
    
    func sendMessage(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = AIMessage(content: text, isUser: true)
        messages.append(userMessage)
        inputText = ""
        errorMessage = nil
        
        _Concurrency.Task {
            await getAIResponse(for: text)
        }
    }
    
    @MainActor
    private func getAIResponse(for question: String) async {
        isLoading = true
        errorMessage = nil
        
        print("🤖 AI Request başlatıldı: \(question)")
        
        do {
            let response = try await aiService.askQuestion(question)
            print("✅ AI Response alındı: \(response.prefix(100))...")
            let aiMessage = AIMessage(content: response, isUser: false)
            messages.append(aiMessage)
        } catch {
            print("❌ AI Error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            // Hata mesajını da ekle
            let errorMsg = AIMessage(content: "Üzgünüm, bir hata oluştu: \(error.localizedDescription)", isUser: false)
            messages.append(errorMsg)
        }
        
        isLoading = false
    }
    
    func askQuickQuestion(_ question: String) {
        sendMessage(question)
    }
    
    func analyzeCoin(_ coin: Coin) {
        _Concurrency.Task {
            await MainActor.run {
                isLoading = true
                errorMessage = nil
            }
            
            let userMessage = AIMessage(content: "\(coin.name) hakkında analiz yap", isUser: true)
            await MainActor.run {
                messages.append(userMessage)
            }
            
            do {
                let response = try await aiService.analyzeCoin(coin)
                let aiMessage = AIMessage(content: response, isUser: false)
                await MainActor.run {
                    messages.append(aiMessage)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    let errorMsg = AIMessage(content: "Üzgünüm, bir hata oluştu: \(error.localizedDescription)", isUser: false)
                    messages.append(errorMsg)
                    isLoading = false
                }
            }
        }
    }
    
    func explainConcept(_ concept: String) {
        _Concurrency.Task {
            await MainActor.run {
                isLoading = true
                errorMessage = nil
            }
            
            let userMessage = AIMessage(content: "\(concept) nedir?", isUser: true)
            await MainActor.run {
                messages.append(userMessage)
            }
            
            do {
                let response = try await aiService.explainConcept(concept)
                let aiMessage = AIMessage(content: response, isUser: false)
                await MainActor.run {
                    messages.append(aiMessage)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    let errorMsg = AIMessage(content: "Üzgünüm, bir hata oluştu: \(error.localizedDescription)", isUser: false)
                    messages.append(errorMsg)
                    isLoading = false
                }
            }
        }
    }
    
    func clearChat() {
        messages.removeAll()
        errorMessage = nil
    }
    
    func checkAPIKey() -> Bool {
        return aiService.hasAPIKey()
    }
}

