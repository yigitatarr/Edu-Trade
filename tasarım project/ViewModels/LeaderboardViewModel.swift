//
//  LeaderboardViewModel.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation
import Combine

class LeaderboardViewModel: ObservableObject {
    static let shared = LeaderboardViewModel()
    
    @Published var entries: [LeaderboardEntry] = []
    @Published var currentUserEntry: LeaderboardEntry?
    @Published var sortOption: LeaderboardSortOption = .xp
    @Published var isLoading = false
    
    private let dataManager = DataManager.shared
    private let userDefaults = UserDefaults.standard
    private let leaderboardKey = "leaderboardEntries"
    
    private init() {
        loadLeaderboard()
        updateCurrentUserEntry()
    }
    
    // MARK: - Load & Save
    
    func loadLeaderboard() {
        guard let data = userDefaults.data(forKey: leaderboardKey),
              let entries = try? JSONDecoder().decode([LeaderboardEntry].self, from: data) else {
            // Initialize with demo entries if empty
            initializeDemoLeaderboard()
            return
        }
        self.entries = entries
        sortLeaderboard()
    }
    
    func saveLeaderboard() {
        if let encoded = try? JSONEncoder().encode(entries) {
            userDefaults.set(encoded, forKey: leaderboardKey)
        }
    }
    
    // MARK: - Update Current User
    
    func updateCurrentUserEntry() {
        let user = dataManager.loadUser()
        let trades = dataManager.loadTrades()
        
        // Calculate win rate
        let winningTrades = trades.filter { trade in
            if trade.type == .buy {
                if let coin = dataManager.coins.first(where: { $0.symbol == trade.coinSymbol }) {
                    return coin.price > trade.price
                }
            }
            return false
        }
        let winRate = trades.isEmpty ? 0 : Double(winningTrades.count) / Double(trades.count) * 100
        
        // Calculate total profit
        var totalProfit = 0.0
        for trade in trades where trade.type == .buy {
            if let coin = dataManager.coins.first(where: { $0.symbol == trade.coinSymbol }) {
                let currentValue = trade.amount * coin.price
                let tradeValue = trade.amount * trade.price
                totalProfit += (currentValue - tradeValue)
            }
        }
        
        let entry = LeaderboardEntry(
            userName: SettingsViewModel().settings.userName,
            totalXP: user.progress.totalXP,
            totalProfit: totalProfit,
            winRate: winRate,
            totalTrades: user.numberOfTrades,
            level: user.progress.currentLevel,
            streak: user.progress.streak
        )
        
        // Update or add entry
        if let index = entries.firstIndex(where: { $0.userName == entry.userName }) {
            entries[index] = entry
        } else {
            entries.append(entry)
        }
        
        currentUserEntry = entry
        sortLeaderboard()
        saveLeaderboard()
    }
    
    // MARK: - Sort
    
    func sortLeaderboard() {
        entries.sort { entry1, entry2 in
            switch sortOption {
            case .xp:
                return entry1.totalXP > entry2.totalXP
            case .profit:
                return entry1.totalProfit > entry2.totalProfit
            case .winRate:
                return entry1.winRate > entry2.winRate
            case .trades:
                return entry1.totalTrades > entry2.totalTrades
            case .level:
                return entry1.level > entry2.level
            case .streak:
                return entry1.streak > entry2.streak
            }
        }
        
        // Update ranks
        for index in entries.indices {
            entries[index].rank = index + 1
        }
    }
    
    // MARK: - Demo Data
    
    private func initializeDemoLeaderboard() {
        entries = [
            LeaderboardEntry(
                userName: "CryptoMaster",
                totalXP: 5000,
                totalProfit: 25000.0,
                winRate: 75.5,
                totalTrades: 150,
                level: 15,
                streak: 30
            ),
            LeaderboardEntry(
                userName: "TradingPro",
                totalXP: 4500,
                totalProfit: 20000.0,
                winRate: 72.0,
                totalTrades: 120,
                level: 12,
                streak: 25
            ),
            LeaderboardEntry(
                userName: "CoinHunter",
                totalXP: 4000,
                totalProfit: 18000.0,
                winRate: 68.5,
                totalTrades: 100,
                level: 10,
                streak: 20
            ),
            LeaderboardEntry(
                userName: "BlockchainGuru",
                totalXP: 3500,
                totalProfit: 15000.0,
                winRate: 65.0,
                totalTrades: 80,
                level: 8,
                streak: 15
            ),
            LeaderboardEntry(
                userName: "DeFiExpert",
                totalXP: 3000,
                totalProfit: 12000.0,
                winRate: 62.5,
                totalTrades: 60,
                level: 6,
                streak: 10
            )
        ]
        sortLeaderboard()
        saveLeaderboard()
    }
}

