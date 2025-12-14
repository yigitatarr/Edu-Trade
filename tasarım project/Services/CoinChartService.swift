//
//  CoinChartService.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation
import Combine

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let price: Double
}

class CoinChartService: ObservableObject {
    static let shared = CoinChartService()
    
    @Published var chartData: [ChartDataPoint] = []
    @Published var isLoading = false
    @Published var error: String?
    
    // Cache for chart data per coin
    private var chartDataCache: [String: [Int: [ChartDataPoint]]] = [:]
    
    private init() {}
    
    // Fetch chart data using coin ID directly (from Coin model)
    func fetchChartData(for coinId: String, days: Int = 7) {
        // Check cache first
        if let cachedData = chartDataCache[coinId]?[days] {
            self.chartData = cachedData
            return
        }
        
        isLoading = true
        error = nil
        
        let urlString = "https://api.coingecko.com/api/v3/coins/\(coinId)/market_chart?vs_currency=usd&days=\(days)"
        
        guard let url = URL(string: urlString) else {
            isLoading = false
            error = "Geçersiz URL"
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.error = error.localizedDescription
                    return
                }
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let prices = json["prices"] as? [[Double]] else {
                    self.error = "Veri parse edilemedi"
                    return
                }
                
                // Parse chart data
                var dataPoints: [ChartDataPoint] = []
                for priceData in prices {
                    if priceData.count >= 2 {
                        let timestamp = Date(timeIntervalSince1970: priceData[0] / 1000)
                        let price = priceData[1]
                        dataPoints.append(ChartDataPoint(timestamp: timestamp, price: price))
                    }
                }
                
                let sortedData = dataPoints.sorted { $0.timestamp < $1.timestamp }
                self.chartData = sortedData
                
                // Cache the data
                if self.chartDataCache[coinId] == nil {
                    self.chartDataCache[coinId] = [:]
                }
                self.chartDataCache[coinId]?[days] = sortedData
            }
        }.resume()
    }
    
    // Helper method to get coin ID from symbol (for backward compatibility)
    func getCoinId(for symbol: String) -> String? {
        return DataManager.shared.coins.first(where: { $0.symbol.uppercased() == symbol.uppercased() })?.id
    }
    
    // Clear cache if needed
    func clearCache() {
        chartDataCache.removeAll()
    }
}

