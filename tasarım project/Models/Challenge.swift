//
//  Challenge.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation

struct Challenge: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let type: ChallengeType
    let xpReward: Int
    let icon: String
    let requirements: ChallengeRequirements
    let requiredChallengeId: String? // Bu challenge'ı unlock etmek için tamamlanması gereken challenge
    let detailedDescription: String? // Daha detaylı açıklama
    let steps: [ChallengeStep]? // Adım adım rehberlik
    
    enum ChallengeType: String, Codable {
        case daily
        case weekly
        case practice
        case achievement
    }
    
    struct ChallengeRequirements: Codable {
        var tradeCount: Int?
        var coinCount: Int?
        var lessonId: String?
        var quizScore: Int?
        var portfolioValue: Double?
        var specificCoin: String?
        var profitPercentage: Double?
    }
}

