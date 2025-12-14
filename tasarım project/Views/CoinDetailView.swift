//
//  CoinDetailView.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import SwiftUI
import Charts

struct CoinDetailView: View {
    let coin: Coin
    @ObservedObject var viewModel: TradingViewModel
    @ObservedObject var dataManager = DataManager.shared
    @ObservedObject var chartService = CoinChartService.shared
    @ObservedObject var detailService = CoinDetailService.shared
    @State private var selectedTimeframe = 7 // days
    @State private var showingTradeSheet = false
    @State private var isBuying = true
    @State private var tradeAmount = ""
    @State private var coinDetail: CoinDetail?
    @State private var isLoadingDetails = false
    @State private var showingPriceAlertSheet = false
    @State private var showingLimitOrderSheet = false
    @Environment(\.dismiss) var dismiss
    
    // Get current coin price from dataManager
    private var currentCoin: Coin? {
        dataManager.coins.first(where: { $0.id == coin.id || $0.symbol == coin.symbol })
    }
    
    private var displayCoin: Coin {
        currentCoin ?? coin
    }
    
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
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Hero Header
                        CoinDetailHeader(coin: displayCoin)
                            .padding(.horizontal)
                            .padding(.top)
                        
                        // Portfolio Info (if owned)
                        if hasPortfolio {
                            PortfolioDetailCard(
                                coin: displayCoin,
                                amount: portfolioAmount,
                                value: portfolioValue
                            )
                            .padding(.horizontal)
                        }
                        
                        // Price Chart Section
                        ChartSection(
                            coin: displayCoin,
                            chartService: chartService,
                            selectedTimeframe: $selectedTimeframe
                        )
                        .padding(.horizontal)
                        
                        // Extended Statistics Grid
                        ExtendedStatisticsGrid(coin: displayCoin, coinDetail: coinDetail)
                            .padding(.horizontal)
                        
                        // Market Analysis
                        MarketAnalysisSection(coin: displayCoin, coinDetail: coinDetail)
                            .padding(.horizontal)
                        
                        // Price Performance
                        PricePerformanceSection(coin: displayCoin, coinDetail: coinDetail)
                            .padding(.horizontal)
                        
                        // Supply Information
                        if coinDetail != nil {
                            SupplyInfoSection(coinDetail: coinDetail!)
                                .padding(.horizontal)
                        }
                        
                        // All-Time High/Low
                        if coinDetail != nil {
                            ATHATLSection(coin: displayCoin, coinDetail: coinDetail!)
                                .padding(.horizontal)
                        }
                        
                        // Market Info
                        MarketInfoSection(coin: displayCoin)
                            .padding(.horizontal)
                        
                        // Quick Actions Section
                        CoinQuickActionsSection(
                            coin: displayCoin,
                            onPriceAlert: {
                                showingPriceAlertSheet = true
                            },
                            onLimitOrder: {
                                showingLimitOrderSheet = true
                            },
                            onTrade: {
                                showingTradeSheet = true
                            }
                        )
                        .padding(.horizontal)
                        
                        // Action Button
                        Button(action: {
                            showingTradeSheet = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.left.arrow.right.circle.fill")
                                    .font(.system(size: 20, weight: .medium))
                                Text("İşlem Yap")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle(displayCoin.name)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadCoinDetails()
            }
            .refreshable {
                loadCoinDetails()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticFeedback.selection()
                        viewModel.toggleFavorite(coinSymbol: displayCoin.symbol)
                    }) {
                        Image(systemName: viewModel.isFavorite(coinSymbol: displayCoin.symbol) ? "star.fill" : "star")
                            .foregroundColor(viewModel.isFavorite(coinSymbol: displayCoin.symbol) ? .yellow : .secondary)
                    }
                }
            }
            .onAppear {
                chartService.fetchChartData(for: displayCoin.id, days: selectedTimeframe)
            }
            .onChange(of: selectedTimeframe) { oldValue, newValue in
                chartService.fetchChartData(for: displayCoin.id, days: newValue)
            }
            .sheet(isPresented: $showingPriceAlertSheet) {
                QuickPriceAlertSheet(coin: displayCoin, viewModel: viewModel)
            }
            .sheet(isPresented: $showingLimitOrderSheet) {
                QuickLimitOrderSheet(coin: displayCoin, viewModel: viewModel)
            }
            .sheet(isPresented: $showingTradeSheet) {
                TradeSheet(
                    coin: displayCoin,
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
    }
    
    private func loadCoinDetails() {
        isLoadingDetails = true
        detailService.fetchCoinDetails(coinId: displayCoin.id) { [self] detail in
            self.coinDetail = detail
            self.isLoadingDetails = false
        }
    }
}

