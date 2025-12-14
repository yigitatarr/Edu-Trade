//
//  AdvancedPortfolioAnalysisView.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import SwiftUI
import Charts

struct AdvancedPortfolioAnalysisView: View {
    @ObservedObject var tradingVM: TradingViewModel
    @ObservedObject var dataManager = DataManager.shared
    @State private var selectedTimeframe: AnalysisTimeframe = .all
    
    enum AnalysisTimeframe: String, CaseIterable {
        case week = "7 Gün"
        case month = "30 Gün"
        case threeMonths = "3 Ay"
        case all = "Tümü"
    }
    
    private var portfolio: [String: Double] {
        tradingVM.user.portfolio
    }
    
    private var portfolioValue: Double {
        tradingVM.calculateTotalPortfolioValue(with: dataManager.coins)
    }
    
    private var portfolioDistribution: [(coin: Coin, amount: Double, value: Double, percentage: Double)] {
        var distribution: [(coin: Coin, amount: Double, value: Double, percentage: Double)] = []
        
        for (symbol, amount) in portfolio {
            if let coin = dataManager.coins.first(where: { $0.symbol == symbol }),
               amount > 0 {
                let value = amount * coin.price
                let percentage = portfolioValue > 0 ? (value / portfolioValue) * 100 : 0
                distribution.append((coin: coin, amount: amount, value: value, percentage: percentage))
            }
        }
        
        return distribution.sorted { $0.value > $1.value }
    }
    
    private var riskMetrics: RiskMetrics {
        calculateRiskMetrics()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Timeframe Selector
                Picker("Zaman Dilimi", selection: $selectedTimeframe) {
                    ForEach(AnalysisTimeframe.allCases, id: \.self) { timeframe in
                        Text(timeframe.rawValue).tag(timeframe)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top)
                
                // Portfolio Overview
                PortfolioOverviewCard(
                    totalValue: portfolioValue,
                    initialBalance: 100000.0,
                    distribution: portfolioDistribution
                )
                .padding(.horizontal)
                
                // Risk Analysis
                RiskAnalysisCard(metrics: riskMetrics)
                    .padding(.horizontal)
                
                // Coin Distribution
                CoinDistributionCard(distribution: portfolioDistribution)
                    .padding(.horizontal)
                
                // Performance Metrics
                PerformanceMetricsCard(
                    tradingVM: tradingVM,
                    portfolioValue: portfolioValue
                )
                .padding(.horizontal)
                
                // Top Performers
                TopPerformersCard(distribution: portfolioDistribution)
                    .padding(.horizontal)
                
                // Recommendations
                RecommendationsCard(metrics: riskMetrics, distribution: portfolioDistribution)
                    .padding(.horizontal)
                    .padding(.bottom)
            }
        }
        .navigationTitle("Gelişmiş Analiz")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground))
    }
    
    private func calculateRiskMetrics() -> RiskMetrics {
        let trades = tradingVM.trades
        let coins = dataManager.coins
        
        // Calculate volatility
        var priceChanges: [Double] = []
        for (symbol, _) in portfolio {
            if let coin = coins.first(where: { $0.symbol == symbol }) {
                priceChanges.append(abs(coin.change24h))
            }
        }
        let volatility = priceChanges.isEmpty ? 0 : priceChanges.reduce(0, +) / Double(priceChanges.count)
        
        // Calculate diversification score (0-100)
        let diversificationScore = min(100, Double(portfolio.count) * 20)
        
        // Calculate concentration risk
        let maxConcentration = portfolioDistribution.first?.percentage ?? 0
        let concentrationRisk = maxConcentration > 50 ? "Yüksek" : maxConcentration > 30 ? "Orta" : "Düşük"
        
        // Calculate correlation (simplified)
        let correlation = "Orta" // Simplified for demo
        
        return RiskMetrics(
            volatility: volatility,
            diversificationScore: diversificationScore,
            concentrationRisk: concentrationRisk,
            maxConcentration: maxConcentration,
            correlation: correlation,
            totalCoins: portfolio.count
        )
    }
}

