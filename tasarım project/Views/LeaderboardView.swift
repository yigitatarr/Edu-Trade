//
//  LeaderboardView.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import SwiftUI

struct LeaderboardView: View {
    @ObservedObject var viewModel = LeaderboardViewModel.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Sort selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(LeaderboardSortOption.allCases, id: \.self) { option in
                                SortButton(
                                    option: option,
                                    isSelected: viewModel.sortOption == option,
                                    action: {
                                        viewModel.sortOption = option
                                        viewModel.sortLeaderboard()
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                    .background(Color(.systemBackground))
                    
                    // Leaderboard list
                    if viewModel.entries.isEmpty {
                        EmptyStateView(
                            icon: "trophy.fill",
                            title: "Liderlik Tablosu Boş",
                            message: "Henüz hiç kullanıcı yok. İlk siz olun!"
                        )
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                // Top 3 podium
                                if viewModel.entries.count >= 3 {
                                    TopThreePodium(entries: Array(viewModel.entries.prefix(3)), sortOption: viewModel.sortOption)
                                        .padding(.horizontal)
                                        .padding(.top)
                                }
                                
                                // Rest of leaderboard
                                LazyVStack(spacing: 8) {
                                    ForEach(Array(viewModel.entries.enumerated()), id: \.element.id) { index, entry in
                                        LeaderboardRow(
                                            entry: entry,
                                            rank: index + 1,
                                            isCurrentUser: entry.userName == viewModel.currentUserEntry?.userName
                                        )
                                        .padding(.horizontal)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
            }
            .navigationTitle(LocalizationHelper.shared.string(for: "leaderboard.title"))
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.updateCurrentUserEntry()
            }
            .refreshable {
                viewModel.updateCurrentUserEntry()
            }
        }
    }
}

struct SortButton: View {
    let option: LeaderboardSortOption
    let isSelected: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticFeedback.selection()
            action()
        }) {
            HStack(spacing: 6) {
                Image(systemName: option.icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(option.rawValue)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(
                        isSelected ?
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [Color(.systemGray6), Color(.systemGray6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

struct TopThreePodium: View {
    let entries: [LeaderboardEntry]
    let sortOption: LeaderboardSortOption
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            if entries.count > 1 {
                PodiumCard(entry: entries[1], rank: 2, height: 120, sortOption: sortOption)
            }
            if entries.count > 0 {
                PodiumCard(entry: entries[0], rank: 1, height: 150, sortOption: sortOption)
            }
            if entries.count > 2 {
                PodiumCard(entry: entries[2], rank: 3, height: 100, sortOption: sortOption)
            }
        }
    }
}

struct PodiumCard: View {
    let entry: LeaderboardEntry
    let rank: Int
    let height: CGFloat
    let sortOption: LeaderboardSortOption
    
    var medalColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2) // Bronze
        default: return .blue
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Medal
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [medalColor.opacity(0.3), medalColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: "medal.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [medalColor, medalColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            // Name
            Text(entry.userName)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            // Value based on sort
            Text(formatValue(for: entry))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primaryGradient)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(width: 100, height: height)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    private func formatValue(for entry: LeaderboardEntry) -> String {
        switch sortOption {
        case .xp: return "\(entry.totalXP) XP"
        case .profit: return String(format: "$%.0f", entry.totalProfit)
        case .winRate: return String(format: "%.1f%%", entry.winRate)
        case .trades: return "\(entry.totalTrades) İşlem"
        case .level: return "Lv. \(entry.level)"
        case .streak: return "\(entry.streak) Gün"
        }
    }
}

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let rank: Int
    let isCurrentUser: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank
            ZStack {
                Circle()
                    .fill(
                        isCurrentUser ?
                        LinearGradient(
                            colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color(.systemGray6), Color(.systemGray6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                
                Text("\(rank)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(isCurrentUser ? .blue : .primary)
            }
            
            // User info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(entry.userName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    
                    if isCurrentUser {
                        Text("(Siz)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.blue)
                    }
                }
                
                HStack(spacing: 12) {
                    Label("\(entry.totalXP)", systemImage: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Label("\(entry.level)", systemImage: "trophy.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Stats
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatCurrency(entry.totalProfit))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(entry.totalProfit >= 0 ? .green : .red)
                
                Text(String(format: "%.1f%%", entry.winRate))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isCurrentUser ? Color.blue.opacity(0.1) : Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isCurrentUser ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 2)
        )
        .modernCard()
    }
    
    private func formatCurrency(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "$%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "$%.1fK", value / 1_000)
        } else {
            return String(format: "$%.0f", value)
        }
    }
}

#Preview {
    LeaderboardView()
}