struct CoinDetailHeader: View {
    let coin: Coin
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center, spacing: 16) {
                // Coin Icon Placeholder
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 64, height: 64)
                    
                    Text(coin.symbol.prefix(1))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(coin.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(coin.symbol)
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    Text(coin.formattedPrice)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    
                    HStack(spacing: 4) {
                        Image(systemName: coin.priceChangeIcon)
                            .font(.system(size: 12))
                        Text(String(format: "%.2f%%", coin.change24h))
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(coin.change24h >= 0 ? .green : .red)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }
}

struct PortfolioDetailCard: View {
    let coin: Coin
    let amount: Double
    let value: Double
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Portföyünüz")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Miktar")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(String(format: "%.4f %@", amount, coin.symbol))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Değer")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(formatCurrency(value))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.green)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
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

struct ChartSection: View {
    let coin: Coin
    @ObservedObject var chartService: CoinChartService
    @Binding var selectedTimeframe: Int
    
    var body: some View {
        VStack(spacing: 16) {
            // Timeframe Selector
            HStack {
                Text("Fiyat Grafiği")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    TimeframeButton(title: "7G", days: 7, selected: selectedTimeframe == 7) {
                        selectedTimeframe = 7
                    }
                    TimeframeButton(title: "30G", days: 30, selected: selectedTimeframe == 30) {
                        selectedTimeframe = 30
                    }
                    TimeframeButton(title: "90G", days: 90, selected: selectedTimeframe == 90) {
                        selectedTimeframe = 90
                    }
                }
            }
            
            // Chart
            if chartService.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Grafik yükleniyor...")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
            } else if let error = chartService.error {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 32))
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 200)
            } else if !chartService.chartData.isEmpty {
                Chart {
                    ForEach(chartService.chartData) { point in
                        LineMark(
                            x: .value("Tarih", point.timestamp, unit: .day),
                            y: .value("Fiyat", point.price)
                        )
                        .foregroundStyle(Color.blue)
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: selectedTimeframe == 7 ? 1 : selectedTimeframe == 30 ? 5 : 10)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text(formatPrice(doubleValue))
                            }
                        }
                    }
                }
                .frame(height: 200)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("Grafik verisi bulunamadı")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }
    
    private func formatPrice(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "$%.0f", value)
        } else if value >= 1 {
            return String(format: "$%.2f", value)
        } else {
            return String(format: "$%.4f", value)
        }
    }
}

struct TimeframeButton: View {
    let title: String
    let days: Int
    let selected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(selected ? .white : .blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(selected ? Color.blue : Color.blue.opacity(0.1))
                )
        }
    }
}

struct StatisticsGrid: View {
    let coin: Coin
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("İstatistikler")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                CoinStatItem(
                    title: "24 Saat Değişim",
                    value: String(format: "%.2f%%", coin.change24h),
                    icon: coin.priceChangeIcon,
                    color: coin.change24h >= 0 ? .green : .red
                )
                
                CoinStatItem(
                    title: "Güncel Fiyat",
                    value: coin.formattedPrice,
                    icon: "dollarsign.circle.fill",
                    color: .blue
                )
                
