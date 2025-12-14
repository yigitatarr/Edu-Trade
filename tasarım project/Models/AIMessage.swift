//
//  AIMessage.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation

struct AIMessage: Identifiable, Codable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    
    init(content: String, isUser: Bool) {
        self.id = UUID()
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
    }
}



