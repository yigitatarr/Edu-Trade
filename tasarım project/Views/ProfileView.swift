//
//  ProfileView.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import SwiftUI
import Charts

struct ProfileView: View {
    @ObservedObject var tradingVM: TradingViewModel
    @ObservedObject var learningVM: LearningViewModel
    @State private var showingResetAlert = false
    @State private var selectedTab = 0
    @StateObject private var settingsVM = SettingsViewModel()
    
    private var user: User {
        tradingVM.user
    }
    
    private var progress: UserProgress {
        user.progress
    }
    
    private var totalPortfolioValue: Double {
        tradingVM.calculateTotalPortfolioValue(with: DataManager.shared.coins)
    }
    
    private var totalProfit: Double {
        totalPortfolioValue - 100000.0 // Başlangıç bakiyesi
    }
    
    private var profitPercentage: Double {
        guard totalPortfolioValue > 0 else { return 0 }
        return (totalProfit / 100000.0) * 100
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Enhanced Profile Header
                    EnhancedProfileHeader(
                        userName: settingsVM.settings.userName,
                        balance: user.balance,
                        totalValue: totalPortfolioValue,
                        profit: totalProfit,
                        profitPercentage: profitPercentage,
                        progress: progress
                    )
                    
                    // Tab Selector
                    TabSelector(selectedTab: $selectedTab)
                        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenPortfolioTab"))) { _ in
                            // Portföy sekmesine geç (selectedTab == 2)
                            selectedTab = 2
                        }
                    
                    // Content based on selected tab
                    if selectedTab == 0 {
                        OverviewTab(tradingVM: tradingVM, learningVM: learningVM, progress: progress)
                    } else if selectedTab == 1 {
                        TradingTab(tradingVM: tradingVM, totalPortfolioValue: totalPortfolioValue)
                    } else if selectedTab == 2 {
                        PortfolioTab(tradingVM: tradingVM, totalPortfolioValue: totalPortfolioValue)
                    } else {
                        LearningTab(learningVM: learningVM, progress: progress)
                    }
                    
                    // Trading Statistics and Charts
                    VStack(spacing: 12) {
                        NavigationLink(destination: TradingStatisticsView(
                            viewModel: tradingVM,
                            statistics: tradingVM.getTradingStatistics()
                        )) {
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                Text("Trading İstatistikleri")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                            )
                        }
                        
                        NavigationLink(destination: PortfolioChartView(
                            snapshots: tradingVM.portfolioSnapshots
                        )) {
                            HStack {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                Text("Portföy Grafiği")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                            )
                        }
                        
                        NavigationLink(destination: AdvancedPortfolioAnalysisView(
                            tradingVM: tradingVM
                        )) {
                            HStack {
                                Image(systemName: "chart.bar.xaxis")
                                Text("Gelişmiş Portföy Analizi")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                            )
                        }
                        
                        NavigationLink(destination: LeaderboardView()) {
                            HStack {
                                Image(systemName: "trophy.fill")
                                Text("Liderlik Tablosu")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                            )
                        }
                        
                        NavigationLink(destination: PriceAlertsView(viewModel: tradingVM)) {
                            HStack {
                                Image(systemName: "bell.fill")
                                Text("Fiyat Alarmları")
                                Spacer()
                                if !tradingVM.priceAlerts.filter({ $0.isActive }).isEmpty {
                                    Text("\(tradingVM.priceAlerts.filter { $0.isActive }.count)")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(6)
                                        .background(Circle().fill(Color.red))
                                }
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                            )
                        }
                        
                        NavigationLink(destination: TradingJournalView(tradingVM: tradingVM)) {
                            HStack {
                                Image(systemName: "book.closed.fill")
                                Text("Trading Günlüğü")
                                Spacer()
                                if !tradingVM.journalEntries.isEmpty {
                                    Text("\(tradingVM.journalEntries.count)")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(6)
                                        .background(Circle().fill(Color.blue))
                                }
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                            )
                        }
                        
