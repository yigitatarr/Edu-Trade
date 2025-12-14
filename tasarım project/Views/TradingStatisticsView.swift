//
//  TradingStatisticsView.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import SwiftUI

struct TradingStatisticsView: View {
    @ObservedObject var viewModel: TradingViewModel
    let statistics: TradingStatistics
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Trading İstatistikleri")
                        .font(.system(size: 24, weight: .bold))
                    
                    Text("Performans özetiniz")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Win Rate Card
                StatCard(
                    title: "Başarı Oranı",
                    value: String(format: "%.1f%%", statistics.winRate),
                    subtitle: "\(statistics.winningTrades) kazanç / \(statistics.totalTrades) işlem",
                    icon: "target",
                    color: statistics.winRate >= 50 ? .green : .orange
                )
                
                // Profit Card
                StatCard(
                    title: "Toplam Kâr/Zarar",
                    value: formatCurrency(statistics.totalProfit),
                    subtitle: statistics.totalProfit >= 0 ? "Kârlı" : "Zararlı",
                    icon: "dollarsign.circle.fill",
                    color: statistics.totalProfit >= 0 ? .green : .red
                )
                
                // Profit Factor Card
                StatCard(
                    title: "Profit Factor",
                    value: String(format: "%.2f", statistics.profitFactor),
                    subtitle: statistics.profitFactor > 1 ? "İyi" : "Geliştirilmeli",
                    icon: "chart.line.uptrend.xyaxis",
                    color: statistics.profitFactor > 1 ? .green : .orange
                )
                
                // Most Profitable Coin
                if let coin = statistics.mostProfitableCoin {
                    StatCard(
                        title: "En Kârlı Coin",
                        value: coin,
                        subtitle: "En çok kazandıran coin",
                        icon: "star.fill",
                        color: .blue
                    )
                }
                
                // Trade Breakdown
                VStack(alignment: .leading, spacing: 12) {
                    Text("İşlem Dağılımı")
                        .font(.system(size: 18, weight: .semibold))
                        .padding(.horizontal)
                    
                    HStack(spacing: 16) {
                        BreakdownItem(
                            title: "Kazanan",
                            count: statistics.winningTrades,
                            color: .green
                        )
                        
                        BreakdownItem(
                            title: "Kaybeden",
                            count: statistics.losingTrades,
                            color: .red
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                )
                .padding(.horizontal)
            }
            .padding(.bottom)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("İstatistikler")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
}

struct BreakdownItem: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(count)")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}



