//
//  ValidationHelperTests.swift
//  EduTradeTests
//
//  Created by AI on 28.10.2025.
//

import XCTest
@testable import tasar_m_project

final class ValidationHelperTests: XCTestCase {
    
    func testValidateTradeAmount_ValidAmount() {
        let result = ValidationHelper.validateTradeAmount("100.50")
        XCTAssertTrue(result.isSuccess)
        if case .success(let amount) = result {
            XCTAssertEqual(amount, 100.50, accuracy: 0.01)
        }
    }
    
    func testValidateTradeAmount_InvalidAmount() {
        let result = ValidationHelper.validateTradeAmount("invalid")
        XCTAssertTrue(result.isFailure)
        if case .failure(let error) = result {
            XCTAssertEqual(error, AppError.invalidAmount)
        }
    }
    
    func testValidateTradeAmount_ZeroAmount() {
        let result = ValidationHelper.validateTradeAmount("0")
        XCTAssertTrue(result.isFailure)
    }
    
    func testValidateTradeAmount_NegativeAmount() {
        let result = ValidationHelper.validateTradeAmount("-10")
        XCTAssertTrue(result.isFailure)
    }
    
    func testValidateTradeAmount_MinimumAmount() {
        let result = ValidationHelper.validateTradeAmount("0.0001", min: 0.0001)
        XCTAssertTrue(result.isSuccess)
    }
    
    func testValidateTradeAmount_BelowMinimum() {
        let result = ValidationHelper.validateTradeAmount("0.00005", min: 0.0001)
        XCTAssertTrue(result.isFailure)
    }
    
    func testValidateStopLoss_ValidStopLoss() {
        let result = ValidationHelper.validateStopLoss(50.0, buyPrice: 100.0)
        XCTAssertTrue(result.isSuccess)
        if case .success(let stopLoss) = result {
            XCTAssertEqual(stopLoss, 50.0)
        }
    }
    
    func testValidateStopLoss_InvalidStopLoss() {
        let result = ValidationHelper.validateStopLoss(150.0, buyPrice: 100.0)
        XCTAssertTrue(result.isFailure)
        if case .failure(let error) = result {
            XCTAssertEqual(error, AppError.invalidStopLoss)
        }
    }
    
    func testValidateBalance_SufficientBalance() {
        let result = ValidationHelper.validateBalance(50.0, available: 100.0)
        XCTAssertTrue(result.isSuccess)
    }
    
    func testValidateBalance_InsufficientBalance() {
        let result = ValidationHelper.validateBalance(150.0, available: 100.0)
        XCTAssertTrue(result.isFailure)
        if case .failure(let error) = result {
            XCTAssertEqual(error, AppError.insufficientBalance)
        }
    }
    
    func testValidateCoinAmount_SufficientAmount() {
        let result = ValidationHelper.validateCoinAmount(5.0, available: 10.0)
        XCTAssertTrue(result.isSuccess)
    }
    
    func testValidateCoinAmount_InsufficientAmount() {
        let result = ValidationHelper.validateCoinAmount(15.0, available: 10.0)
        XCTAssertTrue(result.isFailure)
        if case .failure(let error) = result {
            XCTAssertEqual(error, AppError.insufficientCoins)
        }
    }
}

extension Result {
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
    
    var isFailure: Bool {
        if case .failure = self { return true }
        return false
    }
}

