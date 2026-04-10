//
//  Quiz.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation

struct Quiz: Identifiable, Codable {
    let id: String
    let lessonId: String
    let questions: [QuizQuestion]
    
    struct QuizQuestion: Identifiable, Codable {
        let id: String
        let question: String
        let options: [String]
        let correctAnswer: Int
        
        var correctAnswerIndex: Int {
            let index = correctAnswer - 1
            return max(0, min(index, options.count - 1))
        }
    }
}


