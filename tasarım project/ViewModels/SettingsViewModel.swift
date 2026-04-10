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
        
        if let tradesData = importData["trades"] as? [[String: Any]] {
            var importedTrades: [Trade] = []
            for tradeDict in tradesData {
                guard let idString = tradeDict["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let coinSymbol = tradeDict["coinSymbol"] as? String,
                      let typeString = tradeDict["type"] as? String,
                      let amount = tradeDict["amount"] as? Double,
                      let price = tradeDict["price"] as? Double,
                      let timestamp = tradeDict["timestamp"] as? TimeInterval else {
                    continue
                }
                let tradeType: TradeType = typeString == "buy" ? .buy : .sell
                let coinName = (tradeDict["coinName"] as? String) ?? coinSymbol
                let trade = Trade(
                    id: id,
                    coinSymbol: coinSymbol,
                    coinName: coinName,
                    type: tradeType,
                    amount: amount,
                    price: price,
                    timestamp: Date(timeIntervalSince1970: timestamp)
                )
                importedTrades.append(trade)
            }
            if !importedTrades.isEmpty {
                dataManager.saveTrades(importedTrades)
            }
        }
        
        if let ordersData = importData["orders"] as? [[String: Any]] {
            var importedOrders: [Order] = []
            for orderDict in ordersData {
                guard let idString = orderDict["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let coinSymbol = orderDict["coinSymbol"] as? String,
                      let typeString = orderDict["type"] as? String,
                      let type = OrderType(rawValue: typeString),
                      let amount = orderDict["amount"] as? Double else {
                    continue
                }
                let limitPrice = orderDict["limitPrice"] as? Double
                let statusString = (orderDict["status"] as? String) ?? "pending"
                let status = OrderStatus(rawValue: statusString) ?? .pending
                let order = Order(
                    id: id,
                    coinSymbol: coinSymbol,
                    coinName: coinSymbol,
                    type: type,
                    amount: amount,
                    limitPrice: limitPrice,
                    status: status
                )
                importedOrders.append(order)
            }
            if !importedOrders.isEmpty {
                dataManager.saveOrders(importedOrders)
            }
        }
        
        if let journalData = importData["journalEntries"] as? [[String: Any]] {
            var importedEntries: [TradingJournalEntry] = []
            for entryDict in journalData {
                guard let idString = entryDict["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let tradeIdString = entryDict["tradeId"] as? String,
                      let tradeId = UUID(uuidString: tradeIdString),
                      let coinSymbol = entryDict["coinSymbol"] as? String else {
                    continue
                }
                let entry = TradingJournalEntry(
                    id: id,
                    tradeId: tradeId,
                    coinSymbol: coinSymbol,
                    notes: (entryDict["notes"] as? String) ?? "",
                    rating: (entryDict["rating"] as? Int) ?? 3
                )
                importedEntries.append(entry)
            }
            if !importedEntries.isEmpty {
                dataManager.saveJournalEntries(importedEntries)
            }
        }
        
        if let alertsData = importData["priceAlerts"] as? [[String: Any]] {
            var importedAlerts: [PriceAlert] = []
            for alertDict in alertsData {
                guard let idString = alertDict["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let coinSymbol = alertDict["coinSymbol"] as? String,
                      let targetPrice = alertDict["targetPrice"] as? Double,
                      let conditionString = alertDict["condition"] as? String,
                      let condition = AlertCondition(rawValue: conditionString) else {
                    continue
                }
                let isActive = (alertDict["isActive"] as? Bool) ?? true
                let alert = PriceAlert(
                    id: id,
                    coinSymbol: coinSymbol,
                    coinName: coinSymbol,
                    targetPrice: targetPrice,
                    condition: condition,
                    isActive: isActive
                )
                importedAlerts.append(alert)
            }
            if !importedAlerts.isEmpty {
                dataManager.savePriceAlerts(importedAlerts)
            }
        }
        
        if let snapshotsData = importData["portfolioSnapshots"] as? [[String: Any]] {
            var importedSnapshots: [PortfolioSnapshot] = []
            for snapDict in snapshotsData {
                guard let dateTimestamp = snapDict["date"] as? TimeInterval,
                      let totalValue = snapDict["totalValue"] as? Double,
                      let profit = snapDict["profit"] as? Double else {
                    continue
                }
                let snapshot = PortfolioSnapshot(
                    date: Date(timeIntervalSince1970: dateTimestamp),
                    totalValue: totalValue,
                    profit: profit
                )
                importedSnapshots.append(snapshot)
            }
            if !importedSnapshots.isEmpty {
                dataManager.savePortfolioSnapshots(importedSnapshots)
            }
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

