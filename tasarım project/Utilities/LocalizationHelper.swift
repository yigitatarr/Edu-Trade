//
//  LocalizationHelper.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation
import SwiftUI

class LocalizationHelper: ObservableObject {
    static let shared = LocalizationHelper()
    
    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "appLanguage")
        }
    }
    
    private init() {
        // Try to load from SettingsViewModel first
        let settingsVM = SettingsViewModel()
        if settingsVM.settings.language != .turkish || settingsVM.settings.language != .english {
            self.currentLanguage = settingsVM.settings.language
        } else if let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage"),
           let language = AppLanguage(rawValue: savedLanguage) {
            self.currentLanguage = language
        } else {
            // Default to system language or Turkish
            let systemLanguage = Locale.preferredLanguages.first ?? "tr"
            if systemLanguage.hasPrefix("en") {
                self.currentLanguage = .english
            } else {
                self.currentLanguage = .turkish
            }
        }
    }
    
    func updateLanguage(_ language: AppLanguage) {
        currentLanguage = language
    }
    
    func string(for key: String) -> String {
        return localizedString(key: key, language: currentLanguage)
    }
    
    private func localizedString(key: String, language: AppLanguage) -> String {
        // Try to load from Localizable.strings
        if let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return NSLocalizedString(key, bundle: bundle, comment: "")
        }
        
        // Fallback to hardcoded strings
        return fallbackString(key: key, language: language)
    }
    
    private func fallbackString(key: String, language: AppLanguage) -> String {
        let strings: [String: [AppLanguage: String]] = [
            // Navigation
            "nav.home": [.turkish: "Ana Sayfa", .english: "Home"],
            "nav.trade": [.turkish: "İşlem", .english: "Trade"],
            "nav.learn": [.turkish: "Öğren", .english: "Learn"],
            "nav.profile": [.turkish: "Profil", .english: "Profile"],
            
            // Common
            "common.balance": [.turkish: "Bakiye", .english: "Balance"],
            "common.portfolio": [.turkish: "Portföy", .english: "Portfolio"],
            "common.trades": [.turkish: "İşlemler", .english: "Trades"],
            "common.profit": [.turkish: "Kâr", .english: "Profit"],
            "common.loss": [.turkish: "Zarar", .english: "Loss"],
            "common.price": [.turkish: "Fiyat", .english: "Price"],
            "common.amount": [.turkish: "Miktar", .english: "Amount"],
            "common.total": [.turkish: "Toplam", .english: "Total"],
            "common.save": [.turkish: "Kaydet", .english: "Save"],
            "common.cancel": [.turkish: "İptal", .english: "Cancel"],
            "common.delete": [.turkish: "Sil", .english: "Delete"],
            "common.edit": [.turkish: "Düzenle", .english: "Edit"],
            "common.done": [.turkish: "Tamam", .english: "Done"],
            "common.search": [.turkish: "Ara", .english: "Search"],
            "common.filter": [.turkish: "Filtrele", .english: "Filter"],
            "common.sort": [.turkish: "Sırala", .english: "Sort"],
            "common.refresh": [.turkish: "Yenile", .english: "Refresh"],
            
            // Trading
            "trading.buy": [.turkish: "Al", .english: "Buy"],
            "trading.sell": [.turkish: "Sat", .english: "Sell"],
            "trading.buyCoin": [.turkish: "Coin Al", .english: "Buy Coin"],
            "trading.sellCoin": [.turkish: "Coin Sat", .english: "Sell Coin"],
            "trading.stopLoss": [.turkish: "Stop Loss", .english: "Stop Loss"],
            "trading.limitOrder": [.turkish: "Limit Emri", .english: "Limit Order"],
            "trading.takeProfit": [.turkish: "Take Profit", .english: "Take Profit"],
            "trading.insufficientBalance": [.turkish: "Yetersiz bakiye", .english: "Insufficient balance"],
            "trading.insufficientCoins": [.turkish: "Yetersiz coin", .english: "Insufficient coins"],
            "trading.tradeSuccess": [.turkish: "İşlem başarılı", .english: "Trade successful"],
            "trading.tradeFailed": [.turkish: "İşlem başarısız", .english: "Trade failed"],
            
            // Learning
            "learning.lessons": [.turkish: "Dersler", .english: "Lessons"],
            "learning.quizzes": [.turkish: "Quiz'ler", .english: "Quizzes"],
            "learning.challenges": [.turkish: "Görevler", .english: "Challenges"],
            "learning.completed": [.turkish: "Tamamlandı", .english: "Completed"],
            "learning.inProgress": [.turkish: "Devam Ediyor", .english: "In Progress"],
            "learning.notStarted": [.turkish: "Başlanmadı", .english: "Not Started"],
            "learning.startQuiz": [.turkish: "Quiz'i Başlat", .english: "Start Quiz"],
            "learning.startLesson": [.turkish: "Dersi Başlat", .english: "Start Lesson"],
            "learning.score": [.turkish: "Skor", .english: "Score"],
            "learning.xp": [.turkish: "XP", .english: "XP"],
            "learning.level": [.turkish: "Seviye", .english: "Level"],
            "learning.streak": [.turkish: "Seri", .english: "Streak"],
            
            // Profile
            "profile.overview": [.turkish: "Genel Bakış", .english: "Overview"],
            "profile.trading": [.turkish: "Trading", .english: "Trading"],
            "profile.learning": [.turkish: "Öğrenme", .english: "Learning"],
            "profile.statistics": [.turkish: "İstatistikler", .english: "Statistics"],
            "profile.achievements": [.turkish: "Başarımlar", .english: "Achievements"],
            "profile.settings": [.turkish: "Ayarlar", .english: "Settings"],
            "profile.totalTrades": [.turkish: "Toplam İşlem", .english: "Total Trades"],
            "profile.winRate": [.turkish: "Başarı Oranı", .english: "Win Rate"],
            "profile.totalProfit": [.turkish: "Toplam Kâr", .english: "Total Profit"],
            
            // Settings
            "settings.appearance": [.turkish: "Görünüm", .english: "Appearance"],
            "settings.language": [.turkish: "Dil", .english: "Language"],
            "settings.notifications": [.turkish: "Bildirimler", .english: "Notifications"],
            "settings.backup": [.turkish: "Yedekleme", .english: "Backup"],
            "settings.export": [.turkish: "Dışa Aktar", .english: "Export"],
            "settings.reset": [.turkish: "Sıfırla", .english: "Reset"],
            "settings.theme.light": [.turkish: "Açık", .english: "Light"],
            "settings.theme.dark": [.turkish: "Koyu", .english: "Dark"],
            "settings.theme.system": [.turkish: "Sistem", .english: "System"],
            
            // Errors
            "error.network": [.turkish: "Ağ hatası", .english: "Network error"],
            "error.unknown": [.turkish: "Bilinmeyen hata", .english: "Unknown error"],
            "error.invalidInput": [.turkish: "Geçersiz giriş", .english: "Invalid input"],
            "error.loading": [.turkish: "Yükleniyor...", .english: "Loading..."],
            
            // Empty States
            "empty.noCoins": [.turkish: "Coin bulunamadı", .english: "No coins found"],
            "empty.noTrades": [.turkish: "İşlem bulunamadı", .english: "No trades found"],
            "empty.noLessons": [.turkish: "Ders bulunamadı", .english: "No lessons found"],
            "empty.noFavorites": [.turkish: "Favori coin yok", .english: "No favorite coins"],
        ]
        
        return strings[key]?[language] ?? key
    }
}

// View extension for easy access
extension View {
    func localized(_ key: String) -> String {
        LocalizationHelper.shared.string(for: key)
    }
}

// String extension
extension String {
    var localized: String {
        LocalizationHelper.shared.string(for: self)
    }
}

