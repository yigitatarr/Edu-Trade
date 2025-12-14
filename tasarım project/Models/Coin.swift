//
//  Coin.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation

struct Coin: Identifiable, Codable, Hashable {
    let id: String
    let symbol: String
    let name: String
    var price: Double
    var change24h: Double
    
    // Extended market data (optional, will be populated from API)
    var marketCap: Double?
    var totalVolume: Double?
    var circulatingSupply: Double?
    var totalSupply: Double?
    var maxSupply: Double?
    var ath: Double? // All-time high
    var athDate: String?
    var atl: Double? // All-time low
    var atlDate: String?
    var priceChange7d: Double?
    var priceChange30d: Double?
    var priceChange1y: Double?
    
    var formattedPrice: String {
        String(format: "$%.2f", price)
    }
    
    var priceChangeColor: String {
        change24h >= 0 ? "green" : "red"
    }
    
    var priceChangeIcon: String {
        change24h >= 0 ? "arrow.up" : "arrow.down"
    }
    
    var formattedMarketCap: String {
        guard let marketCap = marketCap else { return "N/A" }
        if marketCap >= 1_000_000_000_000 {
            return String(format: "$%.2fT", marketCap / 1_000_000_000_000)
        } else if marketCap >= 1_000_000_000 {
            return String(format: "$%.2fB", marketCap / 1_000_000_000)
        } else if marketCap >= 1_000_000 {
            return String(format: "$%.2fM", marketCap / 1_000_000)
        } else {
            return String(format: "$%.2f", marketCap)
        }
    }
    
    var formattedVolume: String {
        guard let volume = totalVolume else { return "N/A" }
        if volume >= 1_000_000_000 {
            return String(format: "$%.2fB", volume / 1_000_000_000)
        } else if volume >= 1_000_000 {
            return String(format: "$%.2fM", volume / 1_000_000)
        } else {
            return String(format: "$%.2f", volume)
        }
    }
    
    var formattedSupply: String {
        guard let supply = circulatingSupply else { return "N/A" }
        if supply >= 1_000_000_000 {
            return String(format: "%.2fB", supply / 1_000_000_000)
        } else if supply >= 1_000_000 {
            return String(format: "%.2fM", supply / 1_000_000)
        } else {
            return String(format: "%.2f", supply)
        }
    }
    
    var athPercentage: Double? {
        guard let ath = ath, ath > 0 else { return nil }
        return ((price - ath) / ath) * 100
    }
    
    var atlPercentage: Double? {
        guard let atl = atl, atl > 0 else { return nil }
        return ((price - atl) / atl) * 100
    }
}


