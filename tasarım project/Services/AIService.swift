//
//  AIService.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation

class AIService: ObservableObject {
    static let shared = AIService()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Hugging Face API - Ücretsiz tier
    // Not: Bazı modeller için API key gerekebilir, bazıları için gerekmez
    // Hugging Face Router Inference endpoint (root): https://router.huggingface.co
    // Model is iletilir: body["model"] = "<repo-id>"
    private let baseURL = "https://router.huggingface.co"
    
    // Alternatif: API key olmadan çalışan endpoint (daha sınırlı)
    // private let baseURL = "https://api-inference.huggingface.co/models"
    
    // API Key - Kod içinde tanımlı, kullanıcıdan istemiyoruz
    // Not: Gerçek kullanımda bu key'i güvenli bir şekilde saklamak gerekir (Keychain, environment variables, etc.)
    // Hugging Face'den ücretsiz API key almak için: https://huggingface.co/settings/tokens
    // Buraya kendi API key'inizi ekleyin
    private var apiKey: String {
        // Önce UserDefaults'tan kontrol et (kullanıcı özel key eklemişse)
        if let key = UserDefaults.standard.string(forKey: "huggingFaceAPIKey"), !key.isEmpty {
            return key
        }
        // Varsayılan API key - Buraya kendi Hugging Face API key'inizi ekleyin
        // Örnek: "hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        // API key almak için: https://huggingface.co/settings/tokens
        // Not: Bu değer boş bırakılmıştır, kullanıcı kendi API key'ini eklemelidir
        let defaultAPIKey = "" // API key buraya eklenmelidir
        
        // Eğer default key boşsa, kullanıcıdan isteme, sadece hata döndür
        return defaultAPIKey
    }
    
    // Mantıklı cevaplar için küçük ve erişilebilir modeller
    // Primary: gpt2 (en erişilebilir açık model)
    // Fallback: google/flan-t5-small
    private let primaryModelName = "gpt2"
    private let fallbackModelName = "google/flan-t5-small"
    
    private init() {}
    
    // MARK: - API Key Management
    