struct RiskMetrics {
    let volatility: Double
    let diversificationScore: Double
    let concentrationRisk: String
    let maxConcentration: Double
    let correlation: String
    let totalCoins: Int
}

struct PortfolioOverviewCard: View {
    let totalValue: Double
    let initialBalance: Double
    let distribution: [(coin: Coin, amount: Double, value: Double, percentage: Double)]
    
    private var profit: Double {
        totalValue - initialBalance
    }
    
    private var profitPercentage: Double {
        (profit / initialBalance) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.primaryGradient)
                
                Text("Portföy Özeti")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Toplam Değer")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text(formatCurrency(totalValue))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Kâr/Zarar")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: profit >= 0 ? "arrow.up" : "arrow.down")
                                .font(.system(size: 12))
                            Text(formatCurrency(profit))
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(profit >= 0 ? .green : .red)
                        
                        Text(String(format: "%.2f%%", profitPercentage))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(profit >= 0 ? .green : .red)
                    }
                }
                
                Divider()
                
                HStack {
                    PortfolioStatItem(title: "Coin Sayısı", value: "\(distribution.count)", icon: "bitcoinsign.circle.fill")
                    PortfolioStatItem(title: "Toplam Pozisyon", value: "\(distribution.count)", icon: "chart.bar.fill")
                }
            }
        }
        .padding(18)
        .modernCard()
    }
    
    private func formatCurrency(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }
}

struct PortfolioStatItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color.primaryGradient)
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct RiskAnalysisCard: View {
    let metrics: RiskMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.primaryGradient)
                
                Text("Risk Analizi")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                RiskMetricRow(
                    title: "Volatilite",
                    value: String(format: "%.2f%%", metrics.volatility),
                    level: metrics.volatility > 5 ? .high : metrics.volatility > 2 ? .medium : .low
                )
                
                RiskMetricRow(
                    title: "Çeşitlendirme Skoru",
                    value: String(format: "%.0f/100", metrics.diversificationScore),
                    level: metrics.diversificationScore > 60 ? .low : metrics.diversificationScore > 30 ? .medium : .high
                )
                
                RiskMetricRow(
                    title: "Konsantrasyon Riski",
                    value: metrics.concentrationRisk,
                    level: metrics.concentrationRisk == "Yüksek" ? .high : metrics.concentrationRisk == "Orta" ? .medium : .low
                )
                
                RiskMetricRow(
                    title: "Maksimum Konsantrasyon",
                    value: String(format: "%.1f%%", metrics.maxConcentration),
                    level: metrics.maxConcentration > 50 ? .high : metrics.maxConcentration > 30 ? .medium : .low
                )
            }
        }
        .padding(18)
        .modernCard()
    }
}

enum RiskLevel {
    case low, medium, high
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

struct RiskMetricRow: View {
    let title: String
    let value: String
    let level: RiskLevel
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            HStack(spacing: 6) {
                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                
                Circle()
                    .fill(level.color)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
    }
}

struct CoinDistributionCard: View {
    let distribution: [(coin: Coin, amount: Double, value: Double, percentage: Double)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.primaryGradient)
                
                Text("Coin Dağılımı")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            if distribution.isEmpty {
                Text("Portföyde coin yok")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 10) {
                    ForEach(distribution.prefix(5), id: \.coin.id) { item in
                        CoinDistributionRow(
                            coin: item.coin,
                            percentage: item.percentage,
                            value: item.value
                        )
                    }
                    
                    if distribution.count > 5 {
                        Text("+ \(distribution.count - 5) coin daha")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
            }
        }
        .padding(18)
        .modernCard()
    }
}

struct CoinDistributionRow: View {
    let coin: Coin
    let percentage: Double
    let value: Double
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(coin.symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(String(format: "%.1f%%", percentage))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * (percentage / 100), height: 6)
                }
            }
            .frame(height: 6)
            
            HStack {
                Text(formatCurrency(value))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
    }
    
    private func formatCurrency(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }
}

