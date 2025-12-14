//
//  ValidationHelper.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation

struct ValidationHelper {
    static func validateTradeAmount(_ amountString: String, min: Double = 0.0001, max: Double? = nil) -> Result<Double, AppError> {
        guard let amount = amountString.toDouble, amount > 0 else {
            return .failure(.invalidAmount)
        }
        
        guard amount >= min else {
            return .failure(.invalidInput("Minimum miktar \(min) olmalıdır"))
        }
        
        if let max = max, amount > max {
            return .failure(.invalidInput("Maksimum miktar \(max) olmalıdır"))
        }
        
        return .success(amount)
    }
    
    static func validateStopLoss(_ stopLoss: Double, buyPrice: Double) -> Result<Double, AppError> {
        guard stopLoss > 0 else {
            return .failure(.invalidStopLoss)
        }
        
        guard stopLoss < buyPrice else {
            return .failure(.invalidStopLoss)
        }
        
        return .success(stopLoss)
    }
    
    static func validateBalance(_ required: Double, available: Double) -> Result<Double, AppError> {
        guard available >= required else {
            return .failure(.insufficientBalance)
        }
        
        return .success(required)
    }
    
    static func validateCoinAmount(_ required: Double, available: Double) -> Result<Double, AppError> {
        guard available >= required else {
            return .failure(.insufficientCoins)
        }
        
        return .success(required)
    }
}


