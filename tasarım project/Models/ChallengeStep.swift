//
//  ChallengeStep.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation

struct ChallengeStep: Identifiable, Codable {
    let id: String
    let number: Int
    let title: String
    let description: String
    let action: StepAction
    let icon: String
    
    enum StepAction: String, Codable {
        case navigateToTrade = "navigate_to_trade"
        case navigateToLesson = "navigate_to_lesson"
        case navigateToQuiz = "navigate_to_quiz"
        case readContent = "read_content"
        case completeAction = "complete_action"
    }
}

