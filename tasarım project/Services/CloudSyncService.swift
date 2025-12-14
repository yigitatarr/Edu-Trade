//
//  CloudSyncService.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation
import Combine

class CloudSyncService: ObservableObject {
    static let shared = CloudSyncService()
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    
    private let cloudStore = NSUbiquitousKeyValueStore.default
    private let dataManager = DataManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Listen for cloud updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(cloudStoreDidChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloudStore
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Sync Methods
    
    func syncToCloud() {
        guard !isSyncing else { return }
        
        isSyncing = true
        syncError = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                // Sync user data
                let user = self.dataManager.loadUser()
                if let userData = try? JSONEncoder().encode(user) {
                    self.cloudStore.set(userData, forKey: "user")
                }
                
                // Sync trades
                let trades = self.dataManager.loadTrades()
                if let tradesData = try? JSONEncoder().encode(trades) {
                    self.cloudStore.set(tradesData, forKey: "trades")
                }
                
                // Sync orders
                let orders = self.dataManager.loadOrders()
                if let ordersData = try? JSONEncoder().encode(orders) {
                    self.cloudStore.set(ordersData, forKey: "orders")
                }
                
                // Sync journal entries
                let journalEntries = self.dataManager.loadJournalEntries()
                if let journalData = try? JSONEncoder().encode(journalEntries) {
                    self.cloudStore.set(journalData, forKey: "journalEntries")
                }
                
                // Sync portfolio snapshots
                let snapshots = self.dataManager.loadPortfolioSnapshots()
                if let snapshotsData = try? JSONEncoder().encode(snapshots) {
                    self.cloudStore.set(snapshotsData, forKey: "portfolioSnapshots")
                }
                
                // Sync price alerts
                let alerts = self.dataManager.loadPriceAlerts()
                if let alertsData = try? JSONEncoder().encode(alerts) {
                    self.cloudStore.set(alertsData, forKey: "priceAlerts")
                }
                
                // Sync learning progress
                let userDefaults = UserDefaults.standard
                if let completedLessons = userDefaults.array(forKey: "completedLessons") as? [String] {
                    self.cloudStore.set(completedLessons, forKey: "completedLessons")
                }
                if let quizResults = userDefaults.dictionary(forKey: "quizResults") as? [String: Int] {
                    self.cloudStore.set(quizResults, forKey: "quizResults")
                }
                
                // Sync favorite coins
                self.cloudStore.set(user.favoriteCoins, forKey: "favoriteCoins")
                
                // Sync timestamp
                self.cloudStore.set(Date().timeIntervalSince1970, forKey: "lastSyncTimestamp")
                
                self.cloudStore.synchronize()
                
                DispatchQueue.main.async {
                    self.lastSyncDate = Date()
                    self.isSyncing = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.syncError = "Yedekleme hatası: \(error.localizedDescription)"
                    self.isSyncing = false
                }
            }
        }
    }
    
    func syncFromCloud() {
        guard !isSyncing else { return }
        
        isSyncing = true
        syncError = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                // Check if cloud data exists
                guard let lastSyncTimestamp = self.cloudStore.object(forKey: "lastSyncTimestamp") as? TimeInterval else {
                    DispatchQueue.main.async {
                        self.isSyncing = false
                    }
                    return
                }
                
                let cloudSyncDate = Date(timeIntervalSince1970: lastSyncTimestamp)
                let localSyncDate = UserDefaults.standard.object(forKey: "lastLocalSyncDate") as? Date
                
                // Use cloud data if it's newer
                if localSyncDate == nil || cloudSyncDate > localSyncDate! {
                    // Restore user
                    if let userData = self.cloudStore.data(forKey: "user"),
                       let user = try? JSONDecoder().decode(User.self, from: userData) {
                        self.dataManager.saveUser(user)
                    }
                    
                    // Restore trades
                    if let tradesData = self.cloudStore.data(forKey: "trades"),
                       let trades = try? JSONDecoder().decode([Trade].self, from: tradesData) {
                        self.dataManager.saveTrades(trades)
                    }
                    
                    // Restore orders
                    if let ordersData = self.cloudStore.data(forKey: "orders"),
                       let orders = try? JSONDecoder().decode([Order].self, from: ordersData) {
                        self.dataManager.saveOrders(orders)
                    }
                    
                    // Restore journal entries
                    if let journalData = self.cloudStore.data(forKey: "journalEntries"),
                       let journalEntries = try? JSONDecoder().decode([TradingJournalEntry].self, from: journalData) {
                        self.dataManager.saveJournalEntries(journalEntries)
                    }
                    
                    // Restore portfolio snapshots
                    if let snapshotsData = self.cloudStore.data(forKey: "portfolioSnapshots"),
                       let snapshots = try? JSONDecoder().decode([PortfolioSnapshot].self, from: snapshotsData) {
                        self.dataManager.savePortfolioSnapshots(snapshots)
                    }
                    
                    // Restore price alerts
                    if let alertsData = self.cloudStore.data(forKey: "priceAlerts"),
                       let alerts = try? JSONDecoder().decode([PriceAlert].self, from: alertsData) {
                        self.dataManager.savePriceAlerts(alerts)
                    }
                    
                    // Restore learning progress
                    let userDefaults = UserDefaults.standard
                    if let completedLessons = self.cloudStore.array(forKey: "completedLessons") as? [String] {
                        userDefaults.set(completedLessons, forKey: "completedLessons")
                    }
                    if let quizResults = self.cloudStore.dictionary(forKey: "quizResults") as? [String: Int] {
                        userDefaults.set(quizResults, forKey: "quizResults")
                    }
                    
                    // Restore favorite coins
                    if let favoriteCoins = self.cloudStore.array(forKey: "favoriteCoins") as? [String] {
                        var user = self.dataManager.loadUser()
                        user.favoriteCoins = favoriteCoins
                        self.dataManager.saveUser(user)
                    }
                    
                    userDefaults.set(Date(), forKey: "lastLocalSyncDate")
                }
                
                DispatchQueue.main.async {
                    self.lastSyncDate = cloudSyncDate
                    self.isSyncing = false
                    
                    // Notify that data was synced
                    NotificationCenter.default.post(name: NSNotification.Name("DataSyncedFromCloud"), object: nil)
                }
            } catch {
                DispatchQueue.main.async {
                    self.syncError = "Geri yükleme hatası: \(error.localizedDescription)"
                    self.isSyncing = false
                }
            }
        }
    }
    
    @objc private func cloudStoreDidChange(_ notification: Notification) {
        // Cloud data changed externally, sync from cloud
        syncFromCloud()
    }
    
    // MARK: - Auto Sync
    
    func startAutoSync() {
        // Sync on app launch
        syncFromCloud()
        
        // Sync every 5 minutes
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.syncToCloud()
        }
    }
    
    func enableAutoSync(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "autoSyncEnabled")
        if enabled {
            startAutoSync()
        }
    }
    
    var isAutoSyncEnabled: Bool {
        UserDefaults.standard.bool(forKey: "autoSyncEnabled")
    }
}

