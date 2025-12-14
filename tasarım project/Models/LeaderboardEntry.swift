//
//  LeaderboardEntry.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation

struct LeaderboardEntry: Codable, Identifiable, Hashable {
    let id: UUID
    var userName: String
    var totalXP: Int
    var totalProfit: Double
    var winRate: Double
    var totalTrades: Int
    var level: Int
    var streak: Int
    var rank: Int
    
    init(
        id: UUID = UUID(),
        userName: String,
        totalXP: Int,
        totalProfit: Double,
        winRate: Double,
        totalTrades: Int,
        level: Int,
        streak: Int,
        rank: Int = 0
    ) {
        self.id = id
        self.userName = userName
        self.totalXP = totalXP
        self.totalProfit = totalProfit
        self.winRate = winRate
        self.totalTrades = totalTrades
        self.level = level
        self.streak = streak
        self.rank = rank
    }
}

enum LeaderboardSortOption: String, CaseIterable {
    case xp = "XP"
    case profit = "Kâr"
    case winRate = "Başarı Oranı"
    case trades = "İşlem Sayısı"
    case level = "Seviye"
    case streak = "Seri"
    
    var icon: String {
        switch self {
        case .xp: return "star.fill"
        case .profit: return "dollarsign.circle.fill"
        case .winRate: return "chart.bar.fill"
        case .trades: return "arrow.left.arrow.right.circle.fill"
        case .level: return "trophy.fill"
        case .streak: return "flame.fill"
        }
    }
}

