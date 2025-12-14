//
//  PortfolioSnapshot.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation

struct PortfolioSnapshot: Codable, Identifiable {
    let id: UUID
    let date: Date
    let totalValue: Double
    let profit: Double
    
    init(id: UUID = UUID(), date: Date = Date(), totalValue: Double, profit: Double) {
        self.id = id
        self.date = date
        self.totalValue = totalValue
        self.profit = profit
    }
}

