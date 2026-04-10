//
//  AIService.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation
import Security

class AIService: ObservableObject {
    static let shared = AIService()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // OpenRouter API endpoint (OpenAI-compatible)
    private let baseURL = "https://openrouter.ai/api/v1/chat/completions"
    
    // Keychain key
    private let keychainServiceKey = "com.edutrade.openrouter.apikey"
    
    // API Key - Keychain'den okunur (UserDefaults fallback)
    private var apiKey: String {
        // Once Keychain'den oku
        if let key = readFromKeychain(), !key.isEmpty {
            return key
        }
        // Fallback: UserDefaults (eski versiyondan migration)
        if let key = UserDefaults.standard.string(forKey: "openRouterAPIKey"), !key.isEmpty {
            // Keychain'e tasi ve UserDefaults'tan sil
            saveToKeychain(key)
            UserDefaults.standard.removeObject(forKey: "openRouterAPIKey")
            return key
        }
        return ""
    }
    
    // OpenRouter modelleri
    // Primary: google/gemini-2.0-flash-001 (ucuz, hızlı, Türkçe desteği iyi)
    // Fallback: meta-llama/llama-3.1-8b-instruct:free (ücretsiz yedek)
    private let primaryModelName = "google/gemini-2.0-flash-001"
    private let fallbackModelName = "meta-llama/llama-3.1-8b-instruct:free"
    
    // Sistem prompt'u - EduTrade AI Asistanı (optimize edilmiş)
    private let systemPrompt = """
    Sen EduTrade AI'sın. Kripto para trading eğitimi veren bir iOS uygulamasının asistanısın.

    Uygulama: 100.000 USDT demo bakiye, 80+ coin, 25 ders (8 seviye), quiz'ler, başarımlar, XP sistemi.
    Dersler: Trading Temelleri, Stop Loss, Risk Yönetimi, Destek/Direnç, Trend Takibi, Kripto Para Nedir, Borsa, Grafik Okuma, Mum Desenleri, RSI/MACD, İşlem Türleri, Portföy Yönetimi, Hacim Analizi, Fibonacci, Risk/Reward, Trading Psikolojisi, Order Book, Swing Trading, Day Trading, Market Sentiment, Backtesting, Margin Trading, DeFi, Tokenomics, Trading Günlüğü.

    Kurallar:
    - Türkçe, kısa ve öz cevap ver (2-3 paragraf)
    - Basit örneklerle açıkla
    - ASLA yatırım tavsiyesi verme
    - İlgili derse yönlendir: "Uygulamadaki 'X' dersine bakabilirsin"
    - Samimi ve teşvik edici ol
    """
    
    private init() {}
    
    // MARK: - API Key Management (Keychain)
    
    func setAPIKey(_ key: String) {
        saveToKeychain(key)
    }
    
    func hasAPIKey() -> Bool {
        return !apiKey.isEmpty
    }
    
    func setDefaultAPIKey(_ key: String) {
        saveToKeychain(key)
    }
    
    private func saveToKeychain(_ value: String) {
        let data = Data(value.utf8)
        
        // Once mevcut kaydi sil
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceKey
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Yeni kaydi ekle
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }
    
    private func readFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    // MARK: - AI Chat
    
    func askQuestion(_ question: String, context: String? = nil) async throws -> String {
        guard hasAPIKey() else {
            throw AIError.missingAPIKey
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Kullanıcı mesajını oluştur
        var userMessage = question
        if let context = context {
            userMessage = "\(question)\n\nBağlam bilgisi: \(context)"
        }
        
        // Önce primary modeli dene, çalışmazsa fallback
        let modelsToTry = [primaryModelName, fallbackModelName]
        
        for model in modelsToTry {
            do {
                let result = try await performChatRequest(model: model, userMessage: userMessage)
                return result
            } catch AIError.modelNotFound {
                print("⚠️ Model desteklenmiyor (\(model)), sonraki model deneniyor...")
                continue
            } catch AIError.rateLimitExceeded {
                print("⚠️ Rate limit (\(model)), 5 saniye bekleniyor...")
                try? await _Concurrency.Task.sleep(nanoseconds: 5_000_000_000)
                continue
            } catch {
                if model == fallbackModelName {
                    throw error
                }
                print("⚠️ Hata (\(model)): \(error.localizedDescription), sonraki model deneniyor...")
                continue
            }
        }
        
        throw AIError.modelNotFound
    }
    
    // MARK: - OpenAI Chat Completions Request
    
    private func performChatRequest(model: String, userMessage: String) async throws -> String {
        guard let url = URL(string: baseURL) else {
            throw AIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        
        // OpenAI Chat Completions formatı
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userMessage]
            ],
            "max_tokens": 512,
            "temperature": 0.7,
            "top_p": 0.9
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Debug log
        print("🔍 AI Request - Model: \(model)")
        print("🔍 AI Request - URL: \(baseURL)")
        print("🔍 AI Request - Message: \(userMessage.prefix(100))...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }
        
        // Hata kontrolü
        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ API Error (\(httpResponse.statusCode)): \(errorString)")
            }
            
            switch httpResponse.statusCode {
            case 401: throw AIError.invalidAPIKey
            case 429: throw AIError.rateLimitExceeded
            case 404: throw AIError.modelNotFound
            case 500, 502, 503: throw AIError.apiError("Sunucu hatası, lütfen tekrar deneyin")
            default: throw AIError.apiError("HTTP \(httpResponse.statusCode)")
            }
        }
        
