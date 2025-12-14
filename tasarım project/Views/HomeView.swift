//
//  HomeView.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var tradingVM: TradingViewModel
    @ObservedObject var learningVM: LearningViewModel
    @ObservedObject var offlineService = OfflineService.shared
    @EnvironmentObject var localizationHelper: LocalizationHelper
    @State private var selectedTab = 0
    
    // Helper to get localization helper (fallback to shared if needed)
    private var locHelper: LocalizationHelper {
        return localizationHelper
    }
    
    init() {
        // ViewModel'leri oluştur ve birbirlerine bağla
        let learningVM = LearningViewModel()
        let tradingVM = TradingViewModel()
        tradingVM.learningViewModel = learningVM
        
        self._tradingVM = ObservedObject(wrappedValue: tradingVM)
        self._learningVM = ObservedObject(wrappedValue: learningVM)
    }
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        Group {
            if DeviceHelper.isIPad && horizontalSizeClass == .regular {
                // iPad layout with sidebar
                iPadLayout
            } else {
                // iPhone layout with TabView
                iPhoneLayout
            }
        }
    }
    
    private var iPhoneLayout: some View {
        TabView(selection: $selectedTab) {
            DashboardView(tradingVM: tradingVM, learningVM: learningVM, selectedTab: $selectedTab)
                .tabItem {
                    Label(locHelper.string(for: "nav.home"), systemImage: "house.fill")
                }
                .tag(0)
                .onAppear {
                    learningVM.refreshUser()
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToTab"))) { notification in
                    if let tabIndex = notification.object as? Int {
                        selectedTab = tabIndex
                    }
                }
            
            TradeView(viewModel: tradingVM)
                .tabItem {
                    Label("İşlem", systemImage: "dollarsign.circle.fill")
                }
                .tag(1)
            
            LearnView(viewModel: learningVM)
                .tabItem {
                    Label("Öğren", systemImage: "book.fill")
                }
                .tag(2)
                .onAppear {
                    learningVM.refreshUser()
                }
            
            AIAssistantView()
                .tabItem {
                    Label("AI Asistan", systemImage: "sparkles")
                }
                .tag(3)
            
            ProfileView(tradingVM: tradingVM, learningVM: learningVM)
                .tabItem {
                    Label("Profil", systemImage: "person.fill")
                }
                .tag(4)
                .onAppear {
                    learningVM.refreshUser()
                }
        }
        .accentColor(.blue)
        .accessibilitySupport()
        .onChange(of: selectedTab) { _, _ in
            learningVM.refreshUser()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToTab"))) { notification in
            if let tabIndex = notification.object as? Int {
                selectedTab = tabIndex
            }
        }
    }
    
    private var iPadLayout: some View {
        NavigationSplitView {
            // Sidebar
            List {
                Button(action: { selectedTab = 0 }) {
                    Label(locHelper.string(for: "nav.home"), systemImage: "house.fill")
                }
                
                Button(action: { selectedTab = 1 }) {
                    Label(localizationHelper.string(for: "nav.trade"), systemImage: "dollarsign.circle.fill")
                }
                
                Button(action: { selectedTab = 2 }) {
                    Label(localizationHelper.string(for: "nav.learn"), systemImage: "book.fill")
                }
                
                Button(action: { selectedTab = 3 }) {
                    Label(localizationHelper.string(for: "nav.profile"), systemImage: "person.fill")
                }
            }
            .navigationTitle("EduTrade")
        } detail: {
            // Detail view
            Group {
                switch selectedTab {
                case 0:
                    DashboardView(tradingVM: tradingVM, learningVM: learningVM, selectedTab: $selectedTab)
                case 1:
                    TradeView(viewModel: tradingVM)
                case 2:
                    LearnView(viewModel: learningVM)
                case 3:
                    ProfileView(tradingVM: tradingVM, learningVM: learningVM)
                default:
                    DashboardView(tradingVM: tradingVM, learningVM: learningVM, selectedTab: $selectedTab)
                }
            }
            .onAppear {
                learningVM.refreshUser()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToTab"))) { notification in
                if let tabIndex = notification.object as? Int {
                    selectedTab = tabIndex
                }
            }
        }
        .onChange(of: selectedTab) { _, newValue in
            learningVM.refreshUser()
        }
    }
}

struct DashboardView: View {
    @ObservedObject var tradingVM: TradingViewModel
    @ObservedObject var learningVM: LearningViewModel
    @Binding var selectedTab: Int
    
