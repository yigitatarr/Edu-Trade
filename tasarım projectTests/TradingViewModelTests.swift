//
//  TradingViewModelTests.swift
//  EduTradeTests
//
//  Created by AI on 28.10.2025.
//

import XCTest
@testable import tasar_m_project

final class TradingViewModelTests: XCTestCase {
    var viewModel: TradingViewModel!
    var testCoin: Coin!
    
    override func setUp() {
        super.setUp()
        viewModel = TradingViewModel()
        testCoin = Coin(
            id: "bitcoin",
            symbol: "BTC",
            name: "Bitcoin",
            price: 50000.0,
            change24h: 2.5
        )
    }
    
    override func tearDown() {
        viewModel = nil
        testCoin = nil
        super.tearDown()
    }
    
    func testBuyCoin_SufficientBalance() {
        let initialBalance = viewModel.user.balance
        let amount = 0.1
        let price = testCoin.price
        let totalCost = amount * price
        
        viewModel.buyCoin(testCoin, amount: amount, price: price)
        
        XCTAssertEqual(viewModel.user.balance, initialBalance - totalCost, accuracy: 0.01)
        XCTAssertEqual(viewModel.user.portfolio[testCoin.symbol], amount, accuracy: 0.0001)
        XCTAssertEqual(viewModel.user.numberOfTrades, 1)
    }
    
    func testBuyCoin_InsufficientBalance() {
        let initialBalance = viewModel.user.balance
        let amount = 100.0 // Very large amount
        let price = testCoin.price
        
        viewModel.buyCoin(testCoin, amount: amount, price: price)
        
        // Balance should not change
        XCTAssertEqual(viewModel.user.balance, initialBalance, accuracy: 0.01)
        // Portfolio should not have the coin
        XCTAssertNil(viewModel.user.portfolio[testCoin.symbol])
    }
    
    func testSellCoin_SufficientAmount() {
        // First buy some coins
        let buyAmount = 0.5
        viewModel.buyCoin(testCoin, amount: buyAmount, price: testCoin.price)
        
        let initialBalance = viewModel.user.balance
        let sellAmount = 0.2
        let price = testCoin.price
        let totalValue = sellAmount * price
        
        viewModel.sellCoin(testCoin, amount: sellAmount, price: price)
        
        XCTAssertEqual(viewModel.user.balance, initialBalance + totalValue, accuracy: 0.01)
        XCTAssertEqual(viewModel.user.portfolio[testCoin.symbol], buyAmount - sellAmount, accuracy: 0.0001)
    }
    
    func testSellCoin_InsufficientAmount() {
        let initialBalance = viewModel.user.balance
        let sellAmount = 1.0
        
        viewModel.sellCoin(testCoin, amount: sellAmount, price: testCoin.price)
        
        // Balance should not change
        XCTAssertEqual(viewModel.user.balance, initialBalance, accuracy: 0.01)
    }
    
    func testToggleFavorite() {
        XCTAssertFalse(viewModel.isFavorite(coinSymbol: testCoin.symbol))
        
        viewModel.toggleFavorite(coinSymbol: testCoin.symbol)
        XCTAssertTrue(viewModel.isFavorite(coinSymbol: testCoin.symbol))
        
        viewModel.toggleFavorite(coinSymbol: testCoin.symbol)
        XCTAssertFalse(viewModel.isFavorite(coinSymbol: testCoin.symbol))
    }
    
    func testGetFavoriteCoins() {
        let coins = [testCoin]
        
        viewModel.toggleFavorite(coinSymbol: testCoin.symbol)
        let favorites = viewModel.getFavoriteCoins(from: coins)
        
        XCTAssertEqual(favorites.count, 1)
        XCTAssertEqual(favorites.first?.symbol, testCoin.symbol)
    }
    
    func testGetPortfolioAmount() {
        let amount = 0.5
        viewModel.buyCoin(testCoin, amount: amount, price: testCoin.price)
        
        let portfolioAmount = viewModel.getPortfolioAmount(for: testCoin)
        XCTAssertEqual(portfolioAmount, amount, accuracy: 0.0001)
    }
    
    func testGetPortfolioValue() {
        let amount = 0.5
        viewModel.buyCoin(testCoin, amount: amount, price: testCoin.price)
        
        let portfolioValue = viewModel.getPortfolioValue(for: testCoin)
        let expectedValue = amount * testCoin.price
        XCTAssertEqual(portfolioValue, expectedValue, accuracy: 0.01)
    }
}

