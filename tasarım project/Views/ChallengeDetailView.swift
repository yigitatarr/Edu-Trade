//
//  ChallengeDetailView.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import SwiftUI

struct ChallengeDetailView: View {
    let challenge: Challenge
    @ObservedObject var viewModel: LearningViewModel
    @EnvironmentObject var tradingVM: TradingViewModel
    @Environment(\.dismiss) var dismiss
    @State private var navigateToTrade = false
    @State private var selectedLesson: Lesson?
    @State private var lessonForQuiz: Lesson?
    
    var user: User {
        viewModel.getCurrentUser()
    }
    
    var isCompleted: Bool {
        user.progress.completedChallenges.contains(challenge.id)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero Header with Gradient
                    ChallengeHeroHeader(
                        challenge: challenge,
                        isCompleted: isCompleted,
                        xpReward: challenge.xpReward
                    )
                    
                    VStack(spacing: 24) {
                        // Challenge Description Card
                        if let detailedDescription = challenge.detailedDescription {
                            DescriptionCard(description: detailedDescription)
                        }
                        
                        // Step-by-Step Guide
                        if let steps = challenge.steps, !steps.isEmpty {
                            StepByStepGuide(
                                steps: steps,
                                challenge: challenge,
                                viewModel: viewModel,
                                onNavigateToTrade: { navigateToTrade = true },
                                onNavigateToLesson: { lessonId in
                                    selectedLesson = viewModel.lessons.first(where: { $0.id == lessonId })
                                },
                                onNavigateToQuiz: { lessonId in
                                    if let lesson = viewModel.lessons.first(where: { $0.id == lessonId }) {
                                        lessonForQuiz = lesson
                                    }
                                }
                            )
                        }
                        
                        // Requirements Card
                        RequirementsCard(
                            requirements: challenge.requirements,
                            user: user,
                            viewModel: viewModel
                        )
                        
                        // Action Button
                        if !isCompleted {
                            ActionButtonCard(
                                challenge: challenge,
                                onAction: handleAction,
                                actionText: actionText,
                                actionIcon: actionIcon
                            )
                        } else {
                            CompletedBadge()
                        }
                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Görev Detayı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
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
        }
    }
    
    private var actionText: String {
        if challenge.requirements.tradeCount != nil || challenge.requirements.coinCount != nil {
            return "İşlem Yapmaya Başla"
        } else if challenge.requirements.lessonId != nil {
            return "Dersi Oku"
        } else if challenge.requirements.quizScore != nil {
            return "Quiz Yap"
        }
        return "Başla"
    }
    
    private var actionIcon: String {
        if challenge.requirements.tradeCount != nil || challenge.requirements.coinCount != nil {
            return "dollarsign.circle.fill"
        } else if challenge.requirements.lessonId != nil {
            return "book.fill"
        } else if challenge.requirements.quizScore != nil {
            return "brain.head.profile"
        }
        return "arrow.right.circle.fill"
    }
    
    private func handleAction() {
        if challenge.requirements.tradeCount != nil || challenge.requirements.coinCount != nil {
            navigateToTrade = true
        } else if let lessonId = challenge.requirements.lessonId {
            selectedLesson = viewModel.lessons.first(where: { $0.id == lessonId })
        }
    }
}

// MARK: - Hero Header
struct ChallengeHeroHeader: View {
    let challenge: Challenge
    let isCompleted: Bool
    let xpReward: Int
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Gradient Background - Optimized (removed blur)
            LinearGradient(
                colors: [
                    challengeColor.opacity(0.9),
                    challengeColor.opacity(0.7),
                    challengeColor.opacity(0.4),
                    Color(.systemGroupedBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 220)
            
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top, spacing: 20) {
                    // Icon - Optimized
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.4), Color.white.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: challenge.icon)
                            .font(.system(size: 48, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(challenge.title)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                        
                        HStack(spacing: 12) {
                            // XP Badge
                            HStack(spacing: 8) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                Text("+\(xpReward) XP")
                                    .font(.system(size: 15, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.25))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                    )
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                            
                            if isCompleted {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Tamamlandı")
                                        .font(.system(size: 15, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(Color.green.opacity(0.4))
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                )
                                .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(24)
            }
        }
    }
    
    private var challengeColor: Color {
        switch challenge.type {
        case .daily: return .blue
        case .weekly: return .purple
        case .practice: return .orange
        case .achievement: return .yellow
        }
    }
}

// MARK: - Description Card
struct DescriptionCard: View {
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "info.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                
                Text("Görev Hakkında")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            Text(description)
                .font(.system(size: 16))
                .lineSpacing(8)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }
}