    init(tradingVM: TradingViewModel, learningVM: LearningViewModel, selectedTab: Binding<Int>) {
        self.tradingVM = tradingVM
        self.learningVM = learningVM
        self._selectedTab = selectedTab
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Welcome Card
                        CleanWelcomeCard(
                            balance: tradingVM.user.balance,
                            learningVM: learningVM
                        )
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Action Buttons
                        VStack(spacing: 10) {
                            Button(action: {
                                HapticFeedback.selection()
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedTab = 1
                                }
                            }) {
                                CleanActionButton(
                                    title: "İşlem Yap",
                                    subtitle: "Coin al ve sat",
                                    icon: "chart.line.uptrend.xyaxis"
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: {
                                HapticFeedback.selection()
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedTab = 2
                                }
                            }) {
                                CleanActionButton(
                                    title: "Öğren",
                                    subtitle: "Dersler ve quiz'ler",
                                    icon: "book.fill"
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: {
                                HapticFeedback.selection()
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedTab = 3
                                }
                            }) {
                                CleanActionButton(
                                    title: "AI Asistan",
                                    subtitle: "Trading sorularını sor",
                                    icon: "sparkles"
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal)
                        
                        // Trading Performance Metrics
                        TradingPerformanceMetrics(tradingVM: tradingVM)
                            .padding(.horizontal)
                        
                        // Portfolio Section - Detaylı Portföy Gösterimi
                        DetailedPortfolioSection(viewModel: tradingVM, selectedTab: $selectedTab)
                            .padding(.horizontal)
                        
                        // Market Overview
                        MarketOverviewSection(coins: DataManager.shared.coins)
                            .padding(.horizontal)
                        
                        // Active Alerts & Orders
                        ActiveAlertsOrdersSection(tradingVM: tradingVM, selectedTab: $selectedTab)
                            .padding(.horizontal)
                        
                        // Stats Section
                        CleanStatsGrid(tradingVM: tradingVM, learningVM: learningVM)
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("EduTrade")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct CleanWelcomeCard: View {
    let balance: Double
    @ObservedObject var learningVM: LearningViewModel
    @State private var animateProgress = false
    
    var user: User {
        learningVM.getCurrentUser()
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with gradient background
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hoş Geldin! 👋")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(formatCurrency(balance))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.primaryGradient)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                
                Spacer()
                
                // Level Badge
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                        
                        Text("\(user.progress.currentLevel)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.primaryGradient)
                    }
                    
                    Text("Seviye")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
                .background(Color.secondary.opacity(0.2))
            
            // Stats Row
            HStack(spacing: 0) {
                // XP
                StatItem(
                    icon: "star.fill",
                    value: "\(user.progress.totalXP)",
                    label: "XP",
                    color: .blue
                )
                
                Divider()
                    .frame(height: 40)
                    .padding(.horizontal, 12)
                
                // Streak
                StatItem(
                    icon: "flame.fill",
                    value: "\(user.progress.streak)",
                    label: "Seri",
                    color: .orange
                )
                
                Divider()
                    .frame(height: 40)
                    .padding(.horizontal, 12)
                
                // Progress
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                        Text("\(Int(user.progress.levelProgress * 100))%")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    
                    Text("İlerleme")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            
            // XP Progress Bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(user.progress.currentLevelXP) / \(user.progress.currentLevel * 100) XP")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(user.progress.xpToNextLevel) XP kaldı")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.primaryGradient)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray5))
                            .frame(height: 10)
                        
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: animateProgress ? geometry.size.width * user.progress.levelProgress : 0,
                                height: 10
                            )
                            .animation(.spring(response: 0.8, dampingFraction: 0.8), value: animateProgress)
                    }
                }
                .frame(height: 10)
            }
        }
        .padding(20)
        .modernCard()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                animateProgress = true
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
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

struct CleanActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.15), Color.purple.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color.primaryGradient)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color.primaryGradient)
        }
        .padding(20)
        .modernCard()
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
    }
}

struct CleanStatsGrid: View {
    @ObservedObject var tradingVM: TradingViewModel
    @ObservedObject var learningVM: LearningViewModel
    
