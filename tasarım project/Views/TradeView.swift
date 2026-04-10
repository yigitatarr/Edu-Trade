//
//  TradeView.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import SwiftUI

enum OrderExecutionType {
    case market
    case limit
}

struct TradeView: View {
    @ObservedObject var viewModel: TradingViewModel
    @ObservedObject var dataManager = DataManager.shared
    @ObservedObject var priceService = CoinPriceService.shared
    @ObservedObject var offlineService = OfflineService.shared
    @State private var selectedCoin: Coin?
    @State private var showingTradeSheet = false
    @State private var showingCoinDetail = false
    @State private var isBuying = true
    @State private var tradeAmount = ""
    @State private var showingHistory = false
    @State private var searchText = ""
    @State private var showFavoritesOnly = false
    @State private var sortOption: CoinSortOption = .name
    @State private var sortOrder: SortOrder = .ascending
    @State private var showingFilterSheet = false
    @State private var coinFilter = CoinFilter()
    @State private var showingPriceAlertSheet = false
    @State private var showingLimitOrderSheet = false
    @State private var showingPriceAlertsView = false
    @State private var showingPendingOrdersView = false
    @State private var showingQuickAlertMenu = false
    
    private var coins: [Coin] {
        dataManager.coins
    }
    
    private var favoriteCoins: [Coin] {
        viewModel.getFavoriteCoins(from: coins)
    }
    