                        NavigationLink(destination: PendingOrdersView(tradingVM: tradingVM)) {
                            HStack {
                                Image(systemName: "list.bullet.rectangle")
                                Text("Limit Emirleri")
                                Spacer()
                                if !tradingVM.orders.filter({ $0.status == .pending }).isEmpty {
                                    Text("\(tradingVM.orders.filter { $0.status == .pending }.count)")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(6)
                                        .background(Circle().fill(Color.orange))
                                }
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Reset Button
                    ResetButton(showingResetAlert: $showingResetAlert)
                }
                .padding()
            }
            .navigationTitle(LocalizationHelper.shared.string(for: "nav.profile"))
            .accessibilitySupport()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView(
                        viewModel: settingsVM,
                        tradingVM: tradingVM,
                        learningVM: learningVM
                    )) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.blue)
                            .accessibilityLabel("Ayarlar")
                    }
                }
            }
            .alert("İlerlemeyi Sıfırla", isPresented: $showingResetAlert) {
                Button("İptal", role: .cancel) {}
                Button("Sıfırla", role: .destructive) {
                    resetProgress()
                }
            } message: {
                Text("Tüm ilerlemeni sıfırlamak istediğinden emin misin? Bu işlem geri alınamaz.")
            }
        }
    }
    
    private func resetProgress() {
        let user = User()
        tradingVM.user = user
        DataManager.shared.saveUser(user)
        DataManager.shared.saveTrades([])
        
        learningVM.completedLessons = []
        learningVM.quizResults = [:]
        let userDefaults = UserDefaults.standard
        userDefaults.set([], forKey: "completedLessons")
        userDefaults.set([:], forKey: "quizResults")
        
        tradingVM.trades = []
    }
}

// MARK: - Enhanced Profile Header
struct EnhancedProfileHeader: View {
    let userName: String
    let balance: Double
    let totalValue: Double
    let profit: Double
    let profitPercentage: Double
    let progress: UserProgress
    
    private var level: Int { progress.currentLevel }
    private var xp: Int { progress.totalXP }
    private var streak: Int { progress.streak }
    private var nextLevelXP: Int { level * 100 }
    private var levelProgress: Double { progress.levelProgress }
    
    var body: some View {
        VStack(spacing: 16) {
            // Avatar and Level Badge
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }
                
                // Level Badge
                ZStack {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 36, height: 36)
                    
                    Text("\(level)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(x: 8, y: 8)
            }
            
            // Name
            Text(userName)
                .font(.title2)
                .fontWeight(.bold)
            
            // Balance and Total Value
            VStack(spacing: 8) {
                VStack(spacing: 4) {
                    Text("Toplam Değer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatCurrency(totalValue))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Text(formatCurrency(profit))
                            .font(.headline)
                            .foregroundColor(profit >= 0 ? .green : .red)
                        
                        Text("(\(String(format: "%.2f", profitPercentage))%)")
                            .font(.headline)
                            .foregroundColor(profit >= 0 ? .green : .red)
                    }
                }
                
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("Nakit")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatCurrency(balance))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    VStack(spacing: 4) {
                        Text("Portföy")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatCurrency(totalValue - balance))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.top, 8)
            }
            
            // XP Progress Bar
            VStack(spacing: 8) {
                HStack {
                    Text("Seviye \(level)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(xp) XP")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * levelProgress, height: 8)
                    }
                }
                .frame(height: 8)
                
                HStack {
                    Text("Sonraki seviye: \(nextLevelXP - (xp % (level * 100))) XP")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Streak
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("\(streak) gün")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
    
    private func formatCurrency(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }
}

// MARK: - Tab Selector
struct TabSelector: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            ProfileTabButton(title: "Genel Bakış", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            
            ProfileTabButton(title: "Trading", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            
            ProfileTabButton(title: "Portföy", isSelected: selectedTab == 2) {
                selectedTab = 2
            }
            
            ProfileTabButton(title: "Öğrenme", isSelected: selectedTab == 3) {
                selectedTab = 3
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
    }
}

struct ProfileTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue)
                        }
                    }
                )
        }
    }
}

// MARK: - Overview Tab
struct OverviewTab: View {
    @ObservedObject var tradingVM: TradingViewModel
    @ObservedObject var learningVM: LearningViewModel
    let progress: UserProgress
    
    var body: some View {
        VStack(spacing: 20) {
            // Quick Stats Grid
            QuickStatsGrid(tradingVM: tradingVM, learningVM: learningVM, progress: progress)
            
            // Achievements Section
            AchievementsSection(tradingVM: tradingVM)
            
            // Recent Activity
            RecentActivitySection(tradingVM: tradingVM)
        }
    }
}

struct QuickStatsGrid: View {
    @ObservedObject var tradingVM: TradingViewModel
    @ObservedObject var learningVM: LearningViewModel
    let progress: UserProgress
    
