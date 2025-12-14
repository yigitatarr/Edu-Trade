//
//  AppError.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation

enum AppError: LocalizedError {
    case networkError(String)
    case invalidInput(String)
    case insufficientBalance
    case insufficientCoins
    case invalidAmount
    case invalidStopLoss
    case dataLoadError
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Ağ hatası: \(message)"
        case .invalidInput(let message):
            return "Geçersiz giriş: \(message)"
        case .insufficientBalance:
            return "Yetersiz bakiye"
        case .insufficientCoins:
            return "Yetersiz coin miktarı"
        case .invalidAmount:
            return "Geçersiz miktar"
        case .invalidStopLoss:
            return "Stop loss fiyatı, alış fiyatından düşük olmalıdır"
        case .dataLoadError:
            return "Veri yüklenirken hata oluştu"
        case .unknownError:
            return "Bilinmeyen bir hata oluştu"
        }
    }
}