    var averageQuizScore: Int {
        let scores = Array(learningVM.quizResults.values)
        guard !scores.isEmpty else { return 0 }
        // Skorlar zaten 0-100 arası yüzde değerleri, ortalamasını al
        let total = scores.reduce(0, +)
        let average = total / scores.count
        // Maksimum 100 ile sınırla (güvenlik için)
        return min(average, 100)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("İstatistiklerin")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                CleanStatCard(
                    title: "İşlemler",
                    value: "\(tradingVM.user.numberOfTrades)",
                    icon: "arrow.left.arrow.right.circle.fill"
                )
                
                CleanStatCard(
                    title: "Quiz Skoru",
                    value: "\(averageQuizScore)%",
                    icon: "brain.head.profile"
                )
                
                CleanStatCard(
                    title: "Dersler",
                    value: "\(learningVM.completedLessons.count)",
                    icon: "checkmark.circle.fill"
                )
                
                CleanStatCard(
                    title: "Başarımlar",
                    value: "\(tradingVM.user.unlockedAchievements.count)",
                    icon: "star.fill"
                )
            }
        }
    }
}

struct CleanStatCard: View {
    let title: String
    let value: String
    let icon: String
    @State private var animateValue = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon with gradient
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.15), Color.purple.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.primaryGradient)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .opacity(animateValue ? 1 : 0)
                    .offset(y: animateValue ? 0 : 10)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateValue)
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .modernCard()
        .onAppear {
            animateValue = true
        }
    }
}

// MARK: - Detailed Portfolio Section
struct DetailedPortfolioSection: View {
    @ObservedObject var viewModel: TradingViewModel
    @Binding var selectedTab: Int
    
    private let coins = DataManager.shared.coins
    
    private var portfolioCoins: [(Coin, Double, Double)] {
        viewModel.user.portfolio.compactMap { symbol, amount in
            guard let coin = coins.first(where: { $0.symbol == symbol }),
                  amount > 0 else { return nil }
            let value = amount * coin.price
            return (coin, amount, value)
        }.sorted { $0.2 > $1.2 } // Sort by value
    }
    
    private var totalPortfolioValue: Double {
        portfolioCoins.reduce(0) { $0 + $1.2 }
    }
    
    private var totalProfit: Double {
        totalPortfolioValue + viewModel.user.balance - 100000.0
    }
    
