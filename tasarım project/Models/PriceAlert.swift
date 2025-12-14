//
//  PriceAlert.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation

enum AlertCondition: String, Codable {
    case above = "above"
    case below = "below"
}

struct PriceAlert: Identifiable, Codable {
    let id: UUID
    let coinSymbol: String
    let coinName: String
    let targetPrice: Double
    let condition: AlertCondition
    var isActive: Bool
    let createdAt: Date
    var triggeredAt: Date?
    
    init(
        id: UUID = UUID(),
        coinSymbol: String,
        coinName: String,
        targetPrice: Double,
        condition: AlertCondition,
        isActive: Bool = true,
        createdAt: Date = Date(),
        triggeredAt: Date? = nil
    ) {
        self.id = id
        self.coinSymbol = coinSymbol
        self.coinName = coinName
        self.targetPrice = targetPrice
        self.condition = condition
        self.isActive = isActive
        self.createdAt = createdAt
        self.triggeredAt = triggeredAt
    }
}



