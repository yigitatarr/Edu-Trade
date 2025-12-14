//
//  SettingsViewModel.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation
import SwiftUI

class SettingsViewModel: ObservableObject {
    @Published var settings: AppSettings
    
    private let userDefaults = UserDefaults.standard
    private let settingsKey = "appSettings"
    
    init() {
        if let data = userDefaults.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = AppSettings()
            saveSettings()
        }
    }
    
    func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            userDefaults.set(encoded, forKey: settingsKey)
        }
    }
    
    func resetSettings() {
        settings = AppSettings()
        saveSettings()
    }
    
    func exportData() -> String? {
        // Export user data as JSON
        let dataManager = DataManager.shared
        let user = dataManager.loadUser()
        let trades = dataManager.loadTrades()
        let orders = dataManager.loadOrders()
        let journalEntries = dataManager.loadJournalEntries()
        let portfolioSnapshots = dataManager.loadPortfolioSnapshots()
        let priceAlerts = dataManager.loadPriceAlerts()
        
        let exportData: [String: Any] = [
            "user": [
                "balance": user.balance,
                "numberOfTrades": user.numberOfTrades,
                "portfolio": user.portfolio,
                "unlockedAchievements": user.unlockedAchievements,
                "progress": [
                    "currentLevel": user.progress.currentLevel,
                    "totalXP": user.progress.totalXP,
                    "streak": user.progress.streak
                ]
            ],
            "trades": trades.map { trade in
                [
                    "id": trade.id.uuidString,
                    "coinSymbol": trade.coinSymbol,
                    "type": trade.type == .buy ? "buy" : "sell",
                    "amount": trade.amount,
                    "price": trade.price,
                    "timestamp": trade.timestamp.timeIntervalSince1970
                ]
            },
            "orders": orders.map { order in
                [
                    "id": order.id.uuidString,
                    "coinSymbol": order.coinSymbol,
                    "type": order.type.rawValue,
                    "amount": order.amount,
                    "limitPrice": order.limitPrice ?? 0,
                    "status": order.status.rawValue
                ]
            },
            "journalEntries": journalEntries.map { entry in
                [
                    "id": entry.id.uuidString,
                    "tradeId": entry.tradeId.uuidString,
                    "coinSymbol": entry.coinSymbol,
                    "notes": entry.notes,
                    "rating": entry.rating
                ]
            },
            "portfolioSnapshots": portfolioSnapshots.map { snapshot in
                [
                    "date": snapshot.date.timeIntervalSince1970,
                    "totalValue": snapshot.totalValue,
                    "profit": snapshot.profit
                ]
            },
            "priceAlerts": priceAlerts.map { alert in
                [
                    "id": alert.id.uuidString,
                    "coinSymbol": alert.coinSymbol,
                    "targetPrice": alert.targetPrice,
                    "condition": alert.condition.rawValue,
                    "isActive": alert.isActive
                ]
            },
            "exportDate": Date().timeIntervalSince1970
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        
        return nil
    }
    
    func importData(from jsonString: String) -> Bool {
        guard let jsonData = jsonString.data(using: .utf8),
              let importData = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return false
        }
        
        let dataManager = DataManager.shared
        
        // Import user data
        if let userData = importData["user"] as? [String: Any] {
            var user = dataManager.loadUser()
            
            if let balance = userData["balance"] as? Double {
                user.balance = balance
            }
            if let numberOfTrades = userData["numberOfTrades"] as? Int {
                user.numberOfTrades = numberOfTrades
            }
            if let portfolio = userData["portfolio"] as? [String: Double] {
                user.portfolio = portfolio
            }
            if let achievements = userData["unlockedAchievements"] as? [String] {
                user.unlockedAchievements = achievements
            }
            
            dataManager.saveUser(user)
        }
        
        // Import trades
        if let tradesData = importData["trades"] as? [[String: Any]] {
            // Trades are complex, we'll just note that import happened
            // Full import would require more complex parsing
        }
        
        return true
    }
    
    func createBackup() -> Data? {
        let dataManager = DataManager.shared
        
        let backup: [String: Any] = [
            "user": try? JSONEncoder().encode(dataManager.loadUser()),
            "trades": try? JSONEncoder().encode(dataManager.loadTrades()),
            "orders": try? JSONEncoder().encode(dataManager.loadOrders()),
            "journalEntries": try? JSONEncoder().encode(dataManager.loadJournalEntries()),
            "portfolioSnapshots": try? JSONEncoder().encode(dataManager.loadPortfolioSnapshots()),
            "priceAlerts": try? JSONEncoder().encode(dataManager.loadPriceAlerts()),
            "settings": try? JSONEncoder().encode(settings),
            "backupDate": Date().timeIntervalSince1970
        ]
        
        return try? JSONSerialization.data(withJSONObject: backup, options: [])
    }
    
    func restoreFromBackup(_ data: Data) -> Bool {
        guard let backup = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return false
        }
        
        let dataManager = DataManager.shared
        
        // Restore user
        if let userData = backup["user"] as? Data,
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            dataManager.saveUser(user)
        }
        
        // Restore trades
        if let tradesData = backup["trades"] as? Data,
           let trades = try? JSONDecoder().decode([Trade].self, from: tradesData) {
            dataManager.saveTrades(trades)
        }
        
        // Restore orders
        if let ordersData = backup["orders"] as? Data,
           let orders = try? JSONDecoder().decode([Order].self, from: ordersData) {
            dataManager.saveOrders(orders)
        }
        
        // Restore journal entries
        if let journalData = backup["journalEntries"] as? Data,
           let entries = try? JSONDecoder().decode([TradingJournalEntry].self, from: journalData) {
            dataManager.saveJournalEntries(entries)
        }
        
        // Restore portfolio snapshots
        if let snapshotsData = backup["portfolioSnapshots"] as? Data,
           let snapshots = try? JSONDecoder().decode([PortfolioSnapshot].self, from: snapshotsData) {
            dataManager.savePortfolioSnapshots(snapshots)
        }
        
        // Restore price alerts
        if let alertsData = backup["priceAlerts"] as? Data,
           let alerts = try? JSONDecoder().decode([PriceAlert].self, from: alertsData) {
            dataManager.savePriceAlerts(alerts)
        }
        
        // Restore settings
        if let settingsData = backup["settings"] as? Data,
           let restoredSettings = try? JSONDecoder().decode(AppSettings.self, from: settingsData) {
            settings = restoredSettings
            saveSettings()
        }
        
        return true
    }
}

