//
//  AppSettings.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation

enum AppTheme: String, Codable, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .light: return "Açık"
        case .dark: return "Koyu"
        case .system: return "Sistem"
        }
    }
}

enum AppLanguage: String, Codable, CaseIterable {
    case turkish = "tr"
    case english = "en"
    
    var displayName: String {
        switch self {
        case .turkish: return "Türkçe"
        case .english: return "English"
        }
    }
}

struct AppSettings: Codable {
    var theme: AppTheme
    var language: AppLanguage
    var notificationsEnabled: Bool
    var dailyReminderEnabled: Bool
    var streakReminderEnabled: Bool
    var achievementNotificationEnabled: Bool
    var levelUpNotificationEnabled: Bool
    var priceAlertEnabled: Bool
    var userName: String
    var userAvatar: String // System image name
    
    init() {
        self.theme = .system
        self.language = .turkish
        self.notificationsEnabled = true
        self.dailyReminderEnabled = true
        self.streakReminderEnabled = true
        self.achievementNotificationEnabled = true
        self.levelUpNotificationEnabled = true
        self.priceAlertEnabled = false
        self.userName = "Trader"
        self.userAvatar = "person.circle.fill"
    }
}


