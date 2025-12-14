//
//  String+Decimal.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation

extension String {
    /// Türkçe klavyede virgülü noktaya çevirir
    var normalizedDecimal: String {
        self.replacingOccurrences(of: ",", with: ".")
    }
    
    /// String'i Double'a çevirirken hem virgül hem noktayı kabul eder
    var toDouble: Double? {
        let normalized = self.normalizedDecimal
        return Double(normalized)
    }
}

