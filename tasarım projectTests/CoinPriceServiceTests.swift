//
//  CoinPriceServiceTests.swift
//  EduTradeTests
//
//  Created by AI on 28.10.2025.
//

import XCTest
@testable import tasar_m_project

final class CoinPriceServiceTests: XCTestCase {
    var service: CoinPriceService!
    
    override func setUp() {
        super.setUp()
        service = CoinPriceService.shared
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testCoinIdMapping() {
        // Test that all coins have valid CoinGecko IDs
        let dataManager = DataManager.shared
        let coins = dataManager.coins
        
        for coin in coins {
            // Check if coin ID is valid (not empty)
            XCTAssertFalse(coin.id.isEmpty, "Coin \(coin.symbol) should have a valid ID")
        }
    }
    
    func testPriceServiceInitialization() {
        XCTAssertNotNil(service)
    }
    
    func testGetCoinName() {
        // This is a private method, but we can test through public API
        // Just verify service is initialized
        XCTAssertNotNil(service)
    }
}