    private var profitPercentage: Double {
        guard totalPortfolioValue > 0 else { return 0 }
        return (totalProfit / 100000.0) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "wallet.pass.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.blue)
                    
                    Text("Portföyüm")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // View All Button
                if !portfolioCoins.isEmpty {
                    Button(action: {
                        selectedTab = 3
                        NotificationCenter.default.post(
                            name: NSNotification.Name("OpenPortfolioTab"),
                            object: nil
                        )
                    }) {
                        HStack(spacing: 4) {
                            Text("Tümünü Gör")
                                .font(.system(size: 14, weight: .medium))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            
            if portfolioCoins.isEmpty {
                // Empty State
                VStack(spacing: 16) {
                    Image(systemName: "wallet.pass.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary.opacity(0.4))
                    
                    Text("Portföyün Boş")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Coin satın alarak portföyünü oluşturmaya başla")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        selectedTab = 1
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("İşlem Yap")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                )
            } else {
                // Portfolio Summary Card
                VStack(spacing: 16) {
                    // Total Value
                    VStack(spacing: 8) {
                        Text("Toplam Portföy Değeri")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text(formatCurrency(totalPortfolioValue))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    
                    Divider()
                    
                    // Profit/Loss and Balance
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Toplam Kâr/Zarar")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 4) {
                                Text(formatCurrency(abs(totalProfit)))
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(totalProfit >= 0 ? .green : .red)
                                
                                Text("(\(String(format: "%.2f", profitPercentage))%)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(totalProfit >= 0 ? .green : .red)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Nakit")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            Text(formatCurrency(viewModel.user.balance))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.blue.opacity(0.08),
                                    Color.purple.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                        )
                )
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                
                // Coin List
                VStack(spacing: 10) {
                    ForEach(Array(portfolioCoins.prefix(5)), id: \.0.id) { coin, amount, value in
                        PortfolioCoinRow(
                            coin: coin,
                            amount: amount,
                            value: value,
                            totalValue: totalPortfolioValue
                        )
                    }
                    
                    // Show More Button
                    if portfolioCoins.count > 5 {
                        Button(action: {
                            selectedTab = 3
                            NotificationCenter.default.post(
                                name: NSNotification.Name("OpenPortfolioTab"),
                                object: nil
                            )
                        }) {
                            HStack {
                                Text("\(portfolioCoins.count - 5) coin daha göster")
                                    .font(.system(size: 14, weight: .medium))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.1))
                            )
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }
    
    private func formatCurrency(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }
}

// MARK: - Portfolio Coin Row
struct PortfolioCoinRow: View {
    let coin: Coin
    let amount: Double
    let value: Double
    let totalValue: Double
    
    private var portfolioPercentage: Double {
        totalValue > 0 ? (value / totalValue) * 100 : 0
    }
    
    var body: some View {
        HStack(spacing: 12) {
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
                    .frame(width: 48, height: 48)
                
                Image(systemName: "bitcoinsign.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.blue)
            }
            
            // Coin Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(coin.symbol)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("• \(String(format: "%.1f", portfolioPercentage))%")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Text(coin.name)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Value and Change
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatCurrency(value))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                HStack(spacing: 4) {
                    Image(systemName: coin.change24h >= 0 ? "arrow.up" : "arrow.down")
                        .font(.system(size: 10))
                    Text("\(String(format: "%.2f", coin.change24h))%")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(coin.change24h >= 0 ? .green : .red)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private func formatCurrency(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }
}

// MARK: - Additional Home Sections

struct RecentTradesSection: View {
    @ObservedObject var viewModel: TradingViewModel
    
    var recentTrades: [Trade] {
        Array(viewModel.trades.prefix(3))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Son İşlemler")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                NavigationLink(destination: TradeView(viewModel: viewModel)) {
                    Text("Tümünü Gör")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                }
            }
            
            VStack(spacing: 8) {
                ForEach(recentTrades) { trade in
                    RecentTradeRow(trade: trade)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }
}

struct RecentTradeRow: View {
    let trade: Trade
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: trade.type == .buy ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(trade.type == .buy ? .green : .red)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill((trade.type == .buy ? Color.green : Color.red).opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 3) {
                Text("\(trade.type == .buy ? "Alındı" : "Satıldı") \(trade.coinSymbol)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(trade.timestamp, style: .relative)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 3) {
                Text(String(format: "%.4f", trade.amount))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(formatCurrency(trade.amount * trade.price))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

struct DailyChallengesPreview: View {
    @ObservedObject var learningVM: LearningViewModel
    
    var dailyChallenges: [Challenge] {
        learningVM.challenges.filter { $0.type == .daily }.prefix(2).map { $0 }
    }
    
    var user: User {
        learningVM.getCurrentUser()
    }
    
    var body: some View {
        if !dailyChallenges.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Günlük Görevler")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        NotificationCenter.default.post(name: NSNotification.Name("NavigateToTab"), object: 2)
                    }) {
                        Text("Tümünü Gör")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                    }
                }
                
                VStack(spacing: 8) {
                    ForEach(dailyChallenges) { challenge in
                        DailyChallengeRow(
                            challenge: challenge,
                            isCompleted: user.progress.completedChallenges.contains(challenge.id)
                        )
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
            )
        }
    }
}

struct DailyChallengeRow: View {
    let challenge: Challenge
    let isCompleted: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isCompleted ? Color.green.opacity(0.15) : Color.blue.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: challenge.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isCompleted ? .green : .blue)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(challenge.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                
                Text(challenge.description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 20))
            } else {
                HStack(spacing: 3) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                    Text("\(challenge.xpReward)")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.blue)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCompleted ? Color.green.opacity(0.05) : Color(.systemGray6))
        )
    }
}

struct LeaderboardPreview: View {
    @ObservedObject var leaderboardVM = LeaderboardViewModel.shared
    @State private var showingLeaderboard = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.primaryGradient)
                    
                    Text("Liderlik Tablosu")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                NavigationLink(destination: LeaderboardView()) {
                    Text("Tümünü Gör")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
            
            if leaderboardVM.entries.isEmpty {
                Text("Henüz liderlik tablosu yok")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(leaderboardVM.entries.prefix(3).enumerated()), id: \.element.id) { index, entry in
                        HStack(spacing: 12) {
                            // Rank
                            ZStack {
                                Circle()
                                    .fill(
                                        index == 0 ?
                                        LinearGradient(
                                            colors: [Color.yellow.opacity(0.2), Color.yellow.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ) :
                                        LinearGradient(
                                            colors: [Color(.systemGray6), Color(.systemGray6)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 36, height: 36)
                                
                                Text("\(index + 1)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(index == 0 ? .yellow : .primary)
                            }
                            
                            // User name
                            Text(entry.userName)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            // XP
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                Text("\(entry.totalXP)")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundStyle(Color.primaryGradient)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(index == 0 ? Color.yellow.opacity(0.05) : Color(.systemGray6))
                        )
                    }
                }
            }
        }
        .padding(18)
        .modernCard()
        .onAppear {
            leaderboardVM.updateCurrentUserEntry()
        }
    }
}

// MARK: - Trading Performance Metrics
struct TradingPerformanceMetrics: View {
    @ObservedObject var tradingVM: TradingViewModel
    
    private var statistics: TradingStatistics {
        tradingVM.getTradingStatistics()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.blue)
                
                Text("Trading Performansı")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            HStack(spacing: 12) {
                // Win Rate
                PerformanceMetricCard(
                    title: "Başarı Oranı",
                    value: "\(String(format: "%.1f", statistics.winRate))%",
                    icon: "target",
                    color: statistics.winRate >= 50 ? .green : .orange,
                    subtitle: "\(statistics.totalTrades) işlem"
                )
                
                // Profit Factor
                PerformanceMetricCard(
                    title: "Profit Factor",
                    value: String(format: "%.2f", statistics.profitFactor),
                    icon: "arrow.up.right.circle.fill",
                    color: statistics.profitFactor >= 1 ? .green : .red,
                    subtitle: statistics.profitFactor >= 1 ? "Kârlı" : "Zararlı"
                )
                
                // Total Profit
                PerformanceMetricCard(
                    title: "Toplam Kâr",
                    value: formatCurrency(statistics.totalProfit),
                    icon: "dollarsign.circle.fill",
                    color: statistics.totalProfit >= 0 ? .green : .red,
                    subtitle: statistics.totalProfit >= 0 ? "Pozitif" : "Negatif"
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }
    
    private func formatCurrency(_ value: Double) -> String {
        String(format: "$%.0f", value)
    }
}

struct PerformanceMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(color.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(color.opacity(0.08))
        )
    }
}

// MARK: - Market Overview Section
struct MarketOverviewSection: View {
    let coins: [Coin]
    
    private var topGainers: [Coin] {
        Array(coins.sorted { $0.change24h > $1.change24h }.prefix(3))
    }
    
    private var topLosers: [Coin] {
        Array(coins.sorted { $0.change24h < $1.change24h }.prefix(3))
    }
    
    private var marketTrend: MarketTrend {
        let avgChange = coins.map { $0.change24h }.reduce(0, +) / Double(coins.count)
        if avgChange > 2 {
            return .bullish
        } else if avgChange < -2 {
            return .bearish
        } else {
            return .neutral
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.blue)
                
                Text("Piyasa Durumu")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Market Trend Indicator
                HStack(spacing: 6) {
                    Image(systemName: marketTrend.icon)
                        .font(.system(size: 12))
                    Text(marketTrend.label)
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(marketTrend.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(marketTrend.color.opacity(0.15))
                )
            }
            
            // Market Summary
            HStack(spacing: 12) {
                MarketSummaryCard(
                    title: "En Çok Yükselen",
                    coins: topGainers,
                    isGainer: true
                )
                
                MarketSummaryCard(
                    title: "En Çok Düşen",
                    coins: topLosers,
                    isGainer: false
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }
}

enum MarketTrend {
    case bullish, bearish, neutral
    
    var icon: String {
        switch self {
        case .bullish: return "arrow.up.right"
        case .bearish: return "arrow.down.right"
        case .neutral: return "minus"
        }
    }
    
    var label: String {
        switch self {
        case .bullish: return "Yükseliş"
        case .bearish: return "Düşüş"
        case .neutral: return "Nötr"
        }
    }
    
    var color: Color {
        switch self {
        case .bullish: return .green
        case .bearish: return .red
        case .neutral: return .gray
        }
    }
}

struct MarketSummaryCard: View {
    let title: String
    let coins: [Coin]
    let isGainer: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
            
            if coins.isEmpty {
                Text("Veri yok")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(coins.prefix(3)) { coin in
                        HStack(spacing: 8) {
                            Text(coin.symbol)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Image(systemName: coin.change24h >= 0 ? "arrow.up" : "arrow.down")
                                    .font(.system(size: 9))
                                Text("\(String(format: "%.1f", coin.change24h))%")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(coin.change24h >= 0 ? .green : .red)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isGainer ? Color.green.opacity(0.08) : Color.red.opacity(0.08))
        )
    }
}

// MARK: - Active Alerts & Orders Section
struct ActiveAlertsOrdersSection: View {
    @ObservedObject var tradingVM: TradingViewModel
    @Binding var selectedTab: Int
    @State private var showingPriceAlerts = false
    @State private var showingPendingOrders = false
    
    private var activeAlerts: Int {
        tradingVM.priceAlerts.filter { $0.isActive }.count
    }
    
    private var pendingOrders: Int {
        tradingVM.orders.filter { $0.status == .pending }.count
    }
    
    var body: some View {
        if activeAlerts > 0 || pendingOrders > 0 {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.orange)
                    
                    Text("Aktif Bildirimler")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                HStack(spacing: 12) {
                    if activeAlerts > 0 {
                        Button(action: {
                            showingPriceAlerts = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 14))
                                
                                Text("Fiyat Alarmları")
                                    .font(.system(size: 14, weight: .semibold))
                                
                                Text("\(activeAlerts)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Circle().fill(Color.red))
                            }
                            .foregroundColor(.orange)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.orange.opacity(0.15))
                            )
                        }
                    }
                    
                    if pendingOrders > 0 {
                        Button(action: {
                            showingPendingOrders = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "list.bullet.rectangle.portrait.fill")
                                    .font(.system(size: 14))
                                
                                Text("Limit Emirleri")
                                    .font(.system(size: 14, weight: .semibold))
                                
                                Text("\(pendingOrders)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Circle().fill(Color.red))
                            }
                            .foregroundColor(.purple)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.purple.opacity(0.15))
                            )
                        }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
            )
            .sheet(isPresented: $showingPriceAlerts) {
                PriceAlertsView(viewModel: tradingVM)
            }
            .sheet(isPresented: $showingPendingOrders) {
                PendingOrdersView(tradingVM: tradingVM)
            }
        }
    }
}

