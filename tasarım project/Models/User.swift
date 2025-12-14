//
//  User.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation

struct User: Codable {
    var balance: Double
    var totalQuizScore: Int
    var numberOfTrades: Int
    var portfolio: [String: Double] // [coinSymbol: amount]
    var unlockedAchievements: [String]
    var progress: UserProgress
    var stopLossLevels: [String: Double] // [coinSymbol: stopLossPrice]
    var favoriteCoins: [String] // [coinSymbol] - Watchlist
    
    init() {
        self.balance = 100000.0 // Starting balance
        self.totalQuizScore = 0
        self.numberOfTrades = 0
        self.portfolio = [:]
        self.unlockedAchievements = []
        self.progress = UserProgress()
        self.stopLossLevels = [:]
        self.favoriteCoins = []
    }
    
    var totalPortfolioValue: Double {
        // This will be calculated based on current coin prices
        // Note: This requires access to current coin prices, so it's better to calculate in ViewModel
        // This is kept for backward compatibility but should use TradingViewModel.calculateTotalPortfolioValue instead
        return 0.0
    }
}