    private var averageScore: Double {
        let scores = learningVM.quizResults.values
        guard !scores.isEmpty else { return 0 }
        return Double(scores.reduce(0, +)) / Double(scores.count)
    }
    
    private var totalLessons: Int {
        DataManager.shared.lessons.count
    }
    
    private var totalChallenges: Int {
        DataManager.shared.challenges.filter { $0.type == .practice }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hızlı İstatistikler")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ProfileStatItem(
                    title: "Toplam İşlem",
                    value: "\(tradingVM.user.numberOfTrades)",
                    icon: "arrow.left.arrow.right.circle.fill",
                    color: .blue
                )
                
                ProfileStatItem(
                    title: "Tamamlanan Quiz",
                    value: "\(learningVM.quizResults.count)",
                    icon: "brain.head.profile",
                    color: .purple
                )
                
                ProfileStatItem(
                    title: "Tamamlanan Ders",
                    value: "\(learningVM.completedLessons.count)/\(totalLessons)",
                    icon: "book.fill",
                    color: .green
                )
                
                ProfileStatItem(
                    title: "Ortalama Skor",
                    value: String(format: "%.0f%%", min(averageScore, 100)),
                    icon: "chart.bar.fill",
                    color: .orange
                )
                
                ProfileStatItem(
                    title: "Tamamlanan Görev",
                    value: "\(progress.completedChallenges.count)/\(totalChallenges)",
                    icon: "checkmark.circle.fill",
                    color: .teal
                )
                
                ProfileStatItem(
                    title: "Açılan Başarım",
                    value: "\(tradingVM.user.unlockedAchievements.count)",
                    icon: "star.fill",
                    color: .yellow
                )
            }
            .padding(.horizontal)
        }
    }
}

struct ProfileStatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }
}

struct RecentActivitySection: View {
    @ObservedObject var tradingVM: TradingViewModel
    
    private var recentTrades: [Trade] {
        Array(tradingVM.trades.suffix(5)).reversed()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Son İşlemler")
                .font(.headline)
                .padding(.horizontal)
            
            if recentTrades.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Henüz işlem yok")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal)
            } else {
                VStack(spacing: 8) {
                    ForEach(recentTrades) { trade in
                        ProfileRecentTradeRow(trade: trade)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct ProfileRecentTradeRow: View {
    let trade: Trade
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: trade.timestamp)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: trade.type == .buy ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .font(.title3)
                .foregroundColor(trade.type == .buy ? .green : .red)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(trade.type == .buy ? "Alış" : "Satış") - \(trade.coinSymbol)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.4f", trade.amount))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(formatCurrency(trade.price))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        )
    }
    
    private func formatCurrency(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }
}

// MARK: - Portfolio Tab
struct PortfolioTab: View {
    @ObservedObject var tradingVM: TradingViewModel
    let totalPortfolioValue: Double
    
    private let coins = DataManager.shared.coins
    
    private var portfolioCoins: [(Coin, Double, Double, Double)] {
        tradingVM.user.portfolio.compactMap { symbol, amount in
            guard let coin = coins.first(where: { $0.symbol == symbol }),
                  amount > 0 else { return nil }
            let currentValue = amount * coin.price
            let averagePrice = calculateAveragePrice(for: symbol)
            let profit = currentValue - (amount * averagePrice)
            let profitPercentage = averagePrice > 0 ? (profit / (amount * averagePrice)) * 100 : 0
            return (coin, amount, currentValue, profitPercentage)
        }.sorted { $0.2 > $1.2 } // Sort by value
    }
    
    private var totalProfit: Double {
        totalPortfolioValue - 100000.0
    }
    
    private var profitPercentage: Double {
        guard totalPortfolioValue > 0 else { return 0 }
        return (totalProfit / 100000.0) * 100
    }
    
    private var totalInvested: Double {
        portfolioCoins.reduce(0) { total, item in
            let (coin, amount, _, _) = item
            let avgPrice = calculateAveragePrice(for: coin.symbol)
            return total + (amount * avgPrice)
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Portfolio Summary Card
            PortfolioSummaryCard(
                totalValue: totalPortfolioValue,
                totalProfit: totalProfit,
                profitPercentage: profitPercentage,
                totalInvested: totalInvested,
                balance: tradingVM.user.balance
            )
            
            // Portfolio Distribution Chart
            if !portfolioCoins.isEmpty {
                PortfolioDistributionChart(
                    portfolioCoins: portfolioCoins.map { ($0.0.symbol, $0.1) },
                    coins: coins
                )
            }
            
            // Detailed Coin List
            if !portfolioCoins.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Coin Detayları")
                            .font(.system(size: 20, weight: .bold))
                        Spacer()
                        Text("\(portfolioCoins.count) coin")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    ForEach(portfolioCoins, id: \.0.id) { coin, amount, value, profitPercentage in
                        DetailedPortfolioItem(
                            coin: coin,
                            amount: amount,
                            value: value,
                            profitPercentage: profitPercentage,
                            averagePrice: calculateAveragePrice(for: coin.symbol),
                            tradingVM: tradingVM
                        )
                    }
                }
            } else {
                EmptyPortfolioView()
            }
            
            // Performance Metrics
            if !portfolioCoins.isEmpty {
                PortfolioPerformanceMetrics(
                    portfolioCoins: portfolioCoins,
                    totalValue: totalPortfolioValue,
                    totalInvested: totalInvested
                )
            }
        }
    }
    