    private var filteredCoins: [Coin] {
        var coinsToShow = showFavoritesOnly ? favoriteCoins : coins
        
        // Search filter
        if !searchText.isEmpty {
            coinsToShow = coinsToShow.filter { coin in
                coin.name.localizedCaseInsensitiveContains(searchText) ||
                coin.symbol.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply filters
        coinsToShow = coinsToShow.filter { coin in
            let coinHasPortfolio = viewModel.getPortfolioAmount(for: coin) > 0
            let coinIsFavorite = viewModel.isFavorite(coinSymbol: coin.symbol)
            return coinFilter.matches(coin, coinHasPortfolio: coinHasPortfolio, coinIsFavorite: coinIsFavorite)
        }
        
        // Sort coins
        coinsToShow = sortCoins(coinsToShow, by: sortOption, order: sortOrder)
        
        return coinsToShow
    }
    
    private func sortCoins(_ coins: [Coin], by option: CoinSortOption, order: SortOrder) -> [Coin] {
        return coins.sorted { coin1, coin2 in
            let comparison: Bool
            
            switch option {
            case .name:
                comparison = coin1.name < coin2.name
            case .price:
                comparison = coin1.price < coin2.price
            case .change24h:
                comparison = coin1.change24h < coin2.change24h
            case .marketCap:
                let cap1 = coin1.marketCap ?? 0
                let cap2 = coin2.marketCap ?? 0
                comparison = cap1 < cap2
            case .volume:
                let vol1 = coin1.totalVolume ?? 0
                let vol2 = coin2.totalVolume ?? 0
                comparison = vol1 < vol2
            }
            
            return order == .ascending ? comparison : !comparison
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if coins.isEmpty && !priceService.isLoading {
                    EmptyStateView(
                        icon: "bitcoinsign.circle.fill",
                        title: "Coin Bulunamadı",
                        message: "Coin listesi yükleniyor veya bir hata oluştu. Lütfen yenilemeyi deneyin.",
                        actionTitle: "Yenile",
                        action: {
                            priceService.forceUpdate()
                        }
                    )
                } else {
                    VStack(spacing: 0) {
                        // Search bar and filter
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.secondary)
                                TextField("Coin ara...", text: $searchText)
                                    .textFieldStyle(.plain)
                                if !searchText.isEmpty {
                                    Button(action: { searchText = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(12)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            
                            // Filter and sort buttons
                            HStack(spacing: 12) {
                                FilterButton(
                                    title: "Tümü",
                                    icon: "list.bullet",
                                    isSelected: !showFavoritesOnly,
                                    action: { showFavoritesOnly = false }
                                )
                                
                                FilterButton(
                                    title: "Favoriler",
                                    icon: "star.fill",
                                    isSelected: showFavoritesOnly,
                                    action: { showFavoritesOnly = true }
                                )
                                
                                Spacer()
                                
                                // Sort button
                                Menu {
                                    Picker("Sıralama", selection: $sortOption) {
                                        ForEach(CoinSortOption.allCases, id: \.self) { option in
                                            Label(option.displayName, systemImage: option.icon)
                                                .tag(option)
                                        }
                                    }
                                    
                                    Picker("Sıra", selection: $sortOrder) {
                                        ForEach(SortOrder.allCases, id: \.self) { order in
                                            Label(order.displayName, systemImage: order.icon)
                                                .tag(order)
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: sortOption.icon)
                                            .font(.system(size: 14, weight: .semibold))
                                        Image(systemName: sortOrder.icon)
                                            .font(.system(size: 12))
                                    }
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        Capsule()
                                            .fill(Color(.systemGray6))
                                    )
                                }
                                
                                // Filter button
                                Button(action: {
                                    showingFilterSheet = true
                                }) {
                                    Image(systemName: "line.3.horizontal.decrease.circle")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.primary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(
                                            Capsule()
                                                .fill(
                                                    (coinFilter.minPrice != nil || coinFilter.maxPrice != nil || coinFilter.minChange24h != nil || coinFilter.maxChange24h != nil || coinFilter.hasPortfolio != nil) ?
                                                    LinearGradient(
                                                        colors: [Color.blue, Color.purple],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    ) :
                                                    LinearGradient(
                                                        colors: [Color(.systemGray6), Color(.systemGray6)],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                        )
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        
                        // Quick Actions Bar - Fiyat Alarmı ve Limit Emri
                        HStack(spacing: 12) {
                            Button(action: {
                                showingPriceAlertsView = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "bell.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Fiyat Alarmları")
                                        .font(.system(size: 14, weight: .medium))
                                    
                                    if !viewModel.priceAlerts.filter({ $0.isActive }).isEmpty {
                                        Text("\(viewModel.priceAlerts.filter({ $0.isActive }).count)")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Circle().fill(Color.red))
                                    }
                                }
                                .foregroundColor(.orange)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(Color.orange.opacity(0.15))
                                )
                            }
                            
                            Button(action: {
                                showingPendingOrdersView = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "list.bullet.rectangle.portrait.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Limit Emirleri")
                                        .font(.system(size: 14, weight: .medium))
                                    
                                    if !viewModel.orders.filter({ $0.status == .pending }).isEmpty {
                                        Text("\(viewModel.orders.filter({ $0.status == .pending }).count)")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Circle().fill(Color.red))
                                    }
                                }
                                .foregroundColor(.purple)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(Color.purple.opacity(0.15))
                                )
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        
                        ScrollView {
                            if DeviceHelper.isIPad {
                                // iPad: Grid layout
                                LazyVGrid(
                                    columns: [
                                        GridItem(.flexible(), spacing: 16),
                                        GridItem(.flexible(), spacing: 16)
                                    ],
                                    spacing: 20
                                ) {
                                    // Balance Card (full width)
                                    BalanceCard(balance: viewModel.user.balance)
                                        .gridCellColumns(2)
                                    
                                    // Coins List
                                    if filteredCoins.isEmpty {
                                        EmptyStateView(
                                            icon: showFavoritesOnly ? "star" : "magnifyingglass",
                                            title: showFavoritesOnly ? "Favori Coin Yok" : "Coin Bulunamadı",
                                            message: showFavoritesOnly ? "Henüz favori coin eklemediniz. Coin'lerin yanındaki yıldız ikonuna tıklayarak favorilere ekleyebilirsiniz." : "Arama kriterlerinize uygun coin bulunamadı."
                                        )
                                        .gridCellColumns(2)
                                        .padding(.top, 40)
                                    } else {
                                        ForEach(filteredCoins) { coin in
                                            CoinRow(
                                                coin: coin,
                                                portfolioAmount: viewModel.getPortfolioAmount(for: coin),
                                                viewModel: viewModel,
                                                onTap: {
                                                    HapticFeedback.selection()
                                                    selectedCoin = coin
                                                    showingCoinDetail = true
                                                }
                                            )
                                            .contextMenu {
                                                Button {
                                                    HapticFeedback.selection()
                                                    selectedCoin = coin
                                                    showingCoinDetail = true
                                                } label: {
                                                    Label("Detayları Gör", systemImage: "info.circle")
                                                }
                                                
                                                Button {
                                                    viewModel.toggleFavorite(coinSymbol: coin.symbol)
                                                    HapticFeedback.selection()
                                                } label: {
                                                    Label(
                                                        viewModel.isFavorite(coinSymbol: coin.symbol) ? "Favoriden Çıkar" : "Favoriye Ekle",
                                                        systemImage: viewModel.isFavorite(coinSymbol: coin.symbol) ? "star.slash" : "star"
                                                    )
                                                }
                                                
                                                Button {
                                                    HapticFeedback.medium()
                                                    selectedCoin = coin
                                                    showingTradeSheet = true
                                                    isBuying = true
                                                } label: {
                                                    Label("Hızlı Al", systemImage: "arrow.down.circle")
                                                }
                                                
                                                if viewModel.getPortfolioAmount(for: coin) > 0 {
                                                    Button {
                                                        HapticFeedback.medium()
                                                        selectedCoin = coin
                                                        showingTradeSheet = true
                                                        isBuying = false
                                                    } label: {
                                                        Label("Hızlı Sat", systemImage: "arrow.up.circle")
                                                    }
                                                }
                                                
                                                Divider()
                                                
                                                Button {
                                                    selectedCoin = coin
                                                    showingPriceAlertSheet = true
                                                } label: {
                                                    Label("Fiyat Alarmı Koy", systemImage: "bell.fill")
                                                }
                                                
                                                Button {
                                                    selectedCoin = coin
                                                    showingLimitOrderSheet = true
                                                } label: {
                                                    Label("Limit Emri Oluştur", systemImage: "list.bullet.rectangle.portrait.fill")
                                                }
                                                
                                                Divider()
                                                
                                                Button {
                                                    selectedCoin = coin
                                                    showingCoinDetail = true
                                                } label: {
                                                    Label("Grafik ve Analiz", systemImage: "chart.line.uptrend.xyaxis")
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding()
                            } else {
                                // iPhone: Vertical list
                                VStack(spacing: 20) {
                                    // Balance Card
                                    BalanceCard(balance: viewModel.user.balance)
                                    
                                    // Coins List
                                    if filteredCoins.isEmpty {
                                        EmptyStateView(
                                            icon: showFavoritesOnly ? "star" : "magnifyingglass",
                                            title: showFavoritesOnly ? "Favori Coin Yok" : "Coin Bulunamadı",
                                            message: showFavoritesOnly ? "Henüz favori coin eklemediniz. Coin'lerin yanındaki yıldız ikonuna tıklayarak favorilere ekleyebilirsiniz." : "Arama kriterlerinize uygun coin bulunamadı."
                                        )
                                        .padding(.top, 40)
                                    } else {
                                        ForEach(filteredCoins) { coin in
                                            CoinRow(
                                                coin: coin,
                                                portfolioAmount: viewModel.getPortfolioAmount(for: coin),
                                                viewModel: viewModel,
                                                onTap: {
                                                    HapticFeedback.selection()
                                                    selectedCoin = coin
                                                    showingCoinDetail = true
                                                }
                                            )
                                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                                Button {
                                                    HapticFeedback.medium()
                                                    selectedCoin = coin
                                                    showingTradeSheet = true
                                                    isBuying = true
                                                } label: {
                                                    Label("Hızlı Al", systemImage: "arrow.down.circle.fill")
                                                }
                                                .tint(.green)
                                                
                                                Button {
                                                    viewModel.toggleFavorite(coinSymbol: coin.symbol)
                                                    HapticFeedback.selection()
                                                } label: {
                                                    Label(
                                                        viewModel.isFavorite(coinSymbol: coin.symbol) ? "Favoriden Çıkar" : "Favoriye Ekle",
                                                        systemImage: viewModel.isFavorite(coinSymbol: coin.symbol) ? "star.slash.fill" : "star.fill"
                                                    )
                                                }
                                                .tint(.yellow)
                                            }
                                            .swipeActions(edge: .leading, allowsFullSwipe: viewModel.getPortfolioAmount(for: coin) > 0) {
                                                if viewModel.getPortfolioAmount(for: coin) > 0 {
                                                    Button {
                                                        HapticFeedback.medium()
                                                        selectedCoin = coin
                                                        showingTradeSheet = true
                                                        isBuying = false
                                                    } label: {
                                                        Label("Hızlı Sat", systemImage: "arrow.up.circle.fill")
                                                    }
                                                    .tint(.red)
                                                }
                                            }
                                            .contextMenu {
                                                Button {
                                                    HapticFeedback.selection()
                                                    selectedCoin = coin
                                                    showingCoinDetail = true
                                                } label: {
                                                    Label("Detayları Gör", systemImage: "info.circle")
                                                }
                                                
                                                Button {
                                                    viewModel.toggleFavorite(coinSymbol: coin.symbol)
                                                    HapticFeedback.selection()
                                                } label: {
                                                    Label(
                                                        viewModel.isFavorite(coinSymbol: coin.symbol) ? "Favoriden Çıkar" : "Favoriye Ekle",
                                                        systemImage: viewModel.isFavorite(coinSymbol: coin.symbol) ? "star.slash" : "star"
                                                    )
                                                }
                                                
                                                Button {
                                                    HapticFeedback.medium()
                                                    selectedCoin = coin
                                                    showingTradeSheet = true
                                                    isBuying = true
                                                } label: {
                                                    Label("Hızlı Al", systemImage: "arrow.down.circle")
                                                }
                                                
                                                if viewModel.getPortfolioAmount(for: coin) > 0 {
                                                    Button {
                                                        HapticFeedback.medium()
                                                        selectedCoin = coin
                                                        showingTradeSheet = true
                                                        isBuying = false
                                                    } label: {
                                                        Label("Hızlı Sat", systemImage: "arrow.up.circle")
                                                    }
                                                }
                                                
                                                Divider()
                                                
                                                Button {
                                                    selectedCoin = coin
                                                    showingCoinDetail = true
                                                } label: {
                                                    Label("Grafik ve Analiz", systemImage: "chart.line.uptrend.xyaxis")
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding()
                            }
                        }
                        .refreshable {
                            HapticFeedback.light()
                            priceService.forceUpdate()
                        }
                    }
                }
            }
            .loadingOverlay(isLoading: priceService.isLoading && coins.isEmpty, message: "Fiyatlar güncelleniyor...")
            .navigationTitle(LocalizationHelper.shared.string(for: "nav.trade"))
            .accessibilitySupport()
            .errorAlert()
            .overlay(alignment: .top) {
                if !offlineService.isOnline {
                    HStack {
                        Image(systemName: "wifi.slash")
                            .accessibilityLabel("İnternet bağlantısı yok")
                        Text("Offline - Fiyatlar güncellenemiyor")
                            .font(.caption)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(Color.orange.opacity(0.9))
                    .foregroundColor(.white)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Offline modu. Fiyatlar güncellenemiyor.")
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // Price update indicator
                    HStack(spacing: 6) {
                        if priceService.isLoading {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else if let lastUpdate = priceService.lastUpdateTime {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        // Quick Actions Menu
                        Menu {
                            Button(action: {
                                showingPriceAlertsView = true
                            }) {
                                Label("Fiyat Alarmları", systemImage: "bell.fill")
                            }
                            
                            Button(action: {
                                showingPendingOrdersView = true
                            }) {
                                Label("Limit Emirleri", systemImage: "list.bullet.rectangle.portrait.fill")
                            }
                            
                            Divider()
                            
                            Button(action: {
                                showingHistory = true
                            }) {
                                Label("İşlem Geçmişi", systemImage: "clock.arrow.circlepath")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(.blue)
                                .font(.system(size: 18))
                        }
                        
                        // Manual refresh button
                        Button(action: {
                            priceService.forceUpdate()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingPriceAlertSheet) {
                if let coin = selectedCoin {
                    QuickPriceAlertSheet(coin: coin, viewModel: viewModel)
                }
            }
            .sheet(isPresented: $showingLimitOrderSheet) {
                if let coin = selectedCoin {
                    QuickLimitOrderSheet(coin: coin, viewModel: viewModel)
                }
            }
            .sheet(isPresented: $showingCoinDetail) {
                if let coin = selectedCoin {
                    CoinDetailView(
                        coin: coin,
                        viewModel: viewModel
                    )
                }
            }
            .sheet(isPresented: $showingTradeSheet) {
                if let coin = selectedCoin {
                    TradeSheet(
                        coin: coin,
                        viewModel: viewModel,
                        isBuying: $isBuying,
                        tradeAmount: $tradeAmount,
                        onDismiss: {
                            showingTradeSheet = false
                            tradeAmount = ""
                        }
                    )
                }
            }
            .sheet(isPresented: $showingHistory) {
                TradeHistoryView(trades: viewModel.trades)
            }
            .sheet(isPresented: $showingFilterSheet) {
                CoinFilterSheet(filter: $coinFilter)
            }
        }
    }
}

struct BalanceCard: View {
    let balance: Double
    @State private var animateBalance = false
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.primaryGradient)
                    
                    Text("Mevcut Bakiye")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Text(formatCurrency(balance))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primaryGradient)
                    .opacity(animateBalance ? 1 : 0)
                    .offset(y: animateBalance ? 0 : 5)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateBalance)
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                
                Image(systemName: "wallet.pass.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Color.primaryGradient)
            }
        }
        .padding(20)
        .modernCard()
        .onAppear {
            animateBalance = true
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        String(format: "$%.0f", value)
    }
}

struct CoinRow: View {
    let coin: Coin
    let portfolioAmount: Double
    @ObservedObject var viewModel: TradingViewModel
    let onTap: () -> Void
    @State private var isPressed = false
    @State private var showingQuickTrade = false
    
    private func formatCurrency(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Coin Icon with gradient
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
                    
                    Image(systemName: "bitcoinsign.circle.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(Color.primaryGradient)
                }
                
                // Coin Info
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(coin.symbol)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        if portfolioAmount > 0 {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.green)
                        }
                    }
                    
                    Text(coin.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    if portfolioAmount > 0 {
                        HStack(spacing: 6) {
                            Text("\(String(format: "%.4f", portfolioAmount)) adet")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.green)
                            
                            if let stopLoss = viewModel.user.stopLossLevels[coin.symbol] {
                                HStack(spacing: 3) {
                                    Image(systemName: "hand.raised.fill")
                                        .font(.system(size: 10))
                                    Text("SL")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .foregroundColor(.orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.orange.opacity(0.15))
                                )
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Favorite Button
                Button(action: {
                    HapticFeedback.selection()
                    viewModel.toggleFavorite(coinSymbol: coin.symbol)
                }) {
                    Image(systemName: viewModel.isFavorite(coinSymbol: coin.symbol) ? "star.fill" : "star")
                        .font(.system(size: 20))
                        .foregroundColor(viewModel.isFavorite(coinSymbol: coin.symbol) ? .yellow : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Price Info
                VStack(alignment: .trailing, spacing: 6) {
                    Text(coin.formattedPrice)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    HStack(spacing: 4) {
                        Image(systemName: coin.priceChangeIcon)
                            .font(.system(size: 11, weight: .semibold))
                        Text(String(format: "%.2f%%", coin.change24h))
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(coin.change24h >= 0 ? .green : .red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill((coin.change24h >= 0 ? Color.green : Color.red).opacity(0.15))
                    )
                }
            }
            .padding(18)
            .modernCard(cornerRadius: AppCornerRadius.large)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

struct TradeSheet: View {
    let coin: Coin
    @ObservedObject var viewModel: TradingViewModel
    @ObservedObject var dataManager = DataManager.shared
    @Binding var isBuying: Bool
    @Binding var tradeAmount: String
    let onDismiss: () -> Void
    @State private var stopLossPrice: String = ""
    @State private var showStopLossInfo = false
    @State private var orderType: OrderExecutionType = .market
    @State private var limitPrice: String = ""
    @State private var takeProfitPrice: String = ""
    @State private var showOrderInfo = false
    
    // Get current coin price from dataManager
    private var currentCoin: Coin? {
        dataManager.coins.first(where: { $0.id == coin.id || $0.symbol == coin.symbol })
    }
    
    private var displayCoin: Coin {
        currentCoin ?? coin
    }
    
    private var amount: Double {
        tradeAmount.toDouble ?? 0.0
    }
    
    private var totalCost: Double {
        amount * displayCoin.price
    }
    
    private var canBuy: Bool {
        isBuying && totalCost <= viewModel.user.balance && amount > 0
    }
    
    private var canSell: Bool {
        !isBuying && amount <= viewModel.getPortfolioAmount(for: coin) && amount > 0
    }
    
    // Portfolio bilgileri
    private var portfolioAmount: Double {
        viewModel.getPortfolioAmount(for: displayCoin)
    }
    
    private var portfolioValue: Double {
        viewModel.getPortfolioValue(for: displayCoin)
    }
    
    private var hasPortfolio: Bool {
        portfolioAmount > 0
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 14) {
                        // Hero Header - Coin Info
                        CoinHeroHeader(coin: displayCoin)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        // Portfolio Info Card (if user owns this coin)
                        if hasPortfolio {
                            PortfolioInfoCard(
                                coin: displayCoin,
                                amount: portfolioAmount,
                                value: portfolioValue
                            )
                            .padding(.horizontal)
                        }
                        
                        // Price Statistics Card
                        PriceStatisticsCard(coin: displayCoin)
                            .padding(.horizontal)
                        
                        // Buy/Sell Toggle
                        BuySellToggle(isBuying: $isBuying)
                            .padding(.horizontal)
                        
                        // Order Type Toggle (Market/Limit)
                        OrderTypeSelector(orderType: $orderType, showInfo: $showOrderInfo)
                            .padding(.horizontal)
                        
                        // Amount Input Section
                        AmountInputSection(
                            isBuying: isBuying,
                            tradeAmount: $tradeAmount,
                            coin: displayCoin,
                            balance: viewModel.user.balance,
                            portfolioAmount: portfolioAmount
                        )
                        .padding(.horizontal)
                        
                        // Limit Price Section (only for limit orders)
                        if orderType == .limit {
                            LimitPriceSection(
                                coin: displayCoin,
                                limitPrice: $limitPrice,
                                isBuying: isBuying
                            )
                            .padding(.horizontal)
                        }
                        
                        // Stop Loss Section (only when buying)
                        if isBuying {
                            StopLossSection(
                                coin: displayCoin,
                                stopLossPrice: $stopLossPrice,
                                showInfo: $showStopLossInfo
                            )
                            .padding(.horizontal)
                        }
                        
                        // Take Profit Section (optional)
                        TakeProfitSection(
                            coin: displayCoin,
                            takeProfitPrice: $takeProfitPrice,
                            isBuying: isBuying
                        )
                        .padding(.horizontal)
                        
                        // Trade Summary (when amount > 0)
                        if amount > 0 {
                            TradeSummaryCard(
                                coin: displayCoin,
                                amount: amount,
                                totalCost: totalCost,
                                isBuying: isBuying,
                                stopLoss: stopLossPrice.toDouble,
                                limitPrice: limitPrice.toDouble,
                                takeProfit: takeProfitPrice.toDouble,
                                orderType: orderType
                            )
                            .padding(.horizontal)
                        }
                        
                        // Quick Amount Buttons (only when buying)
                        if isBuying {
                            QuickAmountSection(
                                coin: displayCoin,
                                balance: viewModel.user.balance,
                                tradeAmount: $tradeAmount
                            )
                            .padding(.horizontal)
                        }
                        
                        // Execute Button
                        ExecuteTradeButton(
                            coin: displayCoin,
                            isBuying: isBuying,
                            canExecute: isBuying ? canBuy : canSell,
                            onExecute: executeTrade
                        )
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("İşlem")
            .navigationBarTitleDisplayMode(.inline)
            .errorAlert()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        onDismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
    
    private func executeTrade() {
        guard amount > 0 else { return }
        
        let stopLoss: Double? = {
            if isBuying, let stopLossValue = stopLossPrice.toDouble, stopLossValue > 0 {
                return stopLossValue
            }
            return nil
        }()
        
        let takeProfit: Double? = {
            if let takeProfitValue = takeProfitPrice.toDouble, takeProfitValue > 0 {
                return takeProfitValue
            }
            return nil
        }()
        
        let tradeCoin = displayCoin
        
        if orderType == .limit {
            guard let limitPriceValue = limitPrice.toDouble, limitPriceValue > 0 else {
                ErrorHandler.shared.handle(.invalidInput("Geçerli bir limit fiyatı girin"))
                HapticFeedback.error()
                return
            }
            viewModel.createLimitOrder(
                coin: tradeCoin,
                amount: amount,
                limitPrice: limitPriceValue,
                stopLoss: stopLoss,
                takeProfit: takeProfit
            )
            HapticFeedback.success()
            tradeAmount = ""
            stopLossPrice = ""
            limitPrice = ""
            takeProfitPrice = ""
            onDismiss()
        } else {
            // Execute market order immediately
            if isBuying {
                viewModel.buyCoin(tradeCoin, amount: amount, price: tradeCoin.price, stopLoss: stopLoss)
            } else {
                viewModel.sellCoin(tradeCoin, amount: amount, price: tradeCoin.price)
            }
            
            HapticFeedback.success()
            tradeAmount = ""
            stopLossPrice = ""
            takeProfitPrice = ""
            onDismiss()
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }
}

struct QuickStopLossButton: View {
    let title: String
    let percentage: Double
    let currentPrice: Double
    @Binding var stopLossPrice: String
    
    var calculatedStopLoss: Double {
        currentPrice * (1 - percentage)
    }
    
    var body: some View {
        Button(action: {
            stopLossPrice = String(format: "%.0f", calculatedStopLoss)
        }) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.orange)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

struct TradeHistoryView: View {
    let trades: [Trade]
    @State private var searchText = ""
    @State private var selectedType: TradeType? = nil
    @State private var selectedCoin: String? = nil
    @Environment(\.dismiss) var dismiss
    
    var filteredTrades: [Trade] {
        var filtered = trades
        
        // Type filter
        if let type = selectedType {
            filtered = filtered.filter { $0.type == type }
        }
        
        // Coin filter
        if let coin = selectedCoin {
            filtered = filtered.filter { $0.coinSymbol == coin }
        }
        
        // Search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { trade in
                trade.coinSymbol.localizedCaseInsensitiveContains(searchText) ||
                trade.coinName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    var uniqueCoins: [String] {
        Array(Set(trades.map { $0.coinSymbol })).sorted()
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filters
                VStack(spacing: 12) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Ara...", text: $searchText)
                            .textFieldStyle(.plain)
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Type and coin filters
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            // Type filter
                            FilterChip(
                                title: "Tümü",
                                isSelected: selectedType == nil,
                                action: { selectedType = nil }
                            )
                            FilterChip(
                                title: "Alış",
                                isSelected: selectedType == .buy,
                                action: { selectedType = .buy }
                            )
                            FilterChip(
                                title: "Satış",
                                isSelected: selectedType == .sell,
                                action: { selectedType = .sell }
                            )
                            
                            // Coin filter
                            if !uniqueCoins.isEmpty {
                                Divider()
                                    .frame(height: 20)
                                
                                FilterChip(
                                    title: "Tüm Coinler",
                                    isSelected: selectedCoin == nil,
                                    action: { selectedCoin = nil }
                                )
                                
                                ForEach(uniqueCoins, id: \.self) { coin in
                                    FilterChip(
                                        title: coin,
                                        isSelected: selectedCoin == coin,
                                        action: { selectedCoin = coin }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 12)
                .background(Color(.systemGroupedBackground))
                
                // Trades list
                if filteredTrades.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "İşlem Bulunamadı",
                        message: "Filtre kriterlerinize uygun işlem bulunamadı."
                    )
                } else {
                    List(filteredTrades) { trade in
                        HStack {
                            Image(systemName: trade.type == .buy ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                                .foregroundColor(trade.type == .buy ? .green : .red)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(trade.type == .buy ? "Alındı" : "Satıldı") \(trade.coinSymbol)")
                                    .font(.headline)
                                
                                Text(trade.timestamp, style: .relative)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(String(format: "%.4f", trade.amount))
                                    .font(.subheadline)
                                
                                Text(trade.formattedTotal)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("İşlem Geçmişi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Tamam") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FilterButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticFeedback.selection()
            action()
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(
                        isSelected ?
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [Color(.systemGray6), Color(.systemGray6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticFeedback.selection()
            action()
        }) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemBackground))
                .cornerRadius(16)
        }
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Trade Sheet Components

struct CoinHeroHeader: View {
    let coin: Coin
    
    var body: some View {
        VStack(spacing: 16) {
            // Coin Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "bitcoinsign.circle.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(.blue)
            }
            
            // Coin Name & Symbol
            VStack(spacing: 4) {
                Text(coin.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(coin.symbol)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            // Price
            Text(coin.formattedPrice)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(coin.change24h >= 0 ? .green : .red)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            // 24h Change
            HStack(spacing: 6) {
                Image(systemName: coin.priceChangeIcon)
                    .font(.caption)
                Text(String(format: "%.2f%%", abs(coin.change24h)))
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(coin.change24h >= 0 ? .green : .red)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill((coin.change24h >= 0 ? Color.green : Color.red).opacity(0.15))
            )
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 5)
        )
    }
}

struct PortfolioInfoCard: View {
    let coin: Coin
    let amount: Double
    let value: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "wallet.pass.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
                
                Text("Portföyünüzde")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Miktar")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.4f \(coin.symbol)", amount))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    Text("Değer")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text(formatCurrency(value))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.green)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.green.opacity(0.1), Color.green.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }
    
    private func formatCurrency(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }
}

struct PriceStatisticsCard: View {
    let coin: Coin
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
                
                Text("Fiyat Bilgileri")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Güncel Fiyat")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    Text(coin.formattedPrice)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    Text("24 Saat Değişim")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    HStack(spacing: 4) {
                        Image(systemName: coin.priceChangeIcon)
                            .font(.system(size: 10))
                        Text(String(format: "%.2f%%", abs(coin.change24h)))
                            .font(.system(size: 16, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundColor(coin.change24h >= 0 ? .green : .red)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }
}

struct BuySellToggle: View {
    @Binding var isBuying: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            Button(action: { isBuying = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                    Text("Al")
                        .font(.system(size: 18, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    isBuying ?
                        LinearGradient(
                            colors: [Color.green, Color.green.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                )
                .foregroundColor(isBuying ? .white : .primary)
                .cornerRadius(16, corners: [.topLeft, .bottomLeft])
            }
            
            Button(action: { isBuying = false }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.circle.fill")
                    Text("Sat")
                        .font(.system(size: 18, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    !isBuying ?
                        LinearGradient(
                            colors: [Color.red, Color.red.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                )
                .foregroundColor(!isBuying ? .white : .primary)
                .cornerRadius(16, corners: [.topRight, .bottomRight])
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct AmountInputSection: View {
    let isBuying: Bool
    @Binding var tradeAmount: String
    let coin: Coin
    let balance: Double
    let portfolioAmount: Double
    
    private var maxAmount: Double {
        isBuying ? balance / coin.price : portfolioAmount
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(isBuying ? "Alınacak Miktar" : "Satılacak Miktar")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("Maks: \(String(format: "%.4f", maxAmount)) \(coin.symbol)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            
            TextField("0,0 veya 0.0", text: Binding(
                get: { self.tradeAmount },
                set: { newValue in
                    self.tradeAmount = newValue.replacingOccurrences(of: ",", with: ".")
                }
            ))
            .keyboardType(.decimalPad)
            .font(.system(size: 20, weight: .semibold))
            .padding(14)
            .background(Color(.systemGray6))
            .cornerRadius(14)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            
            if isBuying {
                HStack {
                    Text("Mevcut Bakiye:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatCurrency(balance))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            } else {
                HStack {
                    Text("Portföyünüzde:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(String(format: "%.4f", portfolioAmount)) \(coin.symbol)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }
    
    private func formatCurrency(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }
}

struct StopLossSection: View {
    let coin: Coin
    @Binding var stopLossPrice: String
    @Binding var showInfo: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.orange)
                    
                    Text("Stop Loss")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                
                Spacer()
                
                Button(action: { showInfo.toggle() }) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            
            Text("Fiyat bu seviyeye düştüğünde otomatik satış yapılır")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                TextField("Örn: 58000", text: Binding(
                    get: { self.stopLossPrice },
                    set: { newValue in
                        self.stopLossPrice = newValue.replacingOccurrences(of: ",", with: ".")
                    }
                ))
                .keyboardType(.decimalPad)
                .font(.system(size: 16, weight: .medium))
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                
                if let stopLoss = stopLossPrice.toDouble, stopLoss > 0 {
                    let percentage = ((coin.price - stopLoss) / coin.price) * 100
                    Text("%\(String(format: "%.1f", percentage))")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.orange, Color.orange.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
            }
            
            // Quick Stop Loss Buttons
            HStack(spacing: 8) {
                QuickStopLossButton(
                    title: "-2%",
                    percentage: 0.02,
                    currentPrice: coin.price,
                    stopLossPrice: $stopLossPrice
                )
                QuickStopLossButton(
                    title: "-3%",
                    percentage: 0.03,
                    currentPrice: coin.price,
                    stopLossPrice: $stopLossPrice
                )
                QuickStopLossButton(
                    title: "-5%",
                    percentage: 0.05,
                    currentPrice: coin.price,
                    stopLossPrice: $stopLossPrice
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.orange.opacity(0.05))
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
        .alert("Stop Loss Nedir?", isPresented: $showInfo) {
            Button("Anladım", role: .cancel) {}
        } message: {
            Text("Stop Loss, fiyat belirli bir seviyeye düştüğünde pozisyonunuzu otomatik olarak satan bir risk yönetimi aracıdır. Örneğin Bitcoin'i 60.000$'dan alıp stop loss'u 58.000$'a ayarlarsanız, fiyat 58.000$'a düştüğünde otomatik satış yapılır.")
        }
    }
}

struct TradeSummaryCard: View {
    let coin: Coin
    let amount: Double
    let totalCost: Double
    let isBuying: Bool
    let stopLoss: Double?
    let limitPrice: Double?
    let takeProfit: Double?
    let orderType: OrderExecutionType
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
                
                Text("İşlem Özeti")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 10) {
                HStack {
                    Text("İşlem Tipi:")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(isBuying ? "Alış" : "Satış")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isBuying ? .green : .red)
                        .lineLimit(1)
                }
                
                HStack {
                    Text("Coin:")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(coin.symbol)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                
                HStack {
                    Text("Birim Fiyat:")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(coin.formattedPrice)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                
                HStack {
                    Text("Miktar:")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(String(format: "%.4f", amount)) \(coin.symbol)")
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                
                HStack {
                    Text("Emir Tipi:")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(orderType == .market ? "Piyasa" : "Limit")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(orderType == .market ? .blue : .purple)
                        .lineLimit(1)
                }
                
                if let limitPrice = limitPrice {
                    HStack {
                        Text("Limit Fiyat:")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatCurrency(limitPrice))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.purple)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                
                if let stopLoss = stopLoss {
                    HStack {
                        Text("Stop Loss:")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatCurrency(stopLoss))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.orange)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                
                if let takeProfit = takeProfit {
                    HStack {
                        Text("Kâr Al:")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatCurrency(takeProfit))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.green)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                
                Divider()
                
                HStack {
                    Text("Toplam Tutar:")
                        .font(.system(size: 16, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer()
                    Text(formatCurrency(totalCost))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(isBuying ? .green : .red)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
        .padding(16)
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

struct QuickAmountSection: View {
    let coin: Coin
    let balance: Double
    @Binding var tradeAmount: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hızlı Miktar")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            HStack(spacing: 8) {
                QuickAmountButton(
                    title: "%25",
                    percentage: 0.25,
                    coin: coin,
                    balance: balance,
                    tradeAmount: $tradeAmount
                )
                QuickAmountButton(
                    title: "%50",
                    percentage: 0.50,
                    coin: coin,
                    balance: balance,
                    tradeAmount: $tradeAmount
                )
                QuickAmountButton(
                    title: "%75",
                    percentage: 0.75,
                    coin: coin,
                    balance: balance,
                    tradeAmount: $tradeAmount
                )
                QuickAmountButton(
                    title: "Max",
                    percentage: 1.0,
                    coin: coin,
                    balance: balance,
                    tradeAmount: $tradeAmount
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }
}

struct QuickAmountButton: View {
    let title: String
    let percentage: Double
    let coin: Coin
    let balance: Double
    @Binding var tradeAmount: String
    
    var body: some View {
        Button(action: {
            let maxAmount = balance / coin.price
            tradeAmount = String(format: "%.4f", maxAmount * percentage)
        }) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.blue.opacity(0.1))
                )
                .foregroundColor(.blue)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

struct ExecuteTradeButton: View {
    let coin: Coin
    let isBuying: Bool
    let canExecute: Bool
    let onExecute: () -> Void
    
    var body: some View {
        Button(action: onExecute) {
            HStack(spacing: 8) {
                Image(systemName: isBuying ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 18))
                
                Text(isBuying ? "\(coin.symbol) Satın Al" : "\(coin.symbol) Sat")
                    .font(.system(size: 16, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                canExecute ?
                    LinearGradient(
                        colors: isBuying ? [Color.green, Color.green.opacity(0.8)] : [Color.red, Color.red.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) :
                    LinearGradient(
                        colors: [Color.gray, Color.gray.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
            )
            .foregroundColor(.white)
            .cornerRadius(20)
            .shadow(color: (canExecute ? (isBuying ? Color.green : Color.red) : Color.gray).opacity(0.3), radius: 15, x: 0, y: 8)
        }
        .disabled(!canExecute)
    }
}

struct CoinFilterSheet: View {
    @Binding var filter: CoinFilter
    @Environment(\.dismiss) var dismiss
    @State private var minPriceText = ""
    @State private var maxPriceText = ""
    @State private var minChangeText = ""
    @State private var maxChangeText = ""
    @State private var hasPortfolioFilter: Bool? = nil
    @State private var isFavoriteFilter: Bool? = nil
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Fiyat Aralığı") {
                    HStack {
                        Text("Min Fiyat")
                        Spacer()
                        TextField("$0", text: $minPriceText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    
                    HStack {
                        Text("Max Fiyat")
                        Spacer()
                        TextField("$∞", text: $maxPriceText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                }
                
                Section("24 Saat Değişim") {
                    HStack {
                        Text("Min Değişim (%)")
                        Spacer()
                        TextField("-100", text: $minChangeText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    
                    HStack {
                        Text("Max Değişim (%)")
                        Spacer()
                        TextField("100", text: $maxChangeText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                }
                
                Section("Portföy") {
                    Picker("Portföy Durumu", selection: $hasPortfolioFilter) {
                        Text("Tümü").tag(nil as Bool?)
                        Text("Portföyde Var").tag(true as Bool?)
                        Text("Portföyde Yok").tag(false as Bool?)
                    }
                }
                
                Section("Favoriler") {
                    Picker("Favori Durumu", selection: $isFavoriteFilter) {
                        Text("Tümü").tag(nil as Bool?)
                        Text("Favoriler").tag(true as Bool?)
                        Text("Favori Değil").tag(false as Bool?)
                    }
                }
            }
            .navigationTitle("Filtrele")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Temizle") {
                        filter = CoinFilter()
                        minPriceText = ""
                        maxPriceText = ""
                        minChangeText = ""
                        maxChangeText = ""
                        hasPortfolioFilter = nil
                        isFavoriteFilter = nil
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Uygula") {
                        applyFilters()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                loadFilters()
            }
        }
    }
    
    private func loadFilters() {
        if let minPrice = filter.minPrice {
            minPriceText = String(format: "%.2f", minPrice)
        }
        if let maxPrice = filter.maxPrice {
            maxPriceText = String(format: "%.2f", maxPrice)
        }
        if let minChange = filter.minChange24h {
            minChangeText = String(format: "%.2f", minChange)
        }
        if let maxChange = filter.maxChange24h {
            maxChangeText = String(format: "%.2f", maxChange)
        }
        hasPortfolioFilter = filter.hasPortfolio
        isFavoriteFilter = filter.isFavorite
    }
    
    private func applyFilters() {
        filter.minPrice = minPriceText.isEmpty ? nil : minPriceText.toDouble
        filter.maxPrice = maxPriceText.isEmpty ? nil : maxPriceText.toDouble
        filter.minChange24h = minChangeText.isEmpty ? nil : minChangeText.toDouble
        filter.maxChange24h = maxChangeText.isEmpty ? nil : maxChangeText.toDouble
        filter.hasPortfolio = hasPortfolioFilter
        filter.isFavorite = isFavoriteFilter
    }
}

// MARK: - Order Type Components

struct OrderTypeSelector: View {
    @Binding var orderType: OrderExecutionType
    @Binding var showInfo: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                    
                    Text("Emir Tipi")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Button(action: { showInfo.toggle() }) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 16))
                }
            }
            
            HStack(spacing: 0) {
                Button(action: { orderType = .market }) {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 14))
                        Text("Piyasa")
                            .font(.system(size: 14, weight: .bold))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        orderType == .market ?
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                    )
                    .foregroundColor(orderType == .market ? .white : .primary)
                    .cornerRadius(12, corners: [.topLeft, .bottomLeft])
                }
                
                Button(action: { orderType = .limit }) {
                    HStack(spacing: 6) {
                        Image(systemName: "target")
                            .font(.system(size: 14))
                        Text("Limit")
                            .font(.system(size: 14, weight: .bold))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        orderType == .limit ?
                            LinearGradient(
                                colors: [Color.purple, Color.purple.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                    )
                    .foregroundColor(orderType == .limit ? .white : .primary)
                    .cornerRadius(12, corners: [.topRight, .bottomRight])
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
        .alert("Emir Tipleri", isPresented: $showInfo) {
            Button("Anladım", role: .cancel) {}
        } message: {
            Text("Piyasa Emri: Anında mevcut fiyattan işlem yapar.\nLimit Emri: Belirlediğiniz fiyata ulaştığında otomatik işlem yapar.")
        }
    }
}

struct LimitPriceSection: View {
    let coin: Coin
    @Binding var limitPrice: String
    let isBuying: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "target")
                        .font(.system(size: 16))
                        .foregroundColor(.purple)
                    
                    Text("Limit Fiyat")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Text("Güncel: \(coin.formattedPrice)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            
            TextField("Örn: \(String(format: "%.0f", coin.price))", text: Binding(
                get: { self.limitPrice },
                set: { newValue in
                    self.limitPrice = newValue.replacingOccurrences(of: ",", with: ".")
                }
            ))
            .keyboardType(.decimalPad)
            .font(.system(size: 18, weight: .medium))
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            
            Text(isBuying ? "Fiyat bu seviyeye düştüğünde alış yapılacak" : "Fiyat bu seviyeye ulaştığında satış yapılacak")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.purple.opacity(0.05))
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }
}

struct TakeProfitSection: View {
    let coin: Coin
    @Binding var takeProfitPrice: String
    let isBuying: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.right.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.green)
                    
                    Text("Kâr Al (Opsiyonel)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            
            TextField("Örn: \(String(format: "%.0f", coin.price * 1.1))", text: Binding(
                get: { self.takeProfitPrice },
                set: { newValue in
                    self.takeProfitPrice = newValue.replacingOccurrences(of: ",", with: ".")
                }
            ))
            .keyboardType(.decimalPad)
            .font(.system(size: 16, weight: .medium))
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            
            if let takeProfit = takeProfitPrice.toDouble, takeProfit > 0 {
                let percentage = ((takeProfit - coin.price) / coin.price) * 100
                HStack(spacing: 4) {
                    Image(systemName: percentage >= 0 ? "arrow.up" : "arrow.down")
                        .font(.system(size: 10))
                    Text("%\(String(format: "%.1f", abs(percentage)))")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(percentage >= 0 ? .green : .red)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.green.opacity(0.05))
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }
}

#Preview {
    TradeView(viewModel: TradingViewModel())
}


