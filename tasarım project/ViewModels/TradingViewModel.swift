//
//  TradingViewModel.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation

class TradingViewModel: ObservableObject {
    @Published var user: User
    @Published var trades: [Trade] = []
    @Published var orders: [Order] = []
    @Published var journalEntries: [TradingJournalEntry] = []
    @Published var portfolioSnapshots: [PortfolioSnapshot] = []
    @Published var priceAlerts: [PriceAlert] = []
    @Published var selectedCoin: Coin?
    @Published var tradeAmount: String = ""
    @Published var showTradeSheet = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let dataManager = DataManager.shared
    private let errorHandler = ErrorHandler.shared
    weak var learningViewModel: LearningViewModel?
    
    init() {
        self.user = dataManager.loadUser()
        self.trades = dataManager.loadTrades()
        self.orders = dataManager.loadOrders()
        self.journalEntries = dataManager.loadJournalEntries()
        self.portfolioSnapshots = dataManager.loadPortfolioSnapshots()
        self.priceAlerts = dataManager.loadPriceAlerts()
        updatePortfolioValues()
        checkPendingOrders()
        savePortfolioSnapshot()
        checkPriceAlerts()
        
        priceUpdateObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("CoinPricesUpdated"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.checkPendingOrders()
        }
    }
    
    private var priceUpdateObserver: NSObjectProtocol?
    
