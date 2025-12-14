//
//  LearnView.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import SwiftUI

struct LearnView: View {
    @ObservedObject var viewModel: LearningViewModel
    @State private var selectedTab = 0
    @State private var selectedLesson: Lesson?
    @State private var lessonForQuiz: Lesson?
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Learning Path (Duolingo style)
            PathView(viewModel: viewModel)
                .tabItem {
                    Label("Yol", systemImage: "map.fill")
                }
                .tag(0)
            
            // All Lessons View
            AllLessonsView(
                viewModel: viewModel,
                selectedLesson: $selectedLesson,
                lessonForQuiz: $lessonForQuiz
            )
            .tabItem {
                Label("Dersler", systemImage: "book.fill")
            }
            .tag(1)
            
            // Challenges View
            ChallengesView(viewModel: viewModel)
                .tabItem {
                    Label("Görevler", systemImage: "target")
                }
                .tag(2)
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
            }
        }
        .accessibilitySupport()
    }
}

struct AllLessonsView: View {
    @ObservedObject var viewModel: LearningViewModel
    @Binding var selectedLesson: Lesson?
    @Binding var lessonForQuiz: Lesson?
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    
    var filteredLessons: [Lesson] {
        var lessons = viewModel.lessons
        
        // Category filter
        if let category = selectedCategory {
            lessons = lessons.filter { $0.category == category }
        }
        
        // Search filter
        if !searchText.isEmpty {
            lessons = lessons.filter { lesson in
                lesson.title.localizedCaseInsensitiveContains(searchText) ||
                lesson.content.localizedCaseInsensitiveContains(searchText) ||
                lesson.category.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return lessons
    }
    
    var categories: [String] {
        Array(Set(viewModel.lessons.map { $0.category })).sorted()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Clean background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if viewModel.lessons.isEmpty {
                    EmptyStateView(
                        icon: "book.fill",
                        title: "Ders Bulunamadı",
                        message: "Henüz hiç ders yüklenmedi. Lütfen daha sonra tekrar deneyin."
                    )
                } else {
                    VStack(spacing: 0) {
                        // Search and filter bar
                        VStack(spacing: 12) {
                            // Search bar
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.secondary)
                                TextField("Ders ara...", text: $searchText)
                                    .textFieldStyle(PlainTextFieldStyle())
                                if !searchText.isEmpty {
                                    Button(action: { searchText = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(12)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                            
                            // Category filter
                            if !categories.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        CategoryFilterButton(
                                            title: "Tümü",
                                            isSelected: selectedCategory == nil,
                                            action: { selectedCategory = nil }
                                        )
                                        
                                        ForEach(categories, id: \.self) { category in
                                            CategoryFilterButton(
                                                title: category,
                                                isSelected: selectedCategory == category,
                                                action: { selectedCategory = category }
                                            )
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical, 12)
                        .background(Color(.systemGroupedBackground))
                        
                        // Lessons List
                        if filteredLessons.isEmpty {
                            EmptyStateView(
                                icon: "magnifyingglass",
                                title: "Sonuç Bulunamadı",
                                message: "Arama kriterlerinize uygun ders bulunamadı."
                            )
                        } else {
                            ScrollView {
                                VStack(spacing: 16) {
                                    // Progress Card
                                    CleanProgressCard(viewModel: viewModel)
                                        .padding(.horizontal)
                                        .padding(.top)
                                    
                                    // Lessons List
                                    LazyVStack(spacing: 12) {
                                        ForEach(filteredLessons) { lesson in
                                            CleanLessonCard(
                                                lesson: lesson,
                                                isCompleted: viewModel.isLessonCompleted(lesson.id),
                                                quizResult: viewModel.getQuizResult(for: lesson.id),
                                                onTap: {
                                                    HapticFeedback.selection()
                                                    selectedLesson = lesson
                                                }
                                            )
                                            .padding(.horizontal)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                            .refreshable {
                                HapticFeedback.light()
                                viewModel.refreshUser()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Dersler")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct CategoryFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticFeedback.selection()
            action()
        }) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if isSelected {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        } else {
                            Capsule()
                                .fill(Color(.systemBackground))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                )
                .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

struct CleanProgressCard: View {
    @ObservedObject var viewModel: LearningViewModel
    @State private var animateProgress = false
    
    var completionPercentage: Int {
        viewModel.getCompletionPercentage()
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.primaryGradient)
                        
                        Text("Öğrenme İlerlemesi")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    
                    Text("\(viewModel.completedLessons.count) / \(viewModel.lessons.count) ders tamamlandı")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Completion Badge with gradient
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                    
                    VStack(spacing: 0) {
                        Text("\(completionPercentage)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.primaryGradient)
                        Text("%")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.primaryGradient)
                    }
                }
            }
            
            // Progress Bar with animation
            VStack(alignment: .leading, spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray5))
                            .frame(height: 12)
                        
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: animateProgress ? geometry.size.width * CGFloat(completionPercentage) / 100 : 0,
                                height: 12
                            )
                            .animation(.spring(response: 0.8, dampingFraction: 0.8), value: animateProgress)
                    }
                }
                .frame(height: 12)
            }
        }
        .padding(20)
        .modernCard()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                animateProgress = true
            }
        }
    }
}

struct CleanLessonCard: View {
    let lesson: Lesson
    let isCompleted: Bool
    let quizResult: Int?
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon with gradient
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            isCompleted ?
                            LinearGradient(
                                colors: [Color.green.opacity(0.2), Color.green.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: lesson.icon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(
                            isCompleted ?
                            LinearGradient(
                                colors: [Color.green, Color.green.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            Color.primaryGradient
                        )
                }
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(lesson.title)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.9)
                        
                        if isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 18))
                        }
                    }
                    
