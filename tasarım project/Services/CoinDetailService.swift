//
//  CoinDetailService.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation
import Combine

class CoinDetailService: ObservableObject {
    static let shared = CoinDetailService()
    
    @Published var isLoading = false
    @Published var coinDetails: [String: CoinDetail] = [:]
    
    private init() {}
    
    // MARK: - Fetch Detailed Coin Data
    
    func fetchCoinDetails(coinId: String, completion: @escaping (CoinDetail?) -> Void) {
        isLoading = true
        
        // CoinGecko API endpoint for detailed coin data
        let urlString = "https://api.coingecko.com/api/v3/coins/\(coinId)?localization=false&tickers=false&market_data=true&community_data=false&developer_data=false&sparkline=false"
        
        guard let url = URL(string: urlString) else {
            isLoading = false
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("Coin detail fetch error: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let marketData = json["market_data"] as? [String: Any] else {
                    completion(nil)
                    return
                }
                
                // Parse market data
                let price = marketData["current_price"] as? [String: Double]
                let usdPrice = price?["usd"] ?? 0.0
                
                let marketCap = marketData["market_cap"] as? [String: Double]
                let usdMarketCap = marketCap?["usd"]
                
                let volume = marketData["total_volume"] as? [String: Double]
                let usdVolume = volume?["usd"]
                
                let supply = marketData["circulating_supply"] as? Double
                let totalSupply = marketData["total_supply"] as? Double
                let maxSupply = marketData["max_supply"] as? Double
                
                let priceChange = marketData["price_change_percentage_24h"] as? Double ?? 0.0
                let priceChange7d = marketData["price_change_percentage_7d"] as? Double
                let priceChange30d = marketData["price_change_percentage_30d"] as? Double
                let priceChange1y = marketData["price_change_percentage_1y"] as? Double
                
                let ath = marketData["ath"] as? [String: Double]
                let usdAth = ath?["usd"]
                let athDate = marketData["ath_date"] as? [String: String]
                let usdAthDate = athDate?["usd"]
                
                let atl = marketData["atl"] as? [String: Double]
                let usdAtl = atl?["usd"]
                let atlDate = marketData["atl_date"] as? [String: String]
                let usdAtlDate = atlDate?["usd"]
                
                let detail = CoinDetail(
                    coinId: coinId,
                    marketCap: usdMarketCap,
                    totalVolume: usdVolume,
                    circulatingSupply: supply,
                    totalSupply: totalSupply,
                    maxSupply: maxSupply,
                    priceChange7d: priceChange7d,
                    priceChange30d: priceChange30d,
                    priceChange1y: priceChange1y,
                    ath: usdAth,
                    athDate: usdAthDate,
                    atl: usdAtl,
                    atlDate: usdAtlDate
                )
                
                self.coinDetails[coinId] = detail
                completion(detail)
            }
        }.resume()
    }
    
    func getCoinDetail(coinId: String) -> CoinDetail? {
        return coinDetails[coinId]
    }
}

struct CoinDetail {
    let coinId: String
    let marketCap: Double?
    let totalVolume: Double?
    let circulatingSupply: Double?
    let totalSupply: Double?
    let maxSupply: Double?
    let priceChange7d: Double?
    let priceChange30d: Double?
    let priceChange1y: Double?
    let ath: Double?
    let athDate: String?
    let atl: Double?
    let atlDate: String?
}



