//
//  PortfolioChartView.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import SwiftUI
import Charts

struct PortfolioChartView: View {
    let snapshots: [PortfolioSnapshot]
    @State private var selectedTimeframe: Timeframe = .week
    
    enum Timeframe: String, CaseIterable {
        case week = "7 Gün"
        case month = "30 Gün"
        case all = "Tümü"
    }
    
    var filteredSnapshots: [PortfolioSnapshot] {
        let now = Date()
        let cutoffDate: Date
        
        switch selectedTimeframe {
        case .week:
            cutoffDate = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            cutoffDate = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
        case .all:
            return snapshots
        }
        
        return snapshots.filter { $0.date >= cutoffDate }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Timeframe selector
            Picker("Zaman Dilimi", selection: $selectedTimeframe) {
                ForEach(Timeframe.allCases, id: \.self) { timeframe in
                    Text(timeframe.rawValue).tag(timeframe)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            if filteredSnapshots.isEmpty {
                EmptyStateView(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Veri Yok",
                    message: "Henüz portföy verisi kaydedilmemiş."
                )
            } else {
                // Portfolio Value Chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Portföy Değeri")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if #available(iOS 16.0, *) {
                        Chart {
                            ForEach(filteredSnapshots, id: \.date) { snapshot in
                                LineMark(
                                    x: .value("Tarih", snapshot.date, unit: .day),
                                    y: .value("Değer", snapshot.totalValue)
                                )
                                .foregroundStyle(.blue)
                                .interpolationMethod(.catmullRom)
                                
                                AreaMark(
                                    x: .value("Tarih", snapshot.date, unit: .day),
                                    y: .value("Değer", snapshot.totalValue)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.0)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .interpolationMethod(.catmullRom)
                            }
                        }
                        .frame(height: 200)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day, count: selectedTimeframe == .week ? 1 : 7)) { _ in
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime.month().day())
                            }
                        }
                        .chartYAxis {
                            AxisMarks { value in
                                AxisGridLine()
                                AxisValueLabel {
                                    if let doubleValue = value.as(Double.self) {
                                        Text(formatCurrency(doubleValue))
                                    }
                                }
                            }
                        }
                    } else {
                        // Fallback for iOS < 16
                        Text("iOS 16+ gereklidir")
                            .foregroundColor(.secondary)
                            .frame(height: 200)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                )
                .padding(.horizontal)
                
                // Profit/Loss Chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Kâr/Zarar")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if #available(iOS 16.0, *) {
                        Chart {
                            ForEach(filteredSnapshots, id: \.date) { snapshot in
                                BarMark(
                                    x: .value("Tarih", snapshot.date, unit: .day),
                                    y: .value("Kâr/Zarar", snapshot.profit)
                                )
                                .foregroundStyle(snapshot.profit >= 0 ? Color.green : Color.red)
                            }
                        }
                        .frame(height: 150)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day, count: selectedTimeframe == .week ? 1 : 7)) { _ in
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime.month().day())
                            }
                        }
                        .chartYAxis {
                            AxisMarks { value in
                                AxisGridLine()
                                AxisValueLabel {
                                    if let doubleValue = value.as(Double.self) {
                                        Text(formatCurrency(doubleValue))
                                    }
                                }
                            }
                        }
                    } else {
                        Text("iOS 16+ gereklidir")
                            .foregroundColor(.secondary)
                            .frame(height: 150)
                    }
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
        .padding(.vertical)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Portföy Grafiği")
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



