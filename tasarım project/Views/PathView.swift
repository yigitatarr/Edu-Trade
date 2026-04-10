//
//  PathView.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import SwiftUI

struct PathView: View {
    @ObservedObject var viewModel: LearningViewModel
    @EnvironmentObject var tradingVM: TradingViewModel
    @State private var selectedLevel: Level?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Clean background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // XP and Streak Header
                        ModernXPHeader(viewModel: viewModel)
                            .padding(.horizontal)
                            .padding(.top)
                        
                        // Learning Path
                        VStack(spacing: 20) {
                            ForEach(viewModel.levels) { level in
                                ModernLevelPathCard(
                                    level: level,
                                    isUnlocked: viewModel.isLevelUnlocked(level.id),
                                    isCompleted: viewModel.isLevelCompleted(level.id),
                                    currentLevel: viewModel.getCurrentUser().progress.currentLevel,
                                    viewModel: viewModel,
                                    onTap: {
                                        if viewModel.isLevelUnlocked(level.id) {
                                            selectedLevel = level
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }
            }
            .navigationTitle("Öğrenme Yolu")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedLevel) { level in
                LevelDetailView(level: level, viewModel: viewModel)
            }
        }
    }
}

struct ModernXPHeader: View {
    @ObservedObject var viewModel: LearningViewModel
    
    var user: User {
        viewModel.getCurrentUser()
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Level and XP Cards
            HStack(spacing: 12) {
                // Level Card
                VStack(spacing: 8) {
                    Text("\(user.progress.currentLevel)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.blue)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Text("Seviye")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                )
                
                // XP Card
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                        Text("\(user.progress.totalXP)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    
                    Text("Toplam XP")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                )
                
                // Streak Card
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                        Text("\(user.progress.streak)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    
                    Text("Gün Serisi")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                )
            }
            
            // XP Progress Bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(user.progress.currentLevelXP) / \(user.progress.currentLevel * 100) XP")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Spacer()
                    
                    Text("\(user.progress.xpToNextLevel) XP kaldı")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.blue)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                            .frame(height: 10)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue)
                            .frame(
                                width: geometry.size.width * user.progress.levelProgress,
                                height: 10
                            )
                    }
                }
                .frame(height: 10)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
            )
        }
    }
}

struct ModernLevelPathCard: View {
    let level: Level
    let isUnlocked: Bool
    let isCompleted: Bool
    let currentLevel: Int
    @ObservedObject var viewModel: LearningViewModel
    let onTap: () -> Void
    
    private var levelColor: Color {
        switch level.color {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        default: return .blue
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 20) {
                // Level Number Badge - Optimized
                ZStack {
                    Circle()
                        .fill(
                            isUnlocked ?
                                LinearGradient(
                                    colors: [levelColor, levelColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .frame(width: 70, height: 70)
                    
                    if isUnlocked {
                        Image(systemName: level.icon)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.gray)
                    }
                }
                
                // Content
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Text(level.title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(isUnlocked ? .primary : .secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                        
                        if isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 18))
                        }
                    }
                    
                    Text(level.description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if isUnlocked {
                        // Progress indicators
                        let completedLessons = level.lessons.filter { viewModel.isLessonCompleted($0) }.count
                        let totalLessons = level.lessons.count
                        let completedQuizzes = level.lessons.filter { viewModel.getQuizResult(for: $0) != nil }.count
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                HStack(spacing: 4) {
                                    Image(systemName: "book.fill")
                                        .font(.system(size: 10))
                                    Text("\(completedLessons)/\(totalLessons)")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundColor(completedLessons == totalLessons ? .green : .blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill((completedLessons == totalLessons ? Color.green : Color.blue).opacity(0.15))
                                )
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "brain.head.profile")
                                        .font(.system(size: 10))
                                    Text("\(completedQuizzes)/\(totalLessons)")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundColor(completedQuizzes == totalLessons ? .green : .blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill((completedQuizzes == totalLessons ? Color.green : Color.blue).opacity(0.15))
                                )
                            }
                            
                            if !isCompleted && isUnlocked {
                                ProgressView(value: Double(completedLessons + completedQuizzes), total: Double(totalLessons * 2))
                                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                    .frame(height: 6)
                            }
                        }
                    } else {
                        HStack(spacing: 12) {
                            Label("\(level.lessons.count) Ders", systemImage: "book.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Label("\(level.practiceChallenges.count) Görev", systemImage: "target")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                if isUnlocked {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(levelColor.opacity(0.5))
                }
            }
            .padding(18)
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
}

// Rest of the file remains the same...
struct LevelDetailView: View {
    let level: Level
    @ObservedObject var viewModel: LearningViewModel
    @EnvironmentObject var tradingVM: TradingViewModel
    @Environment(\.dismiss) var dismiss
    @State private var navigateToTrade = false
    @State private var selectedLesson: Lesson?
    @State private var selectedChallenge: Challenge?
    @State private var lessonForQuiz: Lesson?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Level Header
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top, spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.15))
                                        .frame(width: 64, height: 64)
                                    