    private func calculateAveragePrice(for symbol: String) -> Double {
        let coinTrades = tradingVM.trades.filter { $0.coinSymbol == symbol }
        guard !coinTrades.isEmpty else {
            // If no trades, use current price
            return coins.first(where: { $0.symbol == symbol })?.price ?? 0
        }
        
        var totalAmount: Double = 0
        var totalCost: Double = 0
        
        for trade in coinTrades.sorted(by: { $0.timestamp < $1.timestamp }) {
            if trade.type == .buy {
                totalAmount += trade.amount
                totalCost += trade.amount * trade.price
            } else {
                // For sells, reduce the amount proportionally
                let sellRatio = trade.amount / totalAmount
                totalAmount -= trade.amount
                totalCost -= totalCost * sellRatio
            }
        }
        
        return totalAmount > 0 ? totalCost / totalAmount : 0
    }
}

// MARK: - Trading Tab
struct TradingTab: View {
    @ObservedObject var tradingVM: TradingViewModel
    let totalPortfolioValue: Double
    
    private var portfolioCoins: [(String, Double)] {
        Array(tradingVM.user.portfolio.keys).compactMap { symbol in
            guard let amount = tradingVM.user.portfolio[symbol] else { return nil }
            return (symbol, amount)
        }
    }
    
    private var totalProfit: Double {
        totalPortfolioValue - 100000.0
    }
    
    private var winRate: Double {
        let buyTrades = tradingVM.trades.filter { $0.type == .buy }
        guard !buyTrades.isEmpty else { return 0 }
        let coins = DataManager.shared.coins
        let profitableTrades = buyTrades.filter { trade in
            guard let coin = coins.first(where: { $0.symbol == trade.coinSymbol }) else {
                return false
            }
            return coin.price > trade.price
        }
        return Double(profitableTrades.count) / Double(buyTrades.count) * 100
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Trading Performance
            TradingPerformanceCard(
                totalTrades: tradingVM.user.numberOfTrades,
                totalProfit: totalProfit,
                winRate: winRate,
                portfolioValue: totalPortfolioValue
            )
            
            // Portfolio Section
            PortfolioSection(viewModel: tradingVM)
            
            // Portfolio Distribution Chart
            if !portfolioCoins.isEmpty {
                PortfolioDistributionChart(
                    portfolioCoins: portfolioCoins,
                    coins: DataManager.shared.coins
                )
            }
        }
    }
}

struct TradingPerformanceCard: View {
    let totalTrades: Int
    let totalProfit: Double
    let winRate: Double
    let portfolioValue: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trading Performansı")
                .font(.headline)
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Toplam Kâr/Zarar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatCurrency(totalProfit))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(totalProfit >= 0 ? .green : .red)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Başarı Oranı")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f%%", winRate))
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Toplam İşlem")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(totalTrades)")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Portföy Değeri")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatCurrency(portfolioValue))
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
    
    private func formatCurrency(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }
}

struct PortfolioDistributionChart: View {
    let portfolioCoins: [(String, Double)]
    let coins: [Coin]
    
    private var chartData: [(String, Double)] {
        portfolioCoins.compactMap { symbol, amount in
            guard let coin = coins.first(where: { $0.symbol == symbol }) else { return nil }
            let value = amount * coin.price
            return (symbol, value)
        }.sorted { $0.1 > $1.1 }
    }
    