// MARK: - Quick Actions Section

struct QuickActionsSection: View {
    @ObservedObject var tradingVM: TradingViewModel
    @ObservedObject var learningVM: LearningViewModel
    @Binding var selectedTab: Int
    @State private var showingPriceAlerts = false
    @State private var showingTradingJournal = false
    @State private var showingPendingOrders = false
    @State private var showingPortfolioChart = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hızlı Erişim")
                .font(.system(size: 18, weight: .bold))
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                QuickActionCard(
                    title: "Fiyat Alarmları",
                    icon: "bell.fill",
                    color: .orange,
                    badge: tradingVM.priceAlerts.filter { $0.isActive }.count,
                    action: {
                        showingPriceAlerts = true
                    }
                )
                
                QuickActionCard(
                    title: "Limit Emirleri",
                    icon: "list.bullet.rectangle",
                    color: .purple,
                    badge: tradingVM.orders.filter { $0.status == .pending }.count,
                    action: {
                        showingPendingOrders = true
                    }
                )
                
                QuickActionCard(
                    title: "Trading Günlüğü",
                    icon: "book.closed.fill",
                    color: .blue,
                    badge: tradingVM.journalEntries.count,
                    action: {
                        showingTradingJournal = true
                    }
                )
                
                QuickActionCard(
                    title: "Portföy Grafiği",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green,
                    action: {
                        showingPortfolioChart = true
                    }
                )
                
