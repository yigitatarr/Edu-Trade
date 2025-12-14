//
//  LearningViewModelTests.swift
//  EduTradeTests
//
//  Created by AI on 28.10.2025.
//

import XCTest
@testable import tasar_m_project

final class LearningViewModelTests: XCTestCase {
    var viewModel: LearningViewModel!
    var testLesson: Lesson!
    var testQuiz: Quiz!
    
    override func setUp() {
        super.setUp()
        viewModel = LearningViewModel()
        
        testLesson = Lesson(
            id: "test_lesson",
            title: "Test Lesson",
            content: "Test content",
            duration: "5 dk",
            category: "Test",
            icon: "book.fill"
        )
        
        testQuiz = Quiz(
            id: "test_quiz",
            lessonId: "test_lesson",
            questions: [
                Question(
                    id: "q1",
                    question: "Test question?",
                    options: ["A", "B", "C", "D"],
                    correctAnswer: 0
                )
            ]
        )
    }
    
    override func tearDown() {
        viewModel = nil
        testLesson = nil
        testQuiz = nil
        super.tearDown()
    }
    
    func testCompleteLesson() {
        let initialXP = viewModel.getCurrentUser().progress.totalXP
        
        viewModel.completeLesson(testLesson.id)
        
        let updatedUser = viewModel.getCurrentUser()
        XCTAssertTrue(viewModel.isLessonCompleted(testLesson.id))
        XCTAssertGreaterThan(updatedUser.progress.totalXP, initialXP)
    }
    
    func testSubmitQuizScore() {
        let score = 80
        let totalQuestions = 5
        
        viewModel.submitQuizScore(lessonId: testLesson.id, score: score, totalQuestions: totalQuestions)
        
        let result = viewModel.getQuizResult(for: testLesson.id)
        XCTAssertNotNil(result)
        XCTAssertEqual(result, score)
    }
    
    func testIsLessonCompleted() {
        XCTAssertFalse(viewModel.isLessonCompleted(testLesson.id))
        
        viewModel.completeLesson(testLesson.id)
        
        XCTAssertTrue(viewModel.isLessonCompleted(testLesson.id))
    }
    
    func testGetCompletionPercentage() {
        // Assuming we have some lessons loaded
        let percentage = viewModel.getCompletionPercentage()
        XCTAssertGreaterThanOrEqual(percentage, 0)
        XCTAssertLessThanOrEqual(percentage, 100)
    }
}