    private var totalValue: Double {
        chartData.reduce(0) { $0 + $1.1 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Portföy Dağılımı")
                .font(.headline)
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(chartData, id: \.0) { item in
                        SectorMark(
                            angle: .value("Değer", item.1),
                            innerRadius: .ratio(0.5),
                            angularInset: 2
                        )
                        .foregroundStyle(by: .value("Coin", item.0))
                        .annotation(position: .overlay) {
                            if item.1 / totalValue > 0.1 {
                                Text(item.0)
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .frame(height: 250)
            } else {
                // Fallback for iOS < 16
                VStack(spacing: 8) {
                    ForEach(chartData, id: \.0) { item in
                        HStack {
                            Text(item.0)
                                .font(.subheadline)
                                .frame(width: 60, alignment: .leading)
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(.systemGray5))
                                        .frame(height: 20)
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.blue)
                                        .frame(width: geometry.size.width * (item.1 / totalValue), height: 20)
                                }
                            }
                            .frame(height: 20)
                            
                            Text(String(format: "%.1f%%", (item.1 / totalValue) * 100))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 50, alignment: .trailing)
                        }
                    }
                }
                .padding()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
}

// MARK: - Learning Tab
struct LearningTab: View {
    @ObservedObject var learningVM: LearningViewModel
    let progress: UserProgress
    
    private var totalLessons: Int {
        DataManager.shared.lessons.count
    }
    
    private var totalQuizzes: Int {
        DataManager.shared.quizzes.count
    }
    
    private var completedChallenges: Int {
        progress.completedChallenges.count
    }
    
    private var totalChallenges: Int {
        DataManager.shared.challenges.filter { $0.type == .practice }.count
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Learning Progress
            LearningProgressCard(
                completedLessons: learningVM.completedLessons.count,
                totalLessons: totalLessons,
                completedQuizzes: learningVM.quizResults.count,
                totalQuizzes: totalQuizzes,
                completedChallenges: completedChallenges,
                totalChallenges: totalChallenges,
                averageScore: averageScore
            )
            
            // Level Progress
            LevelProgressCard(progress: progress)
            
            // Completed Levels
            CompletedLevelsSection(progress: progress)
        }
    }
    
    private var averageScore: Double {
        let scores = learningVM.quizResults.values
        guard !scores.isEmpty else { return 0 }
        return Double(scores.reduce(0, +)) / Double(scores.count)
    }
}

struct LearningProgressCard: View {
    let completedLessons: Int
    let totalLessons: Int
    let completedQuizzes: Int
    let totalQuizzes: Int
    let completedChallenges: Int
    let totalChallenges: Int
    let averageScore: Double
    
    private var lessonProgress: Double {
        guard totalLessons > 0 else { return 0 }
        return Double(completedLessons) / Double(totalLessons)
    }
    
    private var quizProgress: Double {
        guard totalQuizzes > 0 else { return 0 }
        return Double(completedQuizzes) / Double(totalQuizzes)
    }
    
