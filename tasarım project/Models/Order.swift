//
//  Order.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation

enum OrderType: String, Codable {
    case limitBuy = "limit_buy"
    case limitSell = "limit_sell"
    case marketBuy = "market_buy"
    case marketSell = "market_sell"
}

enum OrderStatus: String, Codable {
    case pending = "pending"
    case executed = "executed"
    case cancelled = "cancelled"
}

struct Order: Identifiable, Codable {
    let id: UUID
    let coinSymbol: String
    let coinName: String
    let type: OrderType
    let amount: Double
    let limitPrice: Double? // For limit orders
    let stopLoss: Double?
    let takeProfit: Double?
    var status: OrderStatus
    let createdAt: Date
    var executedAt: Date?
    var notes: String?
    
    init(
        id: UUID = UUID(),
        coinSymbol: String,
        coinName: String,
        type: OrderType,
        amount: Double,
        limitPrice: Double? = nil,
        stopLoss: Double? = nil,
        takeProfit: Double? = nil,
        status: OrderStatus = .pending,
        createdAt: Date = Date(),
        executedAt: Date? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.coinSymbol = coinSymbol
        self.coinName = coinName
        self.type = type
        self.amount = amount
        self.limitPrice = limitPrice
        self.stopLoss = stopLoss
        self.takeProfit = takeProfit
        self.status = status
        self.createdAt = createdAt
        self.executedAt = executedAt
        self.notes = notes
    }
}