                    HStack(spacing: 8) {
                        Text(lesson.category)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue, Color.purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                        
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 10))
                            Text(lesson.duration)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Quiz Score or Arrow
                if let result = quizResult {
                    VStack(spacing: 2) {
                        Text("\(result)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                result >= 70 ?
                                LinearGradient(
                                    colors: [Color.green, Color.green.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [Color.orange, Color.orange.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text("%")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(result >= 70 ? .green : .orange)
                    }
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill((result >= 70 ? Color.green : Color.orange).opacity(0.15))
                    )
                } else {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.primaryGradient)
                }
            }
            .padding(18)
            .modernCard()
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct LessonDetailView: View {
    let lesson: Lesson
    @ObservedObject var viewModel: LearningViewModel
    let onComplete: () -> Void
    let onQuiz: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top, spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.15))
                                        .frame(width: 64, height: 64)
                                    
                                    Image(systemName: lesson.icon)
                                        .font(.system(size: 28, weight: .medium))
                                        .foregroundColor(.blue)
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(lesson.title)
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.primary)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.9)
                                    
                                    HStack(spacing: 8) {
                                        Text(lesson.category)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Color.blue)
                                            .cornerRadius(8)
                                        
                                        HStack(spacing: 4) {
                                            Image(systemName: "clock")
                                                .font(.system(size: 11))
                                            Text(lesson.duration)
                                                .font(.system(size: 13))
                                        }
                                        .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                        )
                        
                        // Content
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Ders İçeriği")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text(lesson.content)
                                .font(.system(size: 16))
                                .lineSpacing(6)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                        )
                        
                        // Action Button
                        Button(action: onQuiz) {
                            HStack(spacing: 10) {
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 18, weight: .medium))
                                Text("Quiz'i Başlat")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Geri")
                        }
                        .foregroundColor(.blue)
                        .font(.system(size: 16, weight: .medium))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        onComplete()
                        dismiss()
                    }) {
                        Text("Tamamla")
                            .foregroundColor(.green)
                            .font(.system(size: 16, weight: .medium))
                    }
                }
            }
        }
    }
}

#Preview {
    LearnView(viewModel: LearningViewModel())
}