    func setAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "huggingFaceAPIKey")
    }
    
    func hasAPIKey() -> Bool {
        // API key varsa true döndür
        return !apiKey.isEmpty
    }
    
    // API key'i kod içinden set etmek için (geliştirme amaçlı)
    func setDefaultAPIKey(_ key: String) {
        // Bu fonksiyon sadece geliştirme amaçlı
        // Production'da API key'i kod içinde saklamak yerine güvenli bir yöntem kullanın
        UserDefaults.standard.set(key, forKey: "huggingFaceAPIKey")
    }
    
    // MARK: - AI Chat
    
    private func createPrompt(for modelName: String, question: String, context: String?) -> String {
        // T5 modelleri için instruction formatı
        if modelName.contains("flan-t5") || modelName.contains("t5") {
            let systemPrompt = "Sen kripto para ve trading konularında uzman bir eğitim asistanısın. Türkçe olarak, açık ve anlaşılır bir şekilde cevap ver. Yatırım tavsiyesi verme, sadece eğitim amaçlı bilgi ver."
            
            if let context = context {
                return "Soru: \(question). Bağlam: \(context). \(systemPrompt) Cevap:"
            } else {
                return "Soru: \(question). \(systemPrompt) Cevap:"
            }
        } else {
            // Diğer modeller için basit format
            let systemContext = "Kripto para trading asistanı. Soru:"
            
            if let context = context {
                return "\(systemContext) \(question). Bağlam: \(context). Cevap:"
            } else {
                return "\(systemContext) \(question). Cevap:"
            }
        }
    }
    
    func askQuestion(_ question: String, context: String? = nil) async throws -> String {
        guard hasAPIKey() else {
            throw AIError.missingAPIKey
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Önce primary model'i dene, çalışmazsa fallback
        let modelsToTry = [primaryModelName, fallbackModelName]
        
        // Her model için deneme yap
        for model in modelsToTry {
            guard let modelURL = URL(string: baseURL) else {
                continue
            }
            
            // Model tipine göre prompt formatı oluştur
            let formattedPrompt = createPrompt(for: model, question: question, context: context)
            
            // Retry mekanizması ile istek gönder (model yükleniyor hatası için)
            for attempt in 1...3 {
                do {
                    let result = try await performAPIRequest(url: modelURL, prompt: formattedPrompt, modelName: model)
                    return result
                } catch AIError.modelLoading {
                    if attempt < 3 {
                        // Model yükleniyor, 5 saniye bekle ve tekrar dene
                        print("⚠️ Model yükleniyor (\(model)), \(attempt * 5) saniye bekleniyor...")
                        let seconds = Double(attempt * 5)
                        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                            DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                                continuation.resume()
                            }
                        }
                        continue
                    } else {
                        // Model yüklenemedi, bir sonraki model'e geç
                        print("⚠️ Model yüklenemedi (\(model)), bir sonraki model deneniyor...")
                        break
                    }
                } catch AIError.modelNotFound {
                    // Model bulunamadı, bir sonraki model'e geç
                    print("⚠️ Model bulunamadı (\(model)), bir sonraki model deneniyor...")
                    break
                } catch {
                    // Diğer hatalar için son deneme değilse tekrar dene
                    if attempt < 3 {
                        continue
                    } else {
                        // Son deneme başarısız, bir sonraki model'e geç
                        print("⚠️ Model hatası (\(model)): \(error.localizedDescription), bir sonraki model deneniyor...")
                        break
                    }
                }
            }
        }
        
        throw AIError.modelNotFound
    }
    
    private func performAPIRequest(url: URL, prompt: String, modelName: String) async throws -> String {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // API key varsa Authorization header'ı ekle
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 60 // Daha uzun timeout
        
        // Debug: Request bilgilerini logla
        print("🔍 AI Request - Model: \(modelName)")
        print("🔍 AI Request - URL: \(url.absoluteString)")
        print("🔍 AI Request - Has API Key: \(!apiKey.isEmpty)")
        print("🔍 AI Request - API Key prefix: \(apiKey.prefix(10))...")
        print("🔍 AI Request - Prompt: \(prompt.prefix(200))...")
        
        let requestBody: [String: Any] = [
            "inputs": prompt,
            "model": modelName,
            "parameters": [
                "max_new_tokens": 512,
                "temperature": 0.7,
                "top_p": 0.9,
                "return_full_text": false,
                "do_sample": true
            ],
            "options": [
                "wait_for_model": true
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            // Hata detaylarını logla
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("API Error Response: \(errorData)")
            } else if let errorString = String(data: data, encoding: .utf8) {
                print("API Error String: \(errorString)")
            }
            print("API Request URL: \(url.absoluteString)")
            print("API Status Code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 503 {
                // Model yükleniyor, biraz bekle
                throw AIError.modelLoading
            } else if httpResponse.statusCode == 401 {
                throw AIError.invalidAPIKey
            } else if httpResponse.statusCode == 429 {
                throw AIError.rateLimitExceeded
            } else if httpResponse.statusCode == 410 || httpResponse.statusCode == 404 {
                // Model artık mevcut değil veya bulunamadı
                throw AIError.modelNotFound
            }
            throw AIError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        // Hugging Face API response formatını kontrol et
        // Bazen array, bazen direkt object dönebilir
        var generatedText: String = ""
        
        if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
           let firstResponse = jsonArray.first,
           let text = firstResponse["generated_text"] as? String {
            generatedText = text
        } else if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let text = jsonObject["generated_text"] as? String {
            generatedText = text
        } else {
            // Debug için raw response'u göster
            if let rawString = String(data: data, encoding: .utf8) {
                print("Raw API Response: \(rawString)")
                print("Model: \(modelName), Status: \(httpResponse.statusCode)")
            }
            throw AIError.invalidResponse
        }
        
        // Cevabı temizle
        var cleanedResponse = generatedText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n\n", with: "\n")
        
        // Model formatını temizle
        cleanedResponse = cleanedResponse
            .replacingOccurrences(of: "</s>", with: "")
            .replacingOccurrences(of: "[INST]", with: "")
            .replacingOccurrences(of: "[/INST]", with: "")
            .replacingOccurrences(of: "<s>", with: "")
            .replacingOccurrences(of: "Cevap:", with: "")
            .replacingOccurrences(of: "Answer:", with: "")
        
        // Eğer cevap prompt'u içeriyorsa, sadece yeni kısmı al
        if cleanedResponse.contains(prompt) {
            if let range = cleanedResponse.range(of: prompt) {
                cleanedResponse = String(cleanedResponse[range.upperBound...])
            }
        }
        
        cleanedResponse = cleanedResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("✅ AI Response - Model: \(modelName), Response length: \(cleanedResponse.count)")
        
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
            return "Model yükleniyor, lütfen 10-15 saniye sonra tekrar deneyin"
        case .missingAPIKey:
            return "API anahtarı bulunamadı. Lütfen ayarlardan Hugging Face API anahtarınızı ekleyin."
        case .invalidAPIKey:
            return "Geçersiz API anahtarı. Lütfen ayarlardan kontrol edin."
        case .rateLimitExceeded:
            return "Çok fazla istek gönderildi. Lütfen birkaç dakika sonra tekrar deneyin."
        case .modelNotFound:
            return "Model bulunamadı. Lütfen daha sonra tekrar deneyin veya geliştirici ile iletişime geçin."
        }
    }
}

