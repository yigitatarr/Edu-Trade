//
//  DataManagerTests.swift
//  EduTradeTests
//
//  Created by AI on 28.10.2025.
//

import XCTest
@testable import tasar_m_project

final class DataManagerTests: XCTestCase {
    var dataManager: DataManager!
    
    override func setUp() {
        super.setUp()
        dataManager = DataManager.shared
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testLoadUser() {
        let user = dataManager.loadUser()
        XCTAssertNotNil(user)
        XCTAssertGreaterThanOrEqual(user.balance, 0)
    }
    
    func testSaveAndLoadUser() {
        var user = dataManager.loadUser()
        let originalBalance = user.balance
        user.balance = 50000.0
        
        dataManager.saveUser(user)
        
        let loadedUser = dataManager.loadUser()
        XCTAssertEqual(loadedUser.balance, 50000.0, accuracy: 0.01)
        
        // Restore original balance
        user.balance = originalBalance
        dataManager.saveUser(user)
    }
    
    func testLoadCoins() {
        let coins = dataManager.coins
        XCTAssertFalse(coins.isEmpty, "Coins should be loaded")
    }
    
    func testLoadLessons() {
        let lessons = dataManager.lessons
        XCTAssertFalse(lessons.isEmpty, "Lessons should be loaded")
    }
    
    func testLoadQuizzes() {
        let quizzes = dataManager.quizzes
        XCTAssertFalse(quizzes.isEmpty, "Quizzes should be loaded")
    }
    
    func testSaveAndLoadTrades() {
        let testTrade = Trade(
            id: UUID(),
            coinSymbol: "BTC",
            coinName: "Bitcoin",
            type: .buy,
            amount: 0.1,
            price: 50000.0,
            timestamp: Date()
        )
        
        var trades = dataManager.loadTrades()
        trades.append(testTrade)
        dataManager.saveTrades(trades)
        
        let loadedTrades = dataManager.loadTrades()
        XCTAssertTrue(loadedTrades.contains { $0.id == testTrade.id })
    }
}