                QuickActionCard(
                    title: "Portföyüm",
                    icon: "wallet.pass.fill",
                    color: .indigo,
                    badge: tradingVM.user.portfolio.count,
                    action: {
                        selectedTab = 3
                        // ProfileView'a geçip portföy sekmesini aç
                        NotificationCenter.default.post(
                            name: NSNotification.Name("OpenPortfolioTab"),
                            object: nil
                        )
                    }
                )
            }
        }
        .sheet(isPresented: $showingPriceAlerts) {
            PriceAlertsView(viewModel: tradingVM)
        }
        .sheet(isPresented: $showingTradingJournal) {
            TradingJournalView(tradingVM: tradingVM)
        }
        .sheet(isPresented: $showingPendingOrders) {
            PendingOrdersView(tradingVM: tradingVM)
        }
        .sheet(isPresented: $showingPortfolioChart) {
            PortfolioChartView(snapshots: tradingVM.portfolioSnapshots)
        }
    }
}

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let badge: Int?
    let action: () -> Void
    @State private var isPressed = false
    
    init(title: String, icon: String, color: Color, badge: Int? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.badge = badge
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            HapticFeedback.selection()
            action()
        }) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(color)
                    
                    if let badge = badge, badge > 0 {
                        VStack {
                            HStack {
                                Spacer()
                                Text("\(badge)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(Circle().fill(color))
                                    .offset(x: 8, y: -8)
                            }
                            Spacer()
                        }
                        .frame(width: 50, height: 50)
                    }
                }
                
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

#Preview {
    HomeView()
}
