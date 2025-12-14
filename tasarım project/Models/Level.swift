//
//  Level.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation

struct Level: Identifiable, Codable {
    let id: String
    let number: Int
    let title: String
    let description: String
    let icon: String
    let color: String
    let requiredXP: Int
    let lessons: [String] // Lesson IDs
    let practiceChallenges: [String] // Challenge IDs
    let unlockCondition: UnlockCondition?
    
    enum UnlockCondition: Codable {
        case previousLevelCompleted
        case xpRequired(Int)
        case lessonsCompleted([String])
        
        enum CodingKeys: String, CodingKey {
            case type
            case value
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            
            switch type {
            case "previousLevelCompleted":
                self = .previousLevelCompleted
            case "xpRequired":
                let value = try container.decode(Int.self, forKey: .value)
                self = .xpRequired(value)
            case "lessonsCompleted":
                let value = try container.decode([String].self, forKey: .value)
                self = .lessonsCompleted(value)
            default:
                self = .previousLevelCompleted
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            switch self {
            case .previousLevelCompleted:
                try container.encode("previousLevelCompleted", forKey: .type)
            case .xpRequired(let value):
                try container.encode("xpRequired", forKey: .type)
                try container.encode(value, forKey: .value)
            case .lessonsCompleted(let value):
                try container.encode("lessonsCompleted", forKey: .type)
                try container.encode(value, forKey: .value)
            }
        }
    }
}

