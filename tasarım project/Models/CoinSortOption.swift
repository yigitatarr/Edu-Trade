//
//  CoinSortOption.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation

enum CoinSortOption: String, CaseIterable {
    case name = "name"
    case price = "price"
    case change24h = "change24h"
    case marketCap = "marketCap"
    case volume = "volume"
    
    var displayName: String {
        switch self {
        case .name: return "İsim"
        case .price: return "Fiyat"
        case .change24h: return "24h Değişim"
        case .marketCap: return "Market Cap"
        case .volume: return "Hacim"
        }
    }
    
    var icon: String {
        switch self {
        case .name: return "textformat.abc"
        case .price: return "dollarsign.circle"
        case .change24h: return "arrow.up.arrow.down"
        case .marketCap: return "chart.bar"
        case .volume: return "arrow.up.arrow.down.circle"
        }
    }
}

enum SortOrder: String, CaseIterable {
    case ascending = "asc"
    case descending = "desc"
    
    var displayName: String {
        switch self {
        case .ascending: return "Artan"
        case .descending: return "Azalan"
        }
    }
    
    var icon: String {
        switch self {
        case .ascending: return "arrow.up"
        case .descending: return "arrow.down"
        }
    }
}

struct CoinFilter {
    var minPrice: Double?
    var maxPrice: Double?
    var minChange24h: Double?
    var maxChange24h: Double?
    var hasPortfolio: Bool?
    var isFavorite: Bool?
    
    func matches(_ coin: Coin, coinHasPortfolio: Bool, coinIsFavorite: Bool) -> Bool {
        // Price filter
        if let minPrice = minPrice, coin.price < minPrice {
            return false
        }
        if let maxPrice = maxPrice, coin.price > maxPrice {
            return false
        }
        
        // Change filter
        if let minChange = minChange24h, coin.change24h < minChange {
            return false
        }
        if let maxChange = maxChange24h, coin.change24h > maxChange {
            return false
        }
        
        // Portfolio filter
        if let hasPortfolioFilter = self.hasPortfolio, coinHasPortfolio != hasPortfolioFilter {
            return false
        }
        
        // Favorite filter
        if let isFavoriteFilter = self.isFavorite, coinIsFavorite != isFavoriteFilter {
            return false
        }
        
        return true
    }
}

