//
//  PendingOrdersView.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import SwiftUI

struct PendingOrdersView: View {
    @ObservedObject var tradingVM: TradingViewModel
    @ObservedObject var dataManager = DataManager.shared
    @State private var selectedOrder: Order?
    @State private var showingCancelAlert = false
    @State private var showingAddLimitOrder = false
    @State private var selectedCoin: Coin?
    
    private var pendingOrders: [Order] {
        tradingVM.orders.filter { $0.status == .pending }
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    private var executedOrders: [Order] {
        tradingVM.orders.filter { $0.status == .executed }
            .sorted { ($0.executedAt ?? $0.createdAt) > ($1.executedAt ?? $1.createdAt) }
            .prefix(10)
            .map { $0 }
    }
    
    private var failedOrders: [Order] {
        tradingVM.orders.filter { $0.status == .failed }
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if pendingOrders.isEmpty && executedOrders.isEmpty && failedOrders.isEmpty {
                    EmptyStateView(
                        icon: "list.bullet.rectangle",
                        title: "Emir Yok",
                        message: "Henüz limit emri oluşturmadınız. İşlem ekranında 'Limit' emir tipini seçerek limit emri oluşturabilirsiniz."
                    )
                } else {
                    List {
                        // Pending Orders Section
                        if !pendingOrders.isEmpty {
                            Section {
                                ForEach(pendingOrders) { order in
                                    OrderRow(order: order, tradingVM: tradingVM)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            Button(role: .destructive) {
                                                selectedOrder = order
                                                showingCancelAlert = true
                                            } label: {
                                                Label("İptal", systemImage: "xmark.circle")
                                            }
                                        }
                                }
                            } header: {
                                Text("Bekleyen Emirler (\(pendingOrders.count))")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                        
                        if !executedOrders.isEmpty {
                            Section {
                                ForEach(executedOrders) { order in
                                    OrderRow(order: order, tradingVM: tradingVM)
                                }
                            } header: {
                                Text("Tamamlanan Emirler (Son 10)")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                        
                        if !failedOrders.isEmpty {
                            Section {
                                ForEach(failedOrders) { order in
                                    OrderRow(order: order, tradingVM: tradingVM)
                                }
                            } header: {
                                Text("Başarısız Emirler")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Limit Emirleri")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            showingAddLimitOrder = true
                        }) {
                            Label("Yeni Limit Emri", systemImage: "plus.circle.fill")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddLimitOrder, onDismiss: {
                selectedCoin = nil
            }) {
                if let coin = selectedCoin {
                    QuickLimitOrderSheet(coin: coin, viewModel: tradingVM)
                } else {
                    CoinSelectionForOrderView(
                        coins: dataManager.coins,
                        onCoinSelected: { coin in
                            selectedCoin = coin
                        }
                    )
                }
            }
            .alert("Emri İptal Et", isPresented: $showingCancelAlert) {
                Button("İptal", role: .cancel) {
                    selectedOrder = nil
                }
                Button("Evet, İptal Et", role: .destructive) {
                    if let order = selectedOrder {
                        tradingVM.cancelOrder(order)
                        selectedOrder = nil
                        HapticFeedback.success()
                    }
                }
            } message: {
                if let order = selectedOrder {
                    Text("\(order.coinSymbol) için limit emrini iptal etmek istediğinize emin misiniz?")
                }
            }
        }
    }
}

struct OrderRow: View {
    let order: Order
    @ObservedObject var tradingVM: TradingViewModel
    
    private var currentPrice: Double? {
        DataManager.shared.coins.first(where: { $0.symbol == order.coinSymbol })?.price
    }
    
    private var priceDifference: Double? {
        guard let currentPrice = currentPrice,
              let limitPrice = order.limitPrice else {
            return nil
        }
        return currentPrice - limitPrice
    }
    
    private var priceDifferencePercentage: Double? {
        guard let limitPrice = order.limitPrice,
              let difference = priceDifference else {
            return nil
        }
        return (difference / limitPrice) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Coin Symbol Badge
                Text(order.coinSymbol)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(order.type == .limitBuy ? Color.green : Color.red)
                    )
                
                Spacer()
                
                // Status Badge
                StatusBadge(status: order.status)
            }
            
            // Order Type and Amount
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(order.type == .limitBuy ? "Limit Alış" : "Limit Satış")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Miktar: \(String(format: "%.4f", order.amount))")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if let limitPrice = order.limitPrice {
                        Text("Limit: \(formatCurrency(limitPrice))")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    if let currentPrice = currentPrice, order.status == .pending {
                        HStack(spacing: 4) {
                            Text("Güncel: \(formatCurrency(currentPrice))")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            if let percentage = priceDifferencePercentage {
                                Image(systemName: percentage >= 0 ? "arrow.up" : "arrow.down")
                                    .font(.system(size: 10))
                                Text("%\(String(format: "%.1f", abs(percentage)))")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                        }
                        .foregroundColor(priceDifferencePercentage ?? 0 >= 0 ? .green : .red)
                    }
                }
            }
            
            // Stop Loss and Take Profit
            if order.stopLoss != nil || order.takeProfit != nil {
                HStack(spacing: 16) {
                    if let stopLoss = order.stopLoss {
                        HStack(spacing: 4) {
                            Image(systemName: "hand.raised.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                            Text("SL: \(formatCurrency(stopLoss))")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let takeProfit = order.takeProfit {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.right.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.green)
                            Text("TP: \(formatCurrency(takeProfit))")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Date
            HStack {
                Text("Oluşturulma: \(order.createdAt, style: .relative)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                if let executedAt = order.executedAt {
                    Spacer()
                    Text("Tamamlanma: \(executedAt, style: .relative)")
                        .font(.system(size: 11))
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }
}

struct StatusBadge: View {
    let status: OrderStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: statusIcon)
                .font(.system(size: 10))
            Text(statusText)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(statusColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(statusColor.opacity(0.15))
        )
    }
    
    private var statusIcon: String {
        switch status {
        case .pending: return "clock.fill"
        case .executed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }
    
    private var statusText: String {
        switch status {
        case .pending: return "Bekliyor"
        case .executed: return "Tamamlandı"
        case .cancelled: return "İptal Edildi"
        case .failed: return "Başarısız"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .pending: return .orange
        case .executed: return .green
        case .cancelled: return .red
        case .failed: return .purple
        }
    }
}

// MARK: - Coin Selection for Order
struct CoinSelectionForOrderView: View {
    let coins: [Coin]
    let onCoinSelected: (Coin) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    
    private var filteredCoins: [Coin] {
        if searchText.isEmpty {
            return coins
        } else {
            return coins.filter { coin in
                coin.name.localizedCaseInsensitiveContains(searchText) ||
                coin.symbol.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredCoins) { coin in
                    Button(action: {
                        onCoinSelected(coin)
                        dismiss()
                    }) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue.opacity(0.15), Color.purple.opacity(0.15)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "bitcoinsign.circle.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(coin.symbol)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text(coin.name)
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(formatCurrency(coin.price))
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: coin.change24h >= 0 ? "arrow.up" : "arrow.down")
                                        .font(.system(size: 10))
                                    Text("\(String(format: "%.2f", coin.change24h))%")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundColor(coin.change24h >= 0 ? .green : .red)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .searchable(text: $searchText, prompt: "Coin ara...")
            .navigationTitle("Coin Seç")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }
}