                CoinStatItem(
                    title: "Sembol",
                    value: coin.symbol,
                    icon: "tag.fill",
                    color: .blue
                )
                
                CoinStatItem(
                    title: "Coin ID",
                    value: coin.id,
                    icon: "number.circle.fill",
                    color: .blue
                )
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }
}

struct CoinStatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct MarketInfoSection: View {
    let coin: Coin
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Piyasa Bilgileri")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                InfoRow(label: "Coin Adı", value: coin.name)
                InfoRow(label: "Sembol", value: coin.symbol)
                InfoRow(label: "Güncel Fiyat", value: coin.formattedPrice)
                InfoRow(
                    label: "24 Saat Değişim",
                    value: String(format: "%.2f%%", coin.change24h),
                    valueColor: coin.change24h >= 0 ? .green : .red
                )
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.vertical, 4)
    }
}

// Fallback chart view if Charts framework is not available
struct SimpleLineChart: View {
    let data: [ChartDataPoint]
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            if data.isEmpty {
                EmptyView()
            } else {
                let minPrice = data.map { $0.price }.min() ?? 0
                let maxPrice = data.map { $0.price }.max() ?? 1
                let priceRange = maxPrice - minPrice
                
                Path { path in
                    for (index, point) in data.enumerated() {
                        let x = CGFloat(index) / CGFloat(max(data.count - 1, 1)) * width
                        let normalizedPrice = priceRange > 0 ? (point.price - minPrice) / priceRange : 0.5
                        let y = height - (normalizedPrice * height)
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.blue, lineWidth: 2)
                .background(
                    Path { path in
                        for (index, point) in data.enumerated() {
                            let x = CGFloat(index) / CGFloat(max(data.count - 1, 1)) * width
                            let normalizedPrice = priceRange > 0 ? (point.price - minPrice) / priceRange : 0.5
                            let y = height - (normalizedPrice * height)
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: height))
                                path.addLine(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                        // Close the path
                        if let lastX = data.last {
                            let x = CGFloat(data.count - 1) / CGFloat(max(data.count - 1, 1)) * width
                            path.addLine(to: CGPoint(x: x, y: height))
                        }
                    }
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                )
            }
        }
    }
}

// MARK: - Extended Statistics Grid

struct ExtendedStatisticsGrid: View {
    let coin: Coin
    let coinDetail: CoinDetail?
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Detaylı İstatistikler")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                CoinStatItem(
                    title: "24 Saat Değişim",
                    value: String(format: "%.2f%%", coin.change24h),
                    icon: coin.priceChangeIcon,
                    color: coin.change24h >= 0 ? .green : .red
                )
                
                CoinStatItem(
                    title: "Güncel Fiyat",
                    value: coin.formattedPrice,
                    icon: "dollarsign.circle.fill",
                    color: .blue
                )
                
                if let marketCap = coin.marketCap ?? coinDetail?.marketCap {
                    CoinStatItem(
                        title: "Market Cap",
                        value: formatLargeNumber(marketCap, prefix: "$"),
                        icon: "chart.bar.fill",
                        color: .purple
                    )
                }
                
                if let volume = coin.totalVolume ?? coinDetail?.totalVolume {
                    CoinStatItem(
                        title: "24h Hacim",
                        value: formatLargeNumber(volume, prefix: "$"),
                        icon: "arrow.up.arrow.down.circle.fill",
                        color: .orange
                    )
                }
            }
        }
        .padding(18)
        .modernCard()
    }
    
    private func formatLargeNumber(_ value: Double, prefix: String = "") -> String {
        if value >= 1_000_000_000_000 {
            return "\(prefix)\(String(format: "%.2fT", value / 1_000_000_000_000))"
        } else if value >= 1_000_000_000 {
            return "\(prefix)\(String(format: "%.2fB", value / 1_000_000_000))"
        } else if value >= 1_000_000 {
            return "\(prefix)\(String(format: "%.2fM", value / 1_000_000))"
        } else {
            return "\(prefix)\(String(format: "%.2f", value))"
        }
    }
}

