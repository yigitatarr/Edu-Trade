//
//  ChallengesView.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import SwiftUI

struct ChallengesView: View {
    @ObservedObject var viewModel: LearningViewModel
    @State private var selectedTab = 0
    @State private var selectedChallenge: Challenge?
    
    var dailyChallenges: [Challenge] {
        viewModel.challenges.filter { $0.type == .daily }
    }
    
    var weeklyChallenges: [Challenge] {
        viewModel.challenges.filter { $0.type == .weekly }
    }
    
    var practiceChallenges: [Challenge] {
        viewModel.challenges.filter { $0.type == .practice }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Clean background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Tab Selector with Modern Design
                    ModernTabSelector(selectedTab: $selectedTab)
                        .padding()
                    
                    // Challenge List - Using LazyVStack for better performance
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            switch selectedTab {
                            case 0:
                                ModernChallengesSection(
                                    title: "Günlük Görevler",
                                    challenges: dailyChallenges,
                                    viewModel: viewModel,
                                    selectedChallenge: $selectedChallenge
                                )
                            case 1:
                                ModernChallengesSection(
                                    title: "Haftalık Görevler",
                                    challenges: weeklyChallenges,
                                    viewModel: viewModel,
                                    selectedChallenge: $selectedChallenge
                                )
                            case 2:
                                ModernChallengesSection(
                                    title: "Pratik Görevleri",
                                    challenges: practiceChallenges,
                                    viewModel: viewModel,
                                    selectedChallenge: $selectedChallenge
                                )
                            default:
                                EmptyView()
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(LocalizationHelper.shared.string(for: "learning.challenges"))
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                // Ensure challenges are loaded
                viewModel.loadData()
                viewModel.reloadChallenges()
            }
            .refreshable {
                viewModel.loadData()
                viewModel.reloadChallenges()
            }
            .sheet(item: $selectedChallenge) { challenge in
                ChallengeDetailView(challenge: challenge, viewModel: viewModel)
                    .environmentObject(TradingViewModel())
            }
        }
    }
}

struct ModernTabSelector: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 8) {
            TabButton(
                title: "Günlük",
                icon: "sun.max.fill",
                isSelected: selectedTab == 0
            ) {
                selectedTab = 0
            }
            
            TabButton(
                title: "Haftalık",
                icon: "calendar",
                isSelected: selectedTab == 1
            ) {
                selectedTab = 1
            }
            
            TabButton(
                title: "Pratik",
                icon: "target",
                isSelected: selectedTab == 2
            ) {
                selectedTab = 2
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundColor(isSelected ? .white : .blue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isSelected {
                        Capsule()
                            .fill(Color.blue)
                    } else {
                        Capsule()
                            .fill(Color.clear)
                    }
                }
            )
        }
    }
}

struct ModernChallengesSection: View {
    let title: String
    let challenges: [Challenge]
    @ObservedObject var viewModel: LearningViewModel
    @Binding var selectedChallenge: Challenge?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !challenges.isEmpty {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 4)
                
                ForEach(challenges) { challenge in
                    ModernChallengeCard(
                        challenge: challenge,
                        viewModel: viewModel,
                        onTap: {
                            selectedChallenge = challenge
                        }
                    )
                }
            } else {
                EmptyChallengesView()
            }
        }
    }
}

struct ModernChallengeCard: View {
    let challenge: Challenge
    @ObservedObject var viewModel: LearningViewModel
    @State private var showDetail = false
    let onTap: () -> Void
    
    var user: User {
        viewModel.getCurrentUser()
    }
    
    var isCompleted: Bool {
        user.progress.completedChallenges.contains(challenge.id)
    }
    
    var isUnlocked: Bool {
        guard let requiredChallengeId = challenge.requiredChallengeId else {
            return true
        }
        return user.progress.completedChallenges.contains(requiredChallengeId)
    }
    
    var progress: Double {
        if isCompleted {
            return 1.0
        }
        
        if let tradeCount = challenge.requirements.tradeCount {
            return min(Double(user.numberOfTrades) / Double(tradeCount), 1.0)
        } else if let coinCount = challenge.requirements.coinCount {
            return min(Double(user.portfolio.count) / Double(coinCount), 1.0)
        } else if let lessonId = challenge.requirements.lessonId {
            return viewModel.isLessonCompleted(lessonId) ? 1.0 : 0.0
        } else if let quizScore = challenge.requirements.quizScore {
            let completedQuizzes = viewModel.quizResults.count
            return min(Double(completedQuizzes) / Double(quizScore), 1.0)
        }
        return 0.0
    }
    
    var progressText: String {
        if isCompleted {
            return "Tamamlandı!"
        }
        
        if let tradeCount = challenge.requirements.tradeCount {
            return "\(user.numberOfTrades)/\(tradeCount) işlem"
        } else if let coinCount = challenge.requirements.coinCount {
            return "\(user.portfolio.count)/\(coinCount) coin"
        } else if let lessonId = challenge.requirements.lessonId {
            return viewModel.isLessonCompleted(lessonId) ? "Ders tamamlandı" : "Başlanmadı"
        } else if let quizScore = challenge.requirements.quizScore {
            return "\(viewModel.quizResults.count)/\(quizScore) quiz"
        }
        return "Devam ediyor"
    }
    
    var body: some View {
        Button(action: {
            if isUnlocked {
                onTap()
            }
        }) {
            VStack(spacing: 0) {
                HStack(spacing: 18) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                isCompleted ? Color.green.opacity(0.15) :
                                (isUnlocked ? Color.blue.opacity(0.15) : Color.gray.opacity(0.15))
                            )
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: challenge.icon)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(isCompleted ? .green : (isUnlocked ? .blue : .gray))
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Text(challenge.title)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(isUnlocked ? .primary : .secondary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.9)
                            
                            if isCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 18))
                            } else if !isUnlocked {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 12))
                            }
                        }
                        
                        Text(challenge.description)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Progress Bar
                        if !isCompleted && isUnlocked {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.gray.opacity(0.15))
                                        .frame(height: 8)
                                    
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(
                                            LinearGradient(
                                                colors: [challengeColor, challengeColor.opacity(0.7)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * progress, height: 8)
                                        .shadow(color: challengeColor.opacity(0.3), radius: 4, x: 0, y: 2)
                                }
                            }
                            .frame(height: 8)
                            
                            Text(progressText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // XP Badge
                    if isUnlocked {
                        VStack(spacing: 2) {
                            HStack(spacing: 3) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                Text("\(challenge.xpReward)")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(.blue)
                            
                            Text("XP")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                        )
                    }
                }
                .padding(20)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!isUnlocked)
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
    
    private var challengeColor: Color {
        // Tutarlı renk paleti - hepsi mavi tonları
        return .blue
    }
}

struct EmptyChallengesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "target")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("Henüz görev yok")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 5)
        )
    }
}

#Preview {
    ChallengesView(viewModel: LearningViewModel())
        .environmentObject(TradingViewModel())
}
