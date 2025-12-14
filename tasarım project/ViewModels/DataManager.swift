//
//  DataManager.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation
import Combine

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var coins: [Coin] = []
    @Published var lessons: [Lesson] = []
    @Published var quizzes: [Quiz] = []
    @Published var achievements: [Achievement] = []
    @Published var levels: [Level] = []
    @Published var challenges: [Challenge] = []
    
    private let userDefaults = UserDefaults.standard
    private let priceService = CoinPriceService.shared
    
    private init() {
        loadData()
        // Start price updates
        priceService.startAutoUpdate()
    }
    
    func loadData() {
        loadCoins()
        loadLessons()
        loadQuizzes()
        loadAchievements()
        loadLevels()
        loadChallenges()
    }
    
    private func loadCoins() {
        guard let url = Bundle.main.url(forResource: "coins", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let coins = try? JSONDecoder().decode([Coin].self, from: data) else {
            return
        }
        self.coins = coins
    }
    
    private func loadLessons() {
        guard let url = Bundle.main.url(forResource: "learnData", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let lessons = try? JSONDecoder().decode([Lesson].self, from: data) else {
            return
        }
        self.lessons = lessons
    }
    
    private func loadQuizzes() {
        guard let url = Bundle.main.url(forResource: "quizData", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let quizzes = try? JSONDecoder().decode([Quiz].self, from: data) else {
            return
        }
        self.quizzes = quizzes
    }
    
    private func loadAchievements() {
        guard let url = Bundle.main.url(forResource: "achievements", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let achievements = try? JSONDecoder().decode([Achievement].self, from: data) else {
            return
        }
        self.achievements = achievements
    }
    
    private func loadLevels() {
        guard let url = Bundle.main.url(forResource: "levels", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let levels = try? JSONDecoder().decode([Level].self, from: data) else {
            return
        }
        self.levels = levels.sorted { $0.number < $1.number }
    }
    
    private func loadChallenges() {
        guard let url = Bundle.main.url(forResource: "challenges", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let challenges = try? JSONDecoder().decode([Challenge].self, from: data) else {
            return
        }
        self.challenges = challenges
    }
    
    // MARK: - User Persistence
    
    func saveUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            userDefaults.set(encoded, forKey: "user")
        }
    }
    
    func loadUser() -> User {
        guard let data = userDefaults.data(forKey: "user"),
              let user = try? JSONDecoder().decode(User.self, from: data) else {
            return User()
        }
        return user
    }
    
    // MARK: - Trades Persistence
    
    func saveTrades(_ trades: [Trade]) {
        if let encoded = try? JSONEncoder().encode(trades) {
            userDefaults.set(encoded, forKey: "trades")
        }
    }
    
    func loadTrades() -> [Trade] {
        guard let data = userDefaults.data(forKey: "trades"),
              let trades = try? JSONDecoder().decode([Trade].self, from: data) else {
            return []
        }
        return trades
    }
    
    // MARK: - Orders Persistence
    
    func saveOrders(_ orders: [Order]) {
        if let encoded = try? JSONEncoder().encode(orders) {
            userDefaults.set(encoded, forKey: "orders")
        }
    }
    
    func loadOrders() -> [Order] {
        guard let data = userDefaults.data(forKey: "orders"),
              let orders = try? JSONDecoder().decode([Order].self, from: data) else {
            return []
        }
        return orders
    }
    
    // MARK: - Trading Journal Persistence
    
    func saveJournalEntries(_ entries: [TradingJournalEntry]) {
        if let encoded = try? JSONEncoder().encode(entries) {
            userDefaults.set(encoded, forKey: "journalEntries")
        }
    }
    
    func loadJournalEntries() -> [TradingJournalEntry] {
        guard let data = userDefaults.data(forKey: "journalEntries"),
              let entries = try? JSONDecoder().decode([TradingJournalEntry].self, from: data) else {
            return []
        }
        return entries
    }
    
    // MARK: - Portfolio Snapshots Persistence
    
    func savePortfolioSnapshots(_ snapshots: [PortfolioSnapshot]) {
        if let encoded = try? JSONEncoder().encode(snapshots) {
            userDefaults.set(encoded, forKey: "portfolioSnapshots")
        }
    }
    
    func loadPortfolioSnapshots() -> [PortfolioSnapshot] {
        guard let data = userDefaults.data(forKey: "portfolioSnapshots"),
              let snapshots = try? JSONDecoder().decode([PortfolioSnapshot].self, from: data) else {
            return []
        }
        return snapshots
    }
    
    // MARK: - Price Alerts Persistence
    
    func savePriceAlerts(_ alerts: [PriceAlert]) {
        if let encoded = try? JSONEncoder().encode(alerts) {
            userDefaults.set(encoded, forKey: "priceAlerts")
        }
    }
    
    func loadPriceAlerts() -> [PriceAlert] {
        guard let data = userDefaults.data(forKey: "priceAlerts"),
              let alerts = try? JSONDecoder().decode([PriceAlert].self, from: data) else {
            return []
        }
        return alerts
    }
}


