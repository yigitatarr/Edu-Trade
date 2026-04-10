//
//  PriceAlertsView.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import SwiftUI

struct PriceAlertsView: View {
    @ObservedObject var viewModel: TradingViewModel
    @State private var showingAddAlert = false
    @State private var selectedCoin: Coin?
    
    var activeAlerts: [PriceAlert] {
        viewModel.priceAlerts.filter { $0.isActive }
    }
    
    var triggeredAlerts: [PriceAlert] {
        viewModel.priceAlerts.filter { !$0.isActive && $0.triggeredAt != nil }
    }
    
    var body: some View {
        List {
            // Active Alerts
            if !activeAlerts.isEmpty {
                Section {
                    ForEach(activeAlerts) { alert in
                        AlertRow(alert: alert, viewModel: viewModel)
                    }
                } header: {
                    Text("Aktif Alarmlar")
                }
            }
            
            // Triggered Alerts
            if !triggeredAlerts.isEmpty {
                Section {
                    ForEach(triggeredAlerts) { alert in
                        AlertRow(alert: alert, viewModel: viewModel)
                    }
                } header: {
                    Text("Tetiklenen Alarmlar")
                }
            }
            
            if activeAlerts.isEmpty && triggeredAlerts.isEmpty {
                Section {
                    EmptyStateView(
                        icon: "bell.fill",
                        title: "Alarm Yok",
                        message: "Henüz fiyat alarmı oluşturulmamış."
                    )
                }
            }
        }
        .navigationTitle(LocalizationHelper.shared.string(for: "alert.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddAlert = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddAlert) {
            AddPriceAlertView(viewModel: viewModel)
        }
    }
}

struct AlertRow: View {
    let alert: PriceAlert
    @ObservedObject var viewModel: TradingViewModel
    @State private var showingEditSheet = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.coinSymbol)
                    .font(.headline)
                
                HStack(spacing: 4) {
                    Image(systemName: alert.condition == .above ? "arrow.up" : "arrow.down")
                        .font(.caption)
                    Text(formatCurrency(alert.targetPrice))
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)
                
                if let triggeredAt = alert.triggeredAt {
                    Text("Tetiklenme: \(triggeredAt, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("Beklemede")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            if !alert.isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
            
            if alert.isActive {
                Button(action: {
                    showingEditSheet = true
                }) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                }
            }
            
            Button(role: .destructive, action: {
                viewModel.deletePriceAlert(alert)
            }) {
                Image(systemName: "trash")
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingEditSheet) {
            EditPriceAlertView(viewModel: viewModel, alert: alert)
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// MARK: - Edit Price Alert View
struct EditPriceAlertView: View {
    @ObservedObject var viewModel: TradingViewModel
    let alert: PriceAlert
    @Environment(\.dismiss) var dismiss
    @State private var targetPrice: String = ""
    @State private var condition: AlertCondition = .above
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Alarm Bilgileri") {
                    HStack {
                        Text("Coin")
                        Spacer()
                        Text(alert.coinSymbol)
                            .foregroundColor(.secondary)
                    }
                    
                    TextField("Hedef Fiyat", text: $targetPrice)
                        .keyboardType(.decimalPad)
                    
                    Picker("Koşul", selection: $condition) {
                        Text("Üzerinde").tag(AlertCondition.above)
                        Text("Altında").tag(AlertCondition.below)
                    }
                }
                
                if let coin = DataManager.shared.coins.first(where: { $0.symbol == alert.coinSymbol }) {
                    Section("Güncel Fiyat") {
                        HStack {
                            Text(coin.formattedPrice)
                                .font(.headline)
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: coin.change24h >= 0 ? "arrow.up" : "arrow.down")
                                    .font(.caption)
                                Text(String(format: "%.2f%%", coin.change24h))
                                    .font(.subheadline)
                            }
                            .foregroundColor(coin.change24h >= 0 ? .green : .red)
                        }
                    }
                }
            }
            .navigationTitle("Alarm Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Güncelle") {
                        guard let price = Double(targetPrice), price > 0 else { return }
                        // Eski alarmi sil, yenisini olustur
                        viewModel.deletePriceAlert(alert)
                        if let coin = DataManager.shared.coins.first(where: { $0.symbol == alert.coinSymbol }) {
                            viewModel.createPriceAlert(coin: coin, targetPrice: price, condition: condition)
                        }
                        HapticFeedback.success()
                        dismiss()
                    }
                    .disabled(Double(targetPrice) == nil || Double(targetPrice) == 0)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                targetPrice = String(format: "%.0f", alert.targetPrice)
                condition = alert.condition
            }
        }
    }
}

struct AddPriceAlertView: View {
    @ObservedObject var viewModel: TradingViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedCoin: Coin?
    @State private var targetPrice: String = ""
    @State private var condition: AlertCondition = .above
    
    var coins: [Coin] {
        DataManager.shared.coins
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Coin", selection: $selectedCoin) {
                        Text("Coin Seç").tag(nil as Coin?)
                        ForEach(coins) { coin in
                            Text("\(coin.symbol) - \(coin.name)").tag(coin as Coin?)
                        }
                    }
                    
                    TextField("Hedef Fiyat", text: $targetPrice)
                        .keyboardType(.decimalPad)
                    
                    Picker("Koşul", selection: $condition) {
                        Text("Üzerinde").tag(AlertCondition.above)
                        Text("Altında").tag(AlertCondition.below)
                    }
                } header: {
                    Text("Alarm Detayları")
                }
                
                if let coin = selectedCoin, let price = Double(targetPrice), price > 0 {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Özet")
                                .font(.headline)
                            
                            Text("\(coin.symbol) fiyatı \(formatCurrency(price)) seviyesinin \(condition == .above ? "üzerine" : "altına") düştüğünde bildirim gönderilecek.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Yeni Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        if let coin = selectedCoin, let price = Double(targetPrice) {
                            viewModel.createPriceAlert(
                                coin: coin,
                                targetPrice: price,
                                condition: condition
                            )
                            dismiss()
                        }
                    }
                    .disabled(selectedCoin == nil || Double(targetPrice) == nil)
                }
            }
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}



