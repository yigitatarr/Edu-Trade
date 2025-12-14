//
//  Task.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation

struct Task: Identifiable, Codable {
    let id: String
    let challengeId: String
    let title: String
    let description: String
    let type: TaskType
    let xpReward: Int
    let isCompleted: Bool
    let completedDate: Date?
    
    enum TaskType: String, Codable {
        case readLesson
        case completeQuiz
        case makeTrade
        case buyCoin
        case sellCoin
        case reachPortfolioValue
        case completeLevel
    }
}

