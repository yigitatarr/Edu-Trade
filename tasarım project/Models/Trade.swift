//
//  Trade.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation

enum TradeType: String, Codable {
    case buy
    case sell
}

struct Trade: Identifiable, Codable {
    let id: UUID
    let coinSymbol: String
    let coinName: String
    let type: TradeType
    let amount: Double
    let price: Double
    let timestamp: Date
    
    var totalValue: Double {
        amount * price
    }
    
    var formattedTotal: String {
        String(format: "$%.2f", totalValue)
    }
    
    var formattedAmount: String {
        String(format: "%.4f", amount)
    }
}


