//
//  TradingJournal.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation

struct TradingJournalEntry: Identifiable, Codable {
    let id: UUID
    let tradeId: UUID
    let coinSymbol: String
    let entryDate: Date
    var notes: String
    var strategy: String
    var emotions: String
    var lessonsLearned: String
    var rating: Int // 1-5
    
    init(
        id: UUID = UUID(),
        tradeId: UUID,
        coinSymbol: String,
        entryDate: Date = Date(),
        notes: String = "",
        strategy: String = "",
        emotions: String = "",
        lessonsLearned: String = "",
        rating: Int = 3
    ) {
        self.id = id
        self.tradeId = tradeId
        self.coinSymbol = coinSymbol
        self.entryDate = entryDate
        self.notes = notes
        self.strategy = strategy
        self.emotions = emotions
        self.lessonsLearned = lessonsLearned
        self.rating = rating
    }
}