// MARK: - Market Analysis Section

struct MarketAnalysisSection: View {
    let coin: Coin
    let coinDetail: CoinDetail?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.primaryGradient)
                
                Text("Piyasa Analizi")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            if let marketCap = coin.marketCap ?? coinDetail?.marketCap,
               let volume = coin.totalVolume ?? coinDetail?.totalVolume {
                VStack(spacing: 12) {
                    // Market Cap to Volume Ratio
                    AnalysisRow(
                        title: "Market Cap / Hacim Oranı",
                        value: String(format: "%.2f", marketCap / max(volume, 1)),
                        description: marketCap / max(volume, 1) > 10 ? "Yüksek likidite" : "Düşük likidite",
                        color: marketCap / max(volume, 1) > 10 ? .green : .orange
                    )
                    
                    // Volume Analysis
                    if volume > 0 {
                        AnalysisRow(
                            title: "Hacim Analizi",
                            value: formatVolume(volume),
                            description: volume > 100_000_000 ? "Yüksek hacim" : "Normal hacim",
                            color: volume > 100_000_000 ? .green : .blue
                        )
                    }
                }
            } else {
                Text("Veri yükleniyor...")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
        .padding(18)
        .modernCard()
    }
    
    private func formatVolume(_ value: Double) -> String {
        if value >= 1_000_000_000 {
            return String(format: "$%.2fB", value / 1_000_000_000)
        } else if value >= 1_000_000 {
            return String(format: "$%.2fM", value / 1_000_000)
        } else {
            return String(format: "$%.2f", value)
        }
    }
}

struct AnalysisRow: View {
    let title: String
    let value: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(color)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Price Performance Section

struct PricePerformanceSection: View {
    let coin: Coin
    let coinDetail: CoinDetail?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.primaryGradient)
                
                Text("Fiyat Performansı")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                if let change7d = coinDetail?.priceChange7d {
                    PerformanceRow(
                        period: "7 Gün",
                        change: change7d,
                        icon: "calendar"
                    )
                }
                
                if let change30d = coinDetail?.priceChange30d {
                    PerformanceRow(
                        period: "30 Gün",
                        change: change30d,
                        icon: "calendar.badge.clock"
                    )
                }
                
                if let change1y = coinDetail?.priceChange1y {
                    PerformanceRow(
                        period: "1 Yıl",
                        change: change1y,
                        icon: "calendar.badge.exclamationmark"
                    )
                }
                
                PerformanceRow(
                    period: "24 Saat",
                    change: coin.change24h,
                    icon: "clock"
                )
            }
        }
        .padding(18)
        .modernCard()
    }
}

struct PerformanceRow: View {
    let period: String
    let change: Double
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(period)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                    .font(.system(size: 12))
                Text(String(format: "%.2f%%", change))
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(change >= 0 ? .green : .red)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill((change >= 0 ? Color.green : Color.red).opacity(0.15))
            )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Supply Information Section

struct SupplyInfoSection: View {
    let coinDetail: CoinDetail
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "infinity.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.primaryGradient)
                
                Text("Arz Bilgileri")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                if let circulating = coinDetail.circulatingSupply {
                    SupplyRow(
                        title: "Dolaşımdaki Arz",
                        value: formatSupply(circulating),
                        icon: "arrow.triangle.2.circlepath"
                    )
                }
                
                if let total = coinDetail.totalSupply {
                    SupplyRow(
                        title: "Toplam Arz",
                        value: formatSupply(total),
                        icon: "number.circle.fill"
                    )
                }
                
                if let max = coinDetail.maxSupply {
                    SupplyRow(
                        title: "Maksimum Arz",
                        value: formatSupply(max),
                        icon: "arrow.up.circle.fill"
                    )
                }
            }
        }
        .padding(18)
        .modernCard()
    }
    
    private func formatSupply(_ value: Double) -> String {
        if value >= 1_000_000_000 {
            return String(format: "%.2fB", value / 1_000_000_000)
        } else if value >= 1_000_000 {
            return String(format: "%.2fM", value / 1_000_000)
        } else {
            return String(format: "%.2f", value)
        }
    }
}