                                    Image(systemName: level.icon)
                                        .font(.system(size: 28, weight: .medium))
                                        .foregroundColor(.blue)
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(level.title)
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.primary)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.9)
                                    
                                    Text(level.description)
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                
                                Spacer()
                            }
                        }
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                        )
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        // Lessons in this level
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Dersler")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                                .padding(.horizontal)
                            
                            ForEach(level.lessons, id: \.self) { lessonId in
                                if let lesson = viewModel.lessons.first(where: { $0.id == lessonId }) {
                                    ModernLessonRow(
                                        lesson: lesson,
                                        viewModel: viewModel,
                                        onTap: {
                                            selectedLesson = lesson
                                        }
                                    )
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Practice Challenges
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Pratik Görevleri")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                                .padding(.horizontal)
                            
                            ForEach(level.practiceChallenges, id: \.self) { challengeId in
                                if let challenge = viewModel.challenges.first(where: { $0.id == challengeId }) {
                                    ModernChallengeRow(
                                        challenge: challenge,
                                        viewModel: viewModel,
                                        isUnlocked: isChallengeUnlocked(challenge),
                                        onTap: {
                                            if isChallengeUnlocked(challenge) {
                                                if challenge.detailedDescription != nil {
                                                    selectedChallenge = challenge
                                                } else {
                                                    if challenge.requirements.tradeCount != nil || 
                                                       challenge.requirements.coinCount != nil {
                                                        navigateToTrade = true
                                                    }
                                                }
                                            }
                                        }
                                    )
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Seviye \(level.number)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Tamam") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $navigateToTrade) {
                TradeView(viewModel: tradingVM)
            }
            .sheet(item: $selectedLesson) { lesson in
                LessonDetailView(
                    lesson: lesson,
                    viewModel: viewModel,
                    onComplete: {
                        viewModel.completeLesson(lesson.id)
                    },
                    onQuiz: {
                        lessonForQuiz = lesson
                    }
                )
            }
            .sheet(item: $lessonForQuiz) { lesson in
                if let quiz = viewModel.quizzes.first(where: { $0.lessonId == lesson.id }) {
                    QuizView(quiz: quiz, viewModel: viewModel, lessonId: lesson.id)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("Bu ders için quiz henüz hazır değil.")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .sheet(item: $selectedChallenge) { challenge in
                ChallengeDetailView(challenge: challenge, viewModel: viewModel)
                    .environmentObject(tradingVM)
            }
        }
    }
    
    func isChallengeUnlocked(_ challenge: Challenge) -> Bool {
        guard let requiredChallengeId = challenge.requiredChallengeId else {
            return true
        }
        
        let user = viewModel.getCurrentUser()
        return user.progress.completedChallenges.contains(requiredChallengeId)
    }
    
    private var levelColor: Color {
        switch level.color {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        default: return .blue
        }
    }
}

struct ModernLessonRow: View {
    let lesson: Lesson
    @ObservedObject var viewModel: LearningViewModel
    let onTap: () -> Void
    
    var isCompleted: Bool {
        viewModel.isLessonCompleted(lesson.id)
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isCompleted ? Color.green.opacity(0.15) : Color.blue.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: lesson.icon)
                        .foregroundColor(isCompleted ? .green : .blue)
                        .font(.system(size: 20, weight: .medium))
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text(lesson.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.9)
                        
                        if isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 16))
                        }
                    }
                    
                    Text(lesson.category)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isCompleted ? Color.green.opacity(0.05) : Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ModernChallengeRow: View {
    let challenge: Challenge
    @ObservedObject var viewModel: LearningViewModel
    let isUnlocked: Bool
    let onTap: () -> Void
    
    var user: User {
        viewModel.getCurrentUser()
    }
    
    var isCompleted: Bool {
        user.progress.completedChallenges.contains(challenge.id)
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isCompleted ? Color.green.opacity(0.15) : (isUnlocked ? Color.blue.opacity(0.15) : Color.gray.opacity(0.15)))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: challenge.icon)
                        .foregroundColor(isCompleted ? .green : (isUnlocked ? .blue : .gray))
                        .font(.system(size: 20, weight: .medium))
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text(challenge.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isUnlocked ? .primary : .secondary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.9)
                        
                        if isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 16))
                        } else if !isUnlocked {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray)
                                .font(.system(size: 12))
                        }
                    }
                    
                    Text(challenge.description)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                if isUnlocked {
                    VStack(spacing: 2) {
                        Text("+\(challenge.xpReward)")
                            .font(.system(size: 13, weight: .bold))
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
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isCompleted ? Color.green.opacity(0.05) : (isUnlocked ? Color(.systemGray6) : Color(.systemGray5)))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isUnlocked)
    }
}

#Preview {
    PathView(viewModel: LearningViewModel())
        .environmentObject(TradingViewModel())
}
