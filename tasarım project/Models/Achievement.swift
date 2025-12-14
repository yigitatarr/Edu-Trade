//
//  Achievement.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation

struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let condition: String
    var isUnlocked: Bool
}