struct SupplyRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - ATH/ATL Section

struct ATHATLSection: View {
    let coin: Coin
    let coinDetail: CoinDetail
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.primaryGradient)
                
                Text("Tüm Zamanların Rekorları")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                if let ath = coinDetail.ath {
                    ATHATLRow(
                        title: "Tüm Zamanların En Yükseği (ATH)",
                        value: String(format: "$%.2f", ath),
                        date: coinDetail.athDate,
                        currentPrice: coin.price,
                        isATH: true
                    )
                }
                
                if let atl = coinDetail.atl {
                    ATHATLRow(
                        title: "Tüm Zamanların En Düşüğü (ATL)",
                        value: String(format: "$%.2f", atl),
                        date: coinDetail.atlDate,
                        currentPrice: coin.price,
                        isATH: false
                    )
                }
            }
        }
        .padding(18)
        .modernCard()
    }
}

struct ATHATLRow: View {
    let title: String
    let value: String
    let date: String?
    let currentPrice: Double
    let isATH: Bool
    
    private var percentage: Double {
        if isATH {
            return ((currentPrice - Double(value.replacingOccurrences(of: "$", with: ""))!) / Double(value.replacingOccurrences(of: "$", with: ""))!) * 100
        } else {
            return ((currentPrice - Double(value.replacingOccurrences(of: "$", with: ""))!) / Double(value.replacingOccurrences(of: "$", with: ""))!) * 100
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            HStack {
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let date = date {
                    Text(formatDate(date))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 4) {
                Image(systemName: isATH ? "arrow.up" : "arrow.down")
                    .font(.system(size: 12))
                Text(String(format: "%.2f%%", abs(percentage)))
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(isATH ? (percentage < 0 ? .red : .green) : (percentage > 0 ? .green : .red))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .none
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

// MARK: - Coin Quick Actions Section

struct CoinQuickActionsSection: View {
    let coin: Coin
    let onPriceAlert: () -> Void
    let onLimitOrder: () -> Void
    let onTrade: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hızlı İşlemler")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal, 4)
            
            HStack(spacing: 12) {
                // Price Alert Button
                QuickActionButton(
                    title: "Fiyat Alarmı",
                    icon: "bell.fill",
                    color: .orange,
                    action: onPriceAlert
                )
                
                // Limit Order Button
                QuickActionButton(
                    title: "Limit Emri",
                    icon: "list.bullet.rectangle.portrait.fill",
                    color: .purple,
                    action: onLimitOrder
                )
                
                // Trade Button
                QuickActionButton(
                    title: "İşlem Yap",
                    icon: "arrow.left.arrow.right.circle.fill",
                    color: .blue,
                    action: onTrade
                )
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticFeedback.selection()
            action()
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(color)
                    .frame(height: 30)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

// MARK: - Quick Price Alert Sheet

struct QuickPriceAlertSheet: View {
    let coin: Coin
    @ObservedObject var viewModel: TradingViewModel
    @Environment(\.dismiss) var dismiss
    @State private var targetPrice: String = ""
    @State private var condition: AlertCondition = .above
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Text("Coin")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(coin.symbol) - \(coin.name)")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    
                    TextField("Hedef Fiyat", text: $targetPrice)
                        .keyboardType(.decimalPad)
                        .textInputAutocapitalization(.never)
                    
                    Picker("Koşul", selection: $condition) {
                        Text("Üzerinde").tag(AlertCondition.above)
                        Text("Altında").tag(AlertCondition.below)
                    }
                } header: {
                    Text("Alarm Detayları")
                } footer: {
                    Text("Fiyat \(condition == .above ? "üzerine" : "altına") düştüğünde bildirim alacaksınız.")
                }
                
                if let price = Double(targetPrice), price > 0 {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Özet")
                                .font(.headline)
                            
                            Text("\(coin.symbol) fiyatı \(formatCurrency(price)) seviyesinin \(condition == .above ? "üzerine" : "altına") düştüğünde bildirim gönderilecek.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Fiyat Alarmı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        if let price = Double(targetPrice) {
                            viewModel.createPriceAlert(
                                coin: coin,
                                targetPrice: price,
                                condition: condition
                            )
                            HapticFeedback.success()
                            dismiss()
                        }
                    }
                    .disabled(targetPrice.isEmpty || Double(targetPrice) == nil)
                }
            }
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }
}

// MARK: - Quick Limit Order Sheet

struct QuickLimitOrderSheet: View {
    let coin: Coin
    @ObservedObject var viewModel: TradingViewModel
    @Environment(\.dismiss) var dismiss
    @State private var amount: String = ""
    @State private var limitPrice: String = ""
    @State private var orderType: OrderType = .limitBuy
    @State private var stopLoss: String = ""
    @State private var takeProfit: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Text("Coin")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(coin.symbol) - \(coin.name)")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    
                    Picker("Emir Tipi", selection: $orderType) {
                        Text("Limit Alış").tag(OrderType.limitBuy)
                        Text("Limit Satış").tag(OrderType.limitSell)
                    }
                    
                    TextField("Miktar", text: $amount)
                        .keyboardType(.decimalPad)
                        .textInputAutocapitalization(.never)
                    
                    TextField("Limit Fiyat", text: $limitPrice)
                        .keyboardType(.decimalPad)
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("Emir Detayları")
                } footer: {
                    Text("Fiyat limit fiyata ulaştığında emir otomatik olarak gerçekleştirilecek.")
                }
                
                Section {
                    TextField("Stop Loss (Opsiyonel)", text: $stopLoss)
                        .keyboardType(.decimalPad)
                        .textInputAutocapitalization(.never)
                    
                    TextField("Take Profit (Opsiyonel)", text: $takeProfit)
                        .keyboardType(.decimalPad)
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("Risk Yönetimi")
                } footer: {
                    Text("Stop Loss ve Take Profit seviyelerini belirleyebilirsiniz.")
                }
                
                if let amountValue = Double(amount), let limitPriceValue = Double(limitPrice),
                   amountValue > 0, limitPriceValue > 0 {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Özet")
                                .font(.headline)
                            
                            Text("\(orderType == .limitBuy ? "Alış" : "Satış") emri: \(String(format: "%.4f", amountValue)) \(coin.symbol) @ \(formatCurrency(limitPriceValue))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if let stopLossValue = Double(stopLoss), stopLossValue > 0 {
                                Text("Stop Loss: \(formatCurrency(stopLossValue))")
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                            }
                            
                            if let takeProfitValue = Double(takeProfit), takeProfitValue > 0 {
                                Text("Take Profit: \(formatCurrency(takeProfitValue))")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Limit Emri")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Oluştur") {
                        if let amountValue = Double(amount), let limitPriceValue = Double(limitPrice) {
                            let stopLossValue = stopLoss.isEmpty ? nil : Double(stopLoss)
                            let takeProfitValue = takeProfit.isEmpty ? nil : Double(takeProfit)
                            
                            viewModel.createLimitOrder(
                                coin: coin,
                                amount: amountValue,
                                limitPrice: limitPriceValue,
                                stopLoss: stopLossValue,
                                takeProfit: takeProfitValue
                            )
                            HapticFeedback.success()
                            dismiss()
                        }
                    }
                    .disabled(amount.isEmpty || limitPrice.isEmpty || Double(amount) == nil || Double(limitPrice) == nil)
                }
            }
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }
}

#Preview {
    CoinDetailView(
        coin: Coin(id: "bitcoin", symbol: "BTC", name: "Bitcoin", price: 50000, change24h: 2.5),
        viewModel: TradingViewModel()
    )
}