    private var challengeProgress: Double {
        guard totalChallenges > 0 else { return 0 }
        return Double(completedChallenges) / Double(totalChallenges)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Öğrenme İlerlemesi")
                .font(.headline)
            
            VStack(spacing: 16) {
                ProgressRow(
                    title: "Dersler",
                    completed: completedLessons,
                    total: totalLessons,
                    progress: lessonProgress,
                    icon: "book.fill",
                    color: .blue
                )
                
                ProgressRow(
                    title: "Quiz'ler",
                    completed: completedQuizzes,
                    total: totalQuizzes,
                    progress: quizProgress,
                    icon: "brain.head.profile",
                    color: .purple
                )
                
                ProgressRow(
                    title: "Görevler",
                    completed: completedChallenges,
                    total: totalChallenges,
                    progress: challengeProgress,
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                Divider()
                
                HStack {
                    Text("Ortalama Quiz Skoru")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(String(format: "%.0f%%", min(averageScore, 100)))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
}

struct ProgressRow: View {
    let title: String
    let completed: Int
    let total: Int
    let progress: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.subheadline)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(completed)/\(total)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

struct LevelProgressCard: View {
    let progress: UserProgress
    
    private var nextLevelXP: Int {
        progress.currentLevel * 100
    }
    
    private var currentLevelXP: Int {
        progress.totalXP % (progress.currentLevel * 100)
    }
    
    private var levelProgress: Double {
        guard nextLevelXP > 0 else { return 0 }
        return Double(currentLevelXP) / Double(nextLevelXP)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Seviye İlerlemesi")
                .font(.headline)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Seviye \(progress.currentLevel)")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Text("\(progress.totalXP) XP")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                            .frame(height: 12)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * levelProgress, height: 12)
                    }
                }
                .frame(height: 12)
                
                HStack {
                    Text("\(currentLevelXP) / \(nextLevelXP) XP")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Sonraki seviye için \(nextLevelXP - currentLevelXP) XP gerekli")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
}

struct CompletedLevelsSection: View {
    let progress: UserProgress
    
    private var levels: [Level] {
        DataManager.shared.levels.sorted { $0.number < $1.number }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tamamlanan Seviyeler")
                .font(.headline)
            
            if progress.completedLevels.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Henüz seviye tamamlanmadı")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(levels.filter { progress.completedLevels.contains($0.id) }) { level in
                            LevelBadge(level: level)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct LevelBadge: View {
    let level: Level
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: level.icon)
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            Text(level.title)
                .font(.caption)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 80)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Existing Components (kept for compatibility)
struct AchievementsSection: View {
    @ObservedObject var tradingVM: TradingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Başarımlar")
                .font(.headline)
                .padding(.horizontal)
            
            if tradingVM.user.unlockedAchievements.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "star.circle")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("Henüz başarım yok")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Görevleri tamamlayarak başarımları aç!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(tradingVM.user.unlockedAchievements, id: \.self) { achievementId in
                            if let achievement = DataManager.shared.achievements.first(where: { $0.id == achievementId }) {
                                AchievementBadge(achievement: achievement, isUnlocked: true)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct AchievementBadge: View {
    let achievement: Achievement
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? Color.orange.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundColor(isUnlocked ? .orange : .gray)
            }
            
            Text(achievement.title)
                .font(.caption)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 80)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isUnlocked ? Color.orange.opacity(0.1) : Color(.systemBackground))
        )
    }
}

struct PortfolioSection: View {
    @ObservedObject var viewModel: TradingViewModel
    
    private let coins = DataManager.shared.coins
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Portföyüm")
                .font(.headline)
                .padding(.horizontal)
            
            if viewModel.user.portfolio.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "wallet.pass.fill")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("Portföyün boş")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.user.portfolio.keys), id: \.self) { symbol in
                        if let amount = viewModel.user.portfolio[symbol],
                           let coin = coins.first(where: { $0.symbol == symbol }) {
                            PortfolioItem(coin: coin, amount: amount)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct PortfolioItem: View {
    let coin: Coin
    let amount: Double
    
    private var totalValue: Double {
        amount * coin.price
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "bitcoinsign.circle.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(coin.symbol)
                    .font(.headline)
                
                Text(coin.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatCurrency(totalValue))
                    .font(.headline)
                
                Text(String(format: "%.4f", amount))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private func formatCurrency(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }
}

// MARK: - Portfolio Summary Card
struct PortfolioSummaryCard: View {
    let totalValue: Double
    let totalProfit: Double
    let profitPercentage: Double
    let totalInvested: Double
    let balance: Double
    
    var body: some View {
        VStack(spacing: 16) {
            // Total Value
            VStack(spacing: 8) {
                Text("Toplam Portföy Değeri")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(formatCurrency(totalValue))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            Divider()
            
            // Profit/Loss
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Toplam Kâr/Zarar")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Text(formatCurrency(abs(totalProfit)))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(totalProfit >= 0 ? .green : .red)
                        
                        Text("(\(String(format: "%.2f", profitPercentage))%)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(totalProfit >= 0 ? .green : .red)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Nakit Bakiye")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text(formatCurrency(balance))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                }
            }
            
            // Invested Amount
            HStack {
                Text("Yatırılan Tutar")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer()
                Text(formatCurrency(totalInvested))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }
}

// MARK: - Detailed Portfolio Item
struct DetailedPortfolioItem: View {
    let coin: Coin
    let amount: Double
    let value: Double
    let profitPercentage: Double
    let averagePrice: Double
    @ObservedObject var tradingVM: TradingViewModel
    @State private var showingCoinDetail = false
    
    private var profit: Double {
        value - (amount * averagePrice)
    }
    
    private var portfolioPercentage: Double {
        let totalValue = tradingVM.calculateTotalPortfolioValue(with: DataManager.shared.coins)
        return totalValue > 0 ? (value / totalValue) * 100 : 0
    }
    
    var body: some View {
        Button(action: {
            showingCoinDetail = true
        }) {
            VStack(spacing: 12) {
                // Header
                HStack {
                    // Coin Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.15), Color.purple.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "bitcoinsign.circle.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    
                    // Coin Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(coin.symbol)
                            .font(.system(size: 18, weight: .bold))
                        
                        Text(coin.name)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Portfolio Percentage
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(String(format: "%.1f", portfolioPercentage))%")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.blue)
                        
                        Text("Portföy")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                // Value and Amount
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Değer")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text(formatCurrency(value))
                            .font(.system(size: 18, weight: .bold))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Miktar")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text(String(format: "%.4f", amount))
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                
                // Profit/Loss
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Kâr/Zarar")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        HStack(spacing: 4) {
                            Text(formatCurrency(abs(profit)))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(profit >= 0 ? .green : .red)
                            
                            Text("(\(String(format: "%.2f", profitPercentage))%)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(profit >= 0 ? .green : .red)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Ortalama Fiyat")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text(formatCurrency(averagePrice))
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                
                // Current Price
                HStack {
                    Text("Güncel Fiyat")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Spacer()
                    HStack(spacing: 4) {
                        Text(formatCurrency(coin.price))
                            .font(.system(size: 14, weight: .semibold))
                        
                        HStack(spacing: 2) {
                            Image(systemName: coin.change24h >= 0 ? "arrow.up" : "arrow.down")
                                .font(.system(size: 10))
                            Text("\(String(format: "%.2f", coin.change24h))%")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(coin.change24h >= 0 ? .green : .red)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingCoinDetail) {
            CoinDetailView(coin: coin, viewModel: tradingVM)
        }
        .padding(.horizontal)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }
}

// MARK: - Portfolio Performance Metrics
struct PortfolioPerformanceMetrics: View {
    let portfolioCoins: [(Coin, Double, Double, Double)]
    let totalValue: Double
    let totalInvested: Double
    
    private var bestPerformer: (Coin, Double, Double, Double)? {
        portfolioCoins.max(by: { $0.3 < $1.3 })
    }
    
    private var worstPerformer: (Coin, Double, Double, Double)? {
        portfolioCoins.min(by: { $0.3 < $1.3 })
    }
    
    private var totalReturn: Double {
        guard totalInvested > 0 else { return 0 }
        return ((totalValue - totalInvested) / totalInvested) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performans Metrikleri")
                .font(.system(size: 20, weight: .bold))
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                // Total Return
                MetricRow(
                    title: "Toplam Getiri",
                    value: "\(String(format: "%.2f", totalReturn))%",
                    color: totalReturn >= 0 ? .green : .red
                )
                
                Divider()
                
                // Best Performer
                if let best = bestPerformer {
                    MetricRow(
                        title: "En İyi Performans",
                        value: "\(best.0.symbol): \(String(format: "%.2f", best.3))%",
                        color: .green
                    )
                }
                
                // Worst Performer
                if let worst = worstPerformer {
                    MetricRow(
                        title: "En Düşük Performans",
                        value: "\(worst.0.symbol): \(String(format: "%.2f", worst.3))%",
                        color: .red
                    )
                }
                
                Divider()
                
                // Diversification
                let diversification = portfolioCoins.count
                MetricRow(
                    title: "Çeşitlendirme",
                    value: "\(diversification) farklı coin",
                    color: .blue
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
            .padding(.horizontal)
        }
    }
}

struct MetricRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
        }
    }
}

// MARK: - Empty Portfolio View
struct EmptyPortfolioView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wallet.pass.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Portföyün Boş")
                .font(.system(size: 20, weight: .bold))
            
            Text("Henüz coin satın almadınız. İşlem yaparak portföyünüzü oluşturmaya başlayın.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
    }
}

struct ResetButton: View {
    @Binding var showingResetAlert: Bool
    
    var body: some View {
        Button(action: { showingResetAlert = true }) {
            HStack {
                Image(systemName: "arrow.counterclockwise")
                Text("İlerlemeyi Sıfırla")
            }
            .font(.headline)
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
}

#Preview {
    ProfileView(tradingVM: TradingViewModel(), learningVM: LearningViewModel())
}
