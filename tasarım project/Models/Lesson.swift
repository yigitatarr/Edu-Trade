//
//  Lesson.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation

struct Lesson: Identifiable, Codable {
    let id: String
    let title: String
    let content: String
    let duration: String // e.g., "5 min"
    let category: String
    let icon: String
}