    deinit {
        if let observer = priceUpdateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    @discardableResult
    func buyCoin(_ coin: Coin, amount: Double, price: Double, stopLoss: Double? = nil) -> Bool {
        guard amount > 0 else {
            errorHandler.handle(.invalidAmount)
            return false
        }
        
        let totalCost = amount * price
        
        // Validate balance
        switch ValidationHelper.validateBalance(totalCost, available: user.balance) {
        case .failure(let error):
            errorHandler.handle(error)
            return false
        case .success:
            break
        }
        
        if let stopLoss = stopLoss, stopLoss > 0 {
            switch ValidationHelper.validateStopLoss(stopLoss, buyPrice: price) {
            case .failure(let error):
                errorHandler.handle(error)
                return false
            case .success:
                break
            }
        }
        
        user.balance -= totalCost
        
        if let existingAmount = user.portfolio[coin.symbol] {
            user.portfolio[coin.symbol] = existingAmount + amount
        } else {
            user.portfolio[coin.symbol] = amount
        }
        
        if let stopLoss = stopLoss, stopLoss > 0 && stopLoss < price {
            user.stopLossLevels[coin.symbol] = stopLoss
        }
        
        let trade = Trade(
            id: UUID(),
            coinSymbol: coin.symbol,
            coinName: coin.name,
            type: .buy,
            amount: amount,
            price: price,
            timestamp: Date()
        )
        
        trades.insert(trade, at: 0)
        user.numberOfTrades += 1
        
        dataManager.saveUser(user)
        dataManager.saveTrades(trades)
        
        if CloudSyncService.shared.isAutoSyncEnabled {
            CloudSyncService.shared.syncToCloud()
        }
        
        checkAchievements()
        checkChallenges()
        checkStopLossTriggers()
        LeaderboardViewModel.shared.updateCurrentUserEntry()
        return true
    }
    
    @discardableResult
    func sellCoin(_ coin: Coin, amount: Double, price: Double) -> Bool {
        guard amount > 0 else {
            errorHandler.handle(.invalidAmount)
            return false
        }
        
        guard let currentAmount = user.portfolio[coin.symbol] else {
            errorHandler.handle(.insufficientCoins)
            return false
        }
        
        // Validate coin amount
        switch ValidationHelper.validateCoinAmount(amount, available: currentAmount) {
        case .failure(let error):
            errorHandler.handle(error)
            return false
        case .success:
            break
        }
        
        if currentAmount == amount {
            user.stopLossLevels.removeValue(forKey: coin.symbol)
        }
        
        let totalValue = amount * price
        user.balance += totalValue
        user.portfolio[coin.symbol] = currentAmount - amount
        
        if let updatedAmount = user.portfolio[coin.symbol],
           updatedAmount <= 0.0001 {
            user.portfolio.removeValue(forKey: coin.symbol)
        }
        
        let trade = Trade(
            id: UUID(),
            coinSymbol: coin.symbol,
            coinName: coin.name,
            type: .sell,
            amount: amount,
            price: price,
            timestamp: Date()
        )
        
        trades.insert(trade, at: 0)
        user.numberOfTrades += 1
        
        dataManager.saveUser(user)
        dataManager.saveTrades(trades)
        
        HapticFeedback.medium()
        checkAchievements()
        checkChallenges()
        return true
    }
    
    func checkChallenges() {
        // User'ı güncelle (trade sonrası değişiklikler için)
        user = dataManager.loadUser()
        
        // Eğer LearningViewModel referansı varsa onu kullan, yoksa yeni instance oluştur
        let learningVM = learningViewModel ?? LearningViewModel()
        learningVM.checkAllChallenges(user: user)
        
        // Challenge kontrolünden sonra user'ı tekrar yükle (XP eklenmiş olabilir)
        DispatchQueue.main.async {
            self.user = self.dataManager.loadUser()
            
            // LearningViewModel referansı varsa onu da refresh et
            if let learningVM = self.learningViewModel {
                learningVM.refreshUser()
            }
        }
    }
    
    func getPortfolioValue(for coin: Coin) -> Double {
        guard let amount = user.portfolio[coin.symbol] else {
            return 0.0
        }
        return amount * coin.price
    }
    
    func getPortfolioAmount(for coin: Coin) -> Double {
        return user.portfolio[coin.symbol] ?? 0.0
    }
    
    private func updatePortfolioValues() {
        // This can be used to update portfolio values based on current prices
        checkStopLossTriggers()
    }
    
    func checkStopLossTriggers() {
        // Check all coins with stop loss levels
        let coins = dataManager.coins
        for (coinSymbol, stopLossPrice) in user.stopLossLevels {
            // Find the coin in the current coin list
            if let coin = coins.first(where: { $0.symbol == coinSymbol }),
               let portfolioAmount = user.portfolio[coinSymbol],
               portfolioAmount > 0 {
                
                // If current price is at or below stop loss, trigger automatic sell
                if coin.price <= stopLossPrice {
                    // Auto sell at stop loss price
                    sellCoin(coin, amount: portfolioAmount, price: stopLossPrice)
                    
                    // Remove stop loss after selling
                    user.stopLossLevels.removeValue(forKey: coinSymbol)
                    dataManager.saveUser(user)
                }
            }
        }
    }
    
    func checkAchievements() {
        let achievements = dataManager.achievements
        
        // Check first trade achievement
        if user.numberOfTrades >= 1 && !user.unlockedAchievements.contains("first_trade") {
            if let achievement = achievements.first(where: { $0.id == "first_trade" }) {
                unlockAchievement(achievement.id)
            }
        }
        
        // Check progressive trader achievement
        if user.numberOfTrades >= 10 && !user.unlockedAchievements.contains("progressive_trader") {
            if let achievement = achievements.first(where: { $0.id == "progressive_trader" }) {
                unlockAchievement(achievement.id)
            }
        }
        
        // Check centurion achievement
        if user.numberOfTrades >= 100 && !user.unlockedAchievements.contains("centurion") {
            if let achievement = achievements.first(where: { $0.id == "centurion" }) {
                unlockAchievement(achievement.id)
            }
        }
        
        // Check diversifier achievement
        if user.portfolio.count >= 5 && !user.unlockedAchievements.contains("diversifier") {
            if let achievement = achievements.first(where: { $0.id == "diversifier" }) {
                unlockAchievement(achievement.id)
            }
        }
    }
    
    private func unlockAchievement(_ achievementId: String) {
        user.unlockedAchievements.append(achievementId)
        dataManager.saveUser(user)
        
        // Haptic feedback
        HapticFeedback.success()
        
        // Send notification if enabled
        if let achievement = dataManager.achievements.first(where: { $0.id == achievementId }),
           SettingsViewModel().settings.achievementNotificationEnabled {
            NotificationService.shared.sendAchievementNotification(
                title: "Başarım Kazanıldı! 🏆",
                body: achievement.title
            )
        }
    }
    
    func calculateTotalPortfolioValue(with coins: [Coin]) -> Double {
        var totalValue = user.balance
        
        for (symbol, amount) in user.portfolio {
            if let coin = coins.first(where: { $0.symbol == symbol }) {
                totalValue += amount * coin.price
            }
        }
        
        return totalValue
    }
    
    // MARK: - Orders Management
    
    func createLimitOrder(
        coin: Coin,
        amount: Double,
        limitPrice: Double,
        stopLoss: Double? = nil,
        takeProfit: Double? = nil,
        notes: String? = nil
    ) {
        guard amount > 0, limitPrice > 0 else {
            errorHandler.handle(.invalidAmount)
            return
        }
        
        let order = Order(
            coinSymbol: coin.symbol,
            coinName: coin.name,
            type: .limitBuy,
            amount: amount,
            limitPrice: limitPrice,
            stopLoss: stopLoss,
            takeProfit: takeProfit,
            notes: notes
        )
        
        orders.append(order)
        dataManager.saveOrders(orders)
        HapticFeedback.medium()
    }
    
    func cancelOrder(_ order: Order) {
        if let index = orders.firstIndex(where: { $0.id == order.id }) {
            orders[index].status = .cancelled
            dataManager.saveOrders(orders)
            HapticFeedback.light()
        }
    }
    
    func checkPendingOrders() {
        let coins = dataManager.coins
        
        for index in orders.indices where orders[index].status == .pending {
            let order = orders[index]
            
            guard let coin = coins.first(where: { $0.symbol == order.coinSymbol }) else {
                continue
            }
            
            // Check if limit price is reached
            if let limitPrice = order.limitPrice {
                let shouldExecute: Bool
                
                switch order.type {
                case .limitBuy:
                    shouldExecute = coin.price <= limitPrice
                case .limitSell:
                    shouldExecute = coin.price >= limitPrice
                default:
                    shouldExecute = false
                }
                
                if shouldExecute {
                    executeOrder(at: index, coin: coin, executionPrice: limitPrice)
                }
            }
        }
    }
    
    private func executeOrder(at index: Int, coin: Coin, executionPrice: Double) {
        let order = orders[index]
        
        var success = false
        switch order.type {
        case .limitBuy:
            success = buyCoin(coin, amount: order.amount, price: executionPrice, stopLoss: order.stopLoss)
        case .limitSell:
            success = sellCoin(coin, amount: order.amount, price: executionPrice)
        default:
            break
        }
        
        if success {
            orders[index].status = .executed
            orders[index].executedAt = Date()
        } else {
            orders[index].status = .failed
        }
        dataManager.saveOrders(orders)
    }
    
    // MARK: - Trading Statistics (cached)
    
    private var cachedStatistics: TradingStatistics?
    private var lastStatisticsTradeCount: Int = -1
    
    func getTradingStatistics() -> TradingStatistics {
        // Cache'den dondur eger trade sayisi degismediyse
        if let cached = cachedStatistics, lastStatisticsTradeCount == trades.count {
            return cached
        }
        let winningTrades = trades.filter { trade in
            if trade.type == .buy {
                // For buy trades, check if current price is higher
                if let coin = dataManager.coins.first(where: { $0.symbol == trade.coinSymbol }) {
                    return coin.price > trade.price
                }
            }
            return false
        }
        
        let losingTrades = trades.filter { trade in
            if trade.type == .buy {
                if let coin = dataManager.coins.first(where: { $0.symbol == trade.coinSymbol }) {
                    return coin.price < trade.price
                }
            }
            return false
        }
        
        let totalTrades = trades.count
        let winRate = totalTrades > 0 ? Double(winningTrades.count) / Double(totalTrades) * 100 : 0
        
        let totalProfit = calculateTotalProfit()
        
        // Kazanan trade'lerin ortalama karini hesapla
        let winProfit = winningTrades.reduce(0.0) { total, trade in
            if let coin = dataManager.coins.first(where: { $0.symbol == trade.coinSymbol }) {
                return total + (trade.amount * (coin.price - trade.price))
            }
            return total
        }
        let averageProfit = winningTrades.isEmpty ? 0 : winProfit / Double(winningTrades.count)
        
        // Kaybeden trade'lerin ortalama zararini hesapla
        let lossAmount = losingTrades.reduce(0.0) { total, trade in
            if let coin = dataManager.coins.first(where: { $0.symbol == trade.coinSymbol }) {
                return total + abs(trade.amount * (coin.price - trade.price))
            }
            return total
        }
        let averageLoss = losingTrades.isEmpty ? 0 : lossAmount / Double(losingTrades.count)
        
        let profitFactor = averageLoss > 0 ? averageProfit / averageLoss : (averageProfit > 0 ? Double.infinity : 0)
        
        let mostProfitableCoin = getMostProfitableCoin()
        
        let stats = TradingStatistics(
            totalTrades: totalTrades,
            winningTrades: winningTrades.count,
            losingTrades: losingTrades.count,
            winRate: winRate,
            totalProfit: totalProfit,
            averageProfit: averageProfit,
            profitFactor: profitFactor,
            mostProfitableCoin: mostProfitableCoin
        )
        
        // Cache'e kaydet
        cachedStatistics = stats
        lastStatisticsTradeCount = trades.count
        
        return stats
    }
    
    private func calculateTotalProfit() -> Double {
        var profit = 0.0
        
        for trade in trades where trade.type == .buy {
            if let coin = dataManager.coins.first(where: { $0.symbol == trade.coinSymbol }) {
                let currentValue = trade.amount * coin.price
                let tradeValue = trade.amount * trade.price
                profit += (currentValue - tradeValue)
            }
        }
        
        return profit
    }
    
    private func getMostProfitableCoin() -> String? {
        var coinProfits: [String: Double] = [:]
        
        for trade in trades where trade.type == .buy {
            if let coin = dataManager.coins.first(where: { $0.symbol == trade.coinSymbol }) {
                let currentValue = trade.amount * coin.price
                let tradeValue = trade.amount * trade.price
                let profit = currentValue - tradeValue
                
                coinProfits[trade.coinSymbol, default: 0] += profit
            }
        }
        
        return coinProfits.max(by: { $0.value < $1.value })?.key
    }
    
    // MARK: - Trading Journal
    
    func addJournalEntry(
        tradeId: UUID,
        coinSymbol: String,
        notes: String = "",
        strategy: String = "",
        emotions: String = "",
        lessonsLearned: String = "",
        rating: Int = 3
    ) {
        let entry = TradingJournalEntry(
            tradeId: tradeId,
            coinSymbol: coinSymbol,
            notes: notes,
            strategy: strategy,
            emotions: emotions,
            lessonsLearned: lessonsLearned,
            rating: rating
        )
        
        journalEntries.append(entry)
        dataManager.saveJournalEntries(journalEntries)
    }
    
    func getJournalEntry(for tradeId: UUID) -> TradingJournalEntry? {
        return journalEntries.first(where: { $0.tradeId == tradeId })
    }
    
    // MARK: - Portfolio Snapshots
    
    func savePortfolioSnapshot() {
        let totalValue = calculateTotalPortfolioValue(with: dataManager.coins)
        let profit = totalValue - 100000.0 // Starting balance
        
        let snapshot = PortfolioSnapshot(
            totalValue: totalValue,
            profit: profit
        )
        
        portfolioSnapshots.append(snapshot)
        
        // Keep only last 30 days of snapshots
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        portfolioSnapshots = portfolioSnapshots.filter { $0.date >= thirtyDaysAgo }
        
        dataManager.savePortfolioSnapshots(portfolioSnapshots)
    }
    
    // MARK: - Price Alerts
    
    func createPriceAlert(
        coin: Coin,
        targetPrice: Double,
        condition: AlertCondition
    ) {
        guard targetPrice > 0 else {
            errorHandler.handle(.invalidInput("Geçersiz fiyat"))
            return
        }
        
        let alert = PriceAlert(
            coinSymbol: coin.symbol,
            coinName: coin.name,
            targetPrice: targetPrice,
            condition: condition
        )
        
        priceAlerts.append(alert)
        dataManager.savePriceAlerts(priceAlerts)
        HapticFeedback.medium()
    }
    
    func deletePriceAlert(_ alert: PriceAlert) {
        priceAlerts.removeAll { $0.id == alert.id }
        dataManager.savePriceAlerts(priceAlerts)
    }
    
    func checkPriceAlerts() {
        let coins = dataManager.coins
        
        for index in priceAlerts.indices where priceAlerts[index].isActive {
            let alert = priceAlerts[index]
            
            guard let coin = coins.first(where: { $0.symbol == alert.coinSymbol }) else {
                continue
            }
            
            let shouldTrigger: Bool
            switch alert.condition {
            case .above:
                shouldTrigger = coin.price >= alert.targetPrice
            case .below:
                shouldTrigger = coin.price <= alert.targetPrice
            }
            
            if shouldTrigger {
                priceAlerts[index].isActive = false
                priceAlerts[index].triggeredAt = Date()
                dataManager.savePriceAlerts(priceAlerts)
                
                // Send notification
                if SettingsViewModel().settings.priceAlertEnabled {
                    let message = "\(alert.coinSymbol) fiyatı \(formatCurrency(alert.targetPrice)) seviyesine \(alert.condition == .above ? "ulaştı" : "düştü")!"
                    NotificationService.shared.sendAchievementNotification(
                        title: "Fiyat Alarmı 🔔",
                        body: message
                    )
                }
                
                HapticFeedback.warning()
            }
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
    
    // MARK: - Favorite Coins (Watchlist)
    
    func toggleFavorite(coinSymbol: String) {
        if user.favoriteCoins.contains(coinSymbol) {
            user.favoriteCoins.removeAll { $0 == coinSymbol }
            HapticFeedback.light()
        } else {
            user.favoriteCoins.append(coinSymbol)
            HapticFeedback.success()
        }
        dataManager.saveUser(user)
        
        // Sync to iCloud if enabled
        if CloudSyncService.shared.isAutoSyncEnabled {
            CloudSyncService.shared.syncToCloud()
        }
    }
    
    func isFavorite(coinSymbol: String) -> Bool {
        return user.favoriteCoins.contains(coinSymbol)
    }
    
    func getFavoriteCoins(from coins: [Coin]) -> [Coin] {
        return coins.filter { user.favoriteCoins.contains($0.symbol) }
    }
}

// MARK: - Trading Statistics Model

struct TradingStatistics {
    let totalTrades: Int
    let winningTrades: Int
    let losingTrades: Int
    let winRate: Double
    let totalProfit: Double
    let averageProfit: Double
    let profitFactor: Double
    let mostProfitableCoin: String?
}

