//
//  UserProgress.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation

struct UserProgress: Codable {
    var currentLevel: Int
    var totalXP: Int
    var currentLevelXP: Int
    var streak: Int
    var lastActivityDate: Date?
    var completedLevels: [String]
    var unlockedLevels: [String]
    var completedChallenges: [String]
    var dailyChallenges: [String: Date] // [challengeId: completionDate]
    var weeklyChallenges: [String: Date]
    
    init() {
        self.currentLevel = 1
        self.totalXP = 0
        self.currentLevelXP = 0
        self.streak = 0
        self.lastActivityDate = nil
        self.completedLevels = []
        self.unlockedLevels = ["level_1"] // İlk seviye başlangıçta açık
        self.completedChallenges = []
        self.dailyChallenges = [:]
        self.weeklyChallenges = [:]
    }
    
    var xpToNextLevel: Int {
        let nextLevelXP = currentLevel * 100 // Her seviye için 100 XP
        return nextLevelXP - currentLevelXP
    }
    
    var levelProgress: Double {
        let levelXP = currentLevel * 100
        guard levelXP > 0 else { return 0 }
        return Double(currentLevelXP) / Double(levelXP)
    }
}

