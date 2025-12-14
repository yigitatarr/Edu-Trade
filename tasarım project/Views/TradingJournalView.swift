//
//  TradingJournalView.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import SwiftUI

struct TradingJournalView: View {
    @ObservedObject var tradingVM: TradingViewModel
    @State private var selectedEntry: TradingJournalEntry?
    @State private var showingEntrySheet = false
    @State private var searchText = ""
    @State private var selectedCoin: String? = nil
    
    private var filteredEntries: [TradingJournalEntry] {
        var entries = tradingVM.journalEntries.sorted { $0.entryDate > $1.entryDate }
        
        if !searchText.isEmpty {
            entries = entries.filter { entry in
                entry.coinSymbol.localizedCaseInsensitiveContains(searchText) ||
                entry.notes.localizedCaseInsensitiveContains(searchText) ||
                entry.strategy.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let coin = selectedCoin {
            entries = entries.filter { $0.coinSymbol == coin }
        }
        
        return entries
    }
    
    private var uniqueCoins: [String] {
        Array(Set(tradingVM.journalEntries.map { $0.coinSymbol })).sorted()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter
                VStack(spacing: 12) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Ara...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Coin filter
                    if !uniqueCoins.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                JournalFilterChip(
                                    title: "Tümü",
                                    isSelected: selectedCoin == nil,
                                    action: { selectedCoin = nil }
                                )
                                
                                ForEach(uniqueCoins, id: \.self) { coin in
                                    JournalFilterChip(
                                        title: coin,
                                        isSelected: selectedCoin == coin,
                                        action: { selectedCoin = coin }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical, 12)
                .background(Color(.systemGroupedBackground))
                
                // Journal Entries List
                if filteredEntries.isEmpty {
                    EmptyStateView(
                        icon: "book.closed.fill",
                        title: "Günlük Kaydı Yok",
                        message: searchText.isEmpty && selectedCoin == nil ?
                            "Henüz trading günlüğü kaydı yok. İşlemlerinizden sonra günlük tutabilirsiniz." :
                            "Arama kriterlerinize uygun kayıt bulunamadı."
                    )
                } else {
                    List {
                        ForEach(filteredEntries) { entry in
                            JournalEntryRow(entry: entry, tradingVM: tradingVM)
                                .onTapGesture {
                                    selectedEntry = entry
                                    showingEntrySheet = true
                                }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Trading Günlüğü")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedEntry) { entry in
                JournalEntryDetailView(entry: entry, tradingVM: tradingVM)
            }
        }
    }
}

struct JournalEntryRow: View {
    let entry: TradingJournalEntry
    @ObservedObject var tradingVM: TradingViewModel
    
    private var trade: Trade? {
        tradingVM.trades.first { $0.id == entry.tradeId }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Coin Symbol Badge
                Text(entry.coinSymbol)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.blue)
                    )
                
                Spacer()
                
                // Rating Stars
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { index in
                        Image(systemName: index <= entry.rating ? "star.fill" : "star")
                            .font(.system(size: 12))
                            .foregroundColor(index <= entry.rating ? .yellow : .gray.opacity(0.3))
                    }
                }
            }
            
            // Date
            Text(entry.entryDate, style: .date)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            // Notes Preview
            if !entry.notes.isEmpty {
                Text(entry.notes)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }
            
            // Strategy Preview
            if !entry.strategy.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    Text(entry.strategy)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            // Trade Info
            if let trade = trade {
                HStack(spacing: 8) {
                    Image(systemName: trade.type == .buy ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(trade.type == .buy ? .green : .red)
                    
                    Text("\(String(format: "%.4f", trade.amount)) @ \(formatCurrency(trade.price))")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }
}

struct JournalEntryDetailView: View {
    let entry: TradingJournalEntry
    @ObservedObject var tradingVM: TradingViewModel
    @Environment(\.dismiss) var dismiss
    @State private var editedEntry: TradingJournalEntry
    
    init(entry: TradingJournalEntry, tradingVM: TradingViewModel) {
        self.entry = entry
        self.tradingVM = tradingVM
        self._editedEntry = State(initialValue: entry)
    }
    
    private var trade: Trade? {
        tradingVM.trades.first { $0.id == entry.tradeId }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(entry.coinSymbol)
                                .font(.system(size: 24, weight: .bold))
                            
                            Spacer()
                            
                            // Rating
                            HStack(spacing: 4) {
                                ForEach(1...5, id: \.self) { index in
                                    Image(systemName: index <= editedEntry.rating ? "star.fill" : "star")
                                        .font(.system(size: 20))
                                        .foregroundColor(index <= editedEntry.rating ? .yellow : .gray.opacity(0.3))
                                        .onTapGesture {
                                            editedEntry.rating = index
                                        }
                                }
                            }
                        }
                        
                        Text(entry.entryDate, style: .date)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Trade Info
                    if let trade = trade {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("İşlem Bilgileri")
                                .font(.system(size: 18, weight: .bold))
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Tip")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                    Text(trade.type == .buy ? "Alış" : "Satış")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(trade.type == .buy ? .green : .red)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Miktar")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                    Text(String(format: "%.4f", trade.amount))
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Fiyat")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                    Text(formatCurrency(trade.price))
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    }
                    
                    // Strategy
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Strateji")
                            .font(.system(size: 18, weight: .bold))
                        
                        TextEditor(text: Binding(
                            get: { editedEntry.strategy },
                            set: { editedEntry.strategy = $0 }
                        ))
                        .frame(minHeight: 80)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    
                    // Emotions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Duygular")
                            .font(.system(size: 18, weight: .bold))
                        
                        TextEditor(text: Binding(
                            get: { editedEntry.emotions },
                            set: { editedEntry.emotions = $0 }
                        ))
                        .frame(minHeight: 80)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    
                    // Notes
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notlar")
                            .font(.system(size: 18, weight: .bold))
                        
                        TextEditor(text: Binding(
                            get: { editedEntry.notes },
                            set: { editedEntry.notes = $0 }
                        ))
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    
                    // Lessons Learned
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Öğrenilenler")
                            .font(.system(size: 18, weight: .bold))
                        
                        TextEditor(text: Binding(
                            get: { editedEntry.lessonsLearned },
                            set: { editedEntry.lessonsLearned = $0 }
                        ))
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Günlük Detayı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        saveEntry()
                    }
                    .foregroundColor(.blue)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
    
    private func saveEntry() {
        if let index = tradingVM.journalEntries.firstIndex(where: { $0.id == editedEntry.id }) {
            tradingVM.journalEntries[index] = editedEntry
            DataManager.shared.saveJournalEntries(tradingVM.journalEntries)
            HapticFeedback.success()
            dismiss()
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }
}

struct JournalFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticFeedback.selection()
            action()
        }) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemBackground))
                .cornerRadius(16)
        }
    }
}