struct PerformanceMetricsCard: View {
    @ObservedObject var tradingVM: TradingViewModel
    let portfolioValue: Double
    
    private var statistics: TradingStatistics {
        tradingVM.getTradingStatistics()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.primaryGradient)
                
                Text("Performans Metrikleri")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricCard(
                    title: "Win Rate",
                    value: String(format: "%.1f%%", statistics.winRate),
                    icon: "target",
                    color: statistics.winRate > 50 ? .green : .orange
                )
                
                MetricCard(
                    title: "Profit Factor",
                    value: String(format: "%.2f", statistics.profitFactor),
                    icon: "chart.bar.fill",
                    color: statistics.profitFactor > 1.5 ? .green : .orange
                )
                
                MetricCard(
                    title: "Toplam İşlem",
                    value: "\(statistics.totalTrades)",
                    icon: "arrow.left.arrow.right.circle.fill",
                    color: .blue
                )
                
                MetricCard(
                    title: "Ortalama Kâr",
                    value: formatCurrency(statistics.averageProfit),
                    icon: "dollarsign.circle.fill",
                    color: statistics.averageProfit > 0 ? .green : .red
                )
            }
        }
        .padding(18)
        .modernCard()
    }
    
    private func formatCurrency(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct TopPerformersCard: View {
    let distribution: [(coin: Coin, amount: Double, value: Double, percentage: Double)]
    
    var topPerformers: [(coin: Coin, amount: Double, value: Double, percentage: Double)] {
        Array(distribution.prefix(3))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.primaryGradient)
                
                Text("En İyi Performans")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            if topPerformers.isEmpty {
                Text("Henüz performans verisi yok")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(topPerformers.enumerated()), id: \.element.coin.id) { index, item in
                        TopPerformerRow(
                            rank: index + 1,
                            coin: item.coin,
                            value: item.value,
                            percentage: item.percentage
                        )
                    }
                }
            }
        }
        .padding(18)
        .modernCard()
    }
}

struct TopPerformerRow: View {
    let rank: Int
    let coin: Coin
    let value: Double
    let percentage: Double
    
    var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2) // Bronze
        default: return .blue
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Text("\(rank)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(rankColor)
            }
            
            // Coin info
            VStack(alignment: .leading, spacing: 4) {
                Text(coin.symbol)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(coin.name)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Value info
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatCurrency(value))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(String(format: "%.1f%%", percentage))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
    }
    
    private func formatCurrency(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }
}

struct RecommendationsCard: View {
    let metrics: RiskMetrics
    let distribution: [(coin: Coin, amount: Double, value: Double, percentage: Double)]
    
    var recommendations: [String] {
        var recs: [String] = []
        
        if metrics.diversificationScore < 40 {
            recs.append("Portföyünüzü daha fazla çeşitlendirmeyi düşünün. En az 5 farklı coin önerilir.")
        }
        
        if metrics.maxConcentration > 50 {
            recs.append("Portföyünüzün %\(Int(metrics.maxConcentration))'i tek bir coin'de. Risk dağılımı için düşürmeyi düşünün.")
        }
        
        if metrics.volatility > 5 {
            recs.append("Yüksek volatilite tespit edildi. Risk yönetimi kurallarınıza dikkat edin.")
        }
        
        if distribution.count < 3 {
            recs.append("Daha fazla coin ekleyerek riski dağıtabilirsiniz.")
        }
        
        if recs.isEmpty {
            recs.append("Portföyünüz dengeli görünüyor. İyi iş çıkarıyorsunuz! 🎉")
        }
        
        return recs
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.primaryGradient)
                
                Text("Öneriler")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(recommendations.enumerated()), id: \.offset) { index, recommendation in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                            .padding(.top, 2)
                        
                        Text(recommendation)
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6))
                    )
                }
            }
        }
        .padding(18)
        .modernCard()
    }
}