        // Response parse et (OpenAI Chat Completions formatı)
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = jsonObject["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            if let rawString = String(data: data, encoding: .utf8) {
                print("⚠️ Raw Response: \(rawString)")
            }
            throw AIError.invalidResponse
        }
        
        let cleanedResponse = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("✅ AI Response - Model: \(model), Length: \(cleanedResponse.count)")
        
        return cleanedResponse.isEmpty ? "Üzgünüm, şu anda cevap veremiyorum. Lütfen tekrar deneyin." : cleanedResponse
    }
    
    // MARK: - Specialized Functions
    
    func analyzeCoin(_ coin: Coin, portfolio: [String: Double]? = nil) async throws -> String {
        let marketCapText: String
        if let marketCap = coin.marketCap, marketCap > 0 {
            marketCapText = formatLargeNumber(marketCap)
        } else {
            marketCapText = "Bilinmiyor"
        }
        
        let context = """
        Coin: \(coin.name) (\(coin.symbol))
        Fiyat: $\(String(format: "%.2f", coin.price))
        24h Değişim: \(String(format: "%.2f", coin.change24h))%
        Market Cap: \(marketCapText)
        """
        
        let question = "Bu coin hakkında eğitim amaçlı analiz yap. Risk faktörlerini, teknik özelliklerini ve genel durumunu açıkla. Yatırım tavsiyesi verme."
        
        return try await askQuestion(question, context: context)
    }
    
    func explainConcept(_ concept: String) async throws -> String {
        let question = "\(concept) nedir? Kripto para trading bağlamında açıkla. Basit ve anlaşılır bir şekilde, örneklerle anlat."
        return try await askQuestion(question)
    }
    
    func suggestPortfolioChanges(portfolio: [String: Double], coins: [Coin]) async throws -> String {
        let portfolioInfo = portfolio.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
        let context = "Mevcut portföy: \(portfolioInfo)"
        let question = "Bu portföy için eğitim amaçlı genel öneriler ver. Risk dağılımı, çeşitlendirme ve dengeleme konularında bilgi ver. Yatırım tavsiyesi verme."
        
        return try await askQuestion(question, context: context)
    }
    
    // MARK: - Helper Functions
    
    private func formatLargeNumber(_ number: Double) -> String {
        if number >= 1_000_000_000 {
            return String(format: "$%.2fB", number / 1_000_000_000)
        } else if number >= 1_000_000 {
            return String(format: "$%.2fM", number / 1_000_000)
        } else {
            return String(format: "$%.2f", number)
        }
    }
}

enum AIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(String)
    case modelLoading
    case missingAPIKey
    case invalidAPIKey
    case rateLimitExceeded
    case modelNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Geçersiz URL"
        case .invalidResponse:
            return "Geçersiz yanıt alındı"
        case .apiError(let message):
            return "API Hatası: \(message)"
        case .modelLoading:
            return "Model yükleniyor, lütfen tekrar deneyin"
        case .missingAPIKey:
            return "API anahtarı bulunamadı. Lütfen ayarlardan OpenRouter API anahtarınızı ekleyin."
        case .invalidAPIKey:
            return "Geçersiz API anahtarı. Lütfen ayarlardan kontrol edin."
        case .rateLimitExceeded:
            return "Çok fazla istek gönderildi. Lütfen birkaç dakika sonra tekrar deneyin."
        case .modelNotFound:
            return "Model bulunamadı. Lütfen daha sonra tekrar deneyin."
        }
    }
}