// MARK: - Step by Step Guide
struct StepByStepGuide: View {
    let steps: [ChallengeStep]
    let challenge: Challenge
    @ObservedObject var viewModel: LearningViewModel
    let onNavigateToTrade: () -> Void
    let onNavigateToLesson: (String) -> Void
    let onNavigateToQuiz: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.2), Color.orange.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "list.number")
                        .font(.title3)
                        .foregroundColor(.orange)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Adım Adım Rehberlik")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Bu görevi tamamlamak için aşağıdaki adımları takip et")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(spacing: 16) {
                ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                    StepRow(
                        step: step,
                        stepNumber: index + 1,
                        totalSteps: steps.count,
                        challenge: challenge,
                        viewModel: viewModel,
                        onNavigateToTrade: onNavigateToTrade,
                        onNavigateToLesson: onNavigateToLesson,
                        onNavigateToQuiz: onNavigateToQuiz
                    )
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }
}

struct StepRow: View {
    let step: ChallengeStep
    let stepNumber: Int
    let totalSteps: Int
    let challenge: Challenge
    @ObservedObject var viewModel: LearningViewModel
    let onNavigateToTrade: () -> Void
    let onNavigateToLesson: (String) -> Void
    let onNavigateToQuiz: (String) -> Void
    
    var isStepCompleted: Bool {
        switch step.action {
        case .navigateToLesson:
            if let lessonId = challenge.requirements.lessonId {
                return viewModel.isLessonCompleted(lessonId)
            }
            return false
        case .navigateToQuiz:
            if let lessonId = challenge.requirements.lessonId {
                return viewModel.getQuizResult(for: lessonId) != nil
            }
            return false
        case .navigateToTrade:
            if let tradeCount = challenge.requirements.tradeCount {
                return viewModel.getCurrentUser().numberOfTrades >= tradeCount
            }
            return false
        case .completeAction:
            return viewModel.getCurrentUser().progress.completedChallenges.contains(challenge.id)
        case .readContent:
            if let lessonId = challenge.requirements.lessonId {
                return viewModel.isLessonCompleted(lessonId)
            }
            return false
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            // Step Number Circle - Optimized
            ZStack {
                Circle()
                    .fill(
                        isStepCompleted ?
                            LinearGradient(
                                colors: [Color.green, Color.green.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.orange, Color.orange.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .frame(width: 50, height: 50)
                
                if isStepCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(stepNumber)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            // Step Content
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: step.icon)
                        .font(.caption)
                        .foregroundColor(isStepCompleted ? .green : .orange)
                    
                    Text(step.title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                Text(step.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Action Button
                if !isStepCompleted {
                    Button(action: handleStepAction) {
                        HStack(spacing: 8) {
                            Image(systemName: actionIcon)
                                .font(.caption)
                            Text(actionText)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.orange, Color.orange.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: Color.orange.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(isStepCompleted ? Color.green.opacity(0.08) : Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private var actionText: String {
        switch step.action {
        case .navigateToTrade: return "İşlem Yap"
        case .navigateToLesson: return "Dersi Aç"
        case .navigateToQuiz: return "Quiz Yap"
        case .readContent: return "İçeriği Oku"
        case .completeAction: return "Tamamla"
        }
    }
    
    private var actionIcon: String {
        switch step.action {
        case .navigateToTrade: return "dollarsign.circle.fill"
        case .navigateToLesson: return "book.fill"
        case .navigateToQuiz: return "brain.head.profile"
        case .readContent: return "doc.text.fill"
        case .completeAction: return "checkmark.circle.fill"
        }
    }
    
    private func handleStepAction() {
        switch step.action {
        case .navigateToTrade:
            onNavigateToTrade()
        case .navigateToLesson:
            if let lessonId = challenge.requirements.lessonId {
                onNavigateToLesson(lessonId)
            }
        case .navigateToQuiz:
            if let lessonId = challenge.requirements.lessonId {
                onNavigateToQuiz(lessonId)
            }
        case .readContent:
            if let lessonId = challenge.requirements.lessonId {
                onNavigateToLesson(lessonId)
            }
        case .completeAction:
            break
        }
    }
}

// MARK: - Requirements Card
struct RequirementsCard: View {
    let requirements: Challenge.ChallengeRequirements
    let user: User
    @ObservedObject var viewModel: LearningViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "checklist")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                
                Text("Gereksinimler")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            RequirementsList(requirements: requirements, user: user, viewModel: viewModel)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }
}

struct RequirementsList: View {
    let requirements: Challenge.ChallengeRequirements
    let user: User
    @ObservedObject var viewModel: LearningViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let tradeCount = requirements.tradeCount {
                RequirementRow(
                    icon: "arrow.left.arrow.right.circle.fill",
                    text: "\(tradeCount) işlem tamamla",
                    completed: user.numberOfTrades >= tradeCount,
                    current: user.numberOfTrades,
                    required: tradeCount
                )
            }
            
            if let coinCount = requirements.coinCount {
                RequirementRow(
                    icon: "bitcoinsign.circle.fill",
                    text: "\(coinCount) farklı coin bulundur",
                    completed: user.portfolio.count >= coinCount,
                    current: user.portfolio.count,
                    required: coinCount
                )
            }
            
            if let lessonId = requirements.lessonId {
                if let lesson = viewModel.lessons.first(where: { $0.id == lessonId }) {
                    RequirementRow(
                        icon: "book.fill",
                        text: "Tamamla: \(lesson.title)",
                        completed: viewModel.isLessonCompleted(lessonId),
                        current: viewModel.isLessonCompleted(lessonId) ? 1 : 0,
                        required: 1
                    )
                }
            }
            
            if let quizScore = requirements.quizScore {
                RequirementRow(
                    icon: "brain.head.profile",
                    text: "\(quizScore) quiz tamamla",
                    completed: viewModel.quizResults.count >= quizScore,
                    current: viewModel.quizResults.count,
                    required: quizScore
                )
            }
        }
    }
}

struct RequirementRow: View {
    let icon: String
    let text: String
    let completed: Bool
    let current: Int
    let required: Int
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        completed ?
                            LinearGradient(
                                colors: [Color.green.opacity(0.2), Color.green.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.orange.opacity(0.2), Color.orange.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .foregroundColor(completed ? .green : .orange)
                    .font(.title3)
            }
            
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            if required > 1 {
                Text("\(current)/\(required)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(
                                completed ?
                                    LinearGradient(
                                        colors: [Color.green, Color.green.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ) :
                                    LinearGradient(
                                        colors: [Color.orange, Color.orange.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                            )
                    )
                    .shadow(color: (completed ? Color.green : Color.orange).opacity(0.3), radius: 8, x: 0, y: 4)
            } else {
                if completed {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                    }
                }
            }
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Action Button Card
struct ActionButtonCard: View {
    let challenge: Challenge
    let onAction: () -> Void
    let actionText: String
    let actionIcon: String
    
    var body: some View {
        Button(action: onAction) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: actionIcon)
                        .font(.system(size: 20, weight: .semibold))
                }
                
                Text(actionText)
                    .font(.system(size: 18, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color.orange, Color.orange.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .foregroundColor(.white)
            .shadow(color: Color.orange.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Completed Badge
struct CompletedBadge: View {
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24, weight: .semibold))
            }
            
            Text("Görev Tamamlandı!")
                .font(.system(size: 18, weight: .bold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color.green.opacity(0.15), Color.green.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.green.opacity(0.3), lineWidth: 2)
                    )
            }
        )
        .foregroundColor(.green)
        .shadow(color: Color.green.opacity(0.2), radius: 10, x: 0, y: 4)
    }
}

#Preview {
    ChallengeDetailView(
        challenge: Challenge(
            id: "test",
            title: "Test Challenge",
            description: "Test",
            type: .practice,
            xpReward: 20,
            icon: "star.fill",
            requirements: Challenge.ChallengeRequirements(tradeCount: 1),
            requiredChallengeId: nil,
            detailedDescription: "Test description",
            steps: nil
        ),
        viewModel: LearningViewModel()
    )
    .environmentObject(TradingViewModel())
}
