//
//  StringDecimalExtensionTests.swift
//  EduTradeTests
//
//  Created by AI on 28.10.2025.
//

import XCTest
@testable import tasar_m_project

final class StringDecimalExtensionTests: XCTestCase {
    
    func testNormalizedDecimal_WithComma() {
        let input = "10,5"
        let expected = "10.5"
        XCTAssertEqual(input.normalizedDecimal, expected)
    }
    
    func testNormalizedDecimal_WithPeriod() {
        let input = "10.5"
        let expected = "10.5"
        XCTAssertEqual(input.normalizedDecimal, expected)
    }
    
    func testNormalizedDecimal_Mixed() {
        let input = "1,000.50"
        let expected = "1.000.50"
        XCTAssertEqual(input.normalizedDecimal, expected)
    }
    
    func testToDouble_WithComma() {
        let input = "10,5"
        XCTAssertEqual(input.toDouble, 10.5, accuracy: 0.01)
    }
    
    func testToDouble_WithPeriod() {
        let input = "10.5"
        XCTAssertEqual(input.toDouble, 10.5, accuracy: 0.01)
    }
    
    func testToDouble_InvalidInput() {
        let input = "invalid"
        XCTAssertNil(input.toDouble)
    }
    
    func testToDouble_EmptyString() {
        let input = ""
        XCTAssertNil(input.toDouble)
    }
    
    func testToDouble_LargeNumber() {
        let input = "1000000,50"
        XCTAssertEqual(input.toDouble, 1000000.50, accuracy: 0.01)
    }
}

