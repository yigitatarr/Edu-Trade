//
//  QuizView.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import SwiftUI

struct QuizView: View {
    let quiz: Quiz
    @ObservedObject var viewModel: LearningViewModel
    let lessonId: String
    
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswer: Int? = nil
    @State private var isAnswered = false
    @State private var correctAnswers = 0
    @State private var showResults = false
    
    @Environment(\.dismiss) var dismiss
    
    private var currentQuestion: Quiz.QuizQuestion {
        quiz.questions[currentQuestionIndex]
    }
    
    private var score: Int {
        Int((Double(correctAnswers) / Double(quiz.questions.count)) * 100)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                        
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: geometry.size.width * CGFloat(currentQuestionIndex + 1) / CGFloat(quiz.questions.count))
                    }
                }
                .frame(height: 4)
                
                // Question Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Question Number
                        Text("Soru \(currentQuestionIndex + 1) / \(quiz.questions.count)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        // Question Text
                        Text(currentQuestion.question)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        // Options
                        VStack(spacing: 12) {
                            ForEach(Array(currentQuestion.options.enumerated()), id: \.offset) { index, option in
                                OptionButton(
                                    option: option,
                                    index: index,
                                    isSelected: selectedAnswer == index,
                                    isCorrect: index == currentQuestion.correctAnswerIndex,
                                    isAnswered: isAnswered,
                                    onTap: {
                                        if !isAnswered {
                                            selectedAnswer = index
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                
                // Navigation Buttons
                if isAnswered {
                    VStack(spacing: 0) {
                        Divider()
                        
                        Button(action: nextQuestion) {
                            Text(currentQuestionIndex == quiz.questions.count - 1 ? "Sonuçları Gör" : "Sonraki Soru")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                        }
                    }
                } else {
                    VStack(spacing: 0) {
                        Divider()
                        
                        Button(action: submitAnswer) {
                            Text("Cevabı Gönder")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedAnswer == nil ? Color.gray : Color.blue)
                                .foregroundColor(.white)
                        }
                        .disabled(selectedAnswer == nil)
                    }
                }
            }
            .navigationTitle("Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Reset quiz state when view appears
                currentQuestionIndex = 0
                selectedAnswer = nil
                isAnswered = false
                correctAnswers = 0
                showResults = false
            }
            .sheet(isPresented: $showResults) {
                QuizResultsView(
                    score: score,
                    totalQuestions: quiz.questions.count,
                    onDismiss: {
                        viewModel.submitQuizScore(lessonId: lessonId, score: score, totalQuestions: quiz.questions.count)
                        viewModel.completeLesson(lessonId)
                        dismiss()
                    }
                )
            }
        }
    }
    
    private func submitAnswer() {
        isAnswered = true
        
        if let selected = selectedAnswer, selected == currentQuestion.correctAnswerIndex {
            correctAnswers += 1
        }
    }
    
    private func nextQuestion() {
        if currentQuestionIndex < quiz.questions.count - 1 {
            currentQuestionIndex += 1
            selectedAnswer = nil
            isAnswered = false
        } else {
            showResults = true
        }
    }
}

struct OptionButton: View {
    let option: String
    let index: Int
    let isSelected: Bool
    let isCorrect: Bool
    let isAnswered: Bool
    let onTap: () -> Void
    
    private var backgroundColor: Color {
        if isAnswered {
            if isCorrect {
                return Color.green.opacity(0.2)
            } else if isSelected && !isCorrect {
                return Color.red.opacity(0.2)
            } else {
                return Color.gray.opacity(0.1)
            }
        } else {
            return isSelected ? Color.blue.opacity(0.2) : Color(.systemGray6)
        }
    }
    
    private var borderColor: Color {
        if isAnswered {
            if isCorrect {
                return Color.green
            } else if isSelected && !isCorrect {
                return Color.red
            } else {
                return Color.clear
            }
        } else {
            return isSelected ? Color.blue : Color.clear
        }
    }
    
    private var icon: String? {
        guard isAnswered else { return nil }
        if isCorrect {
            return "checkmark.circle.fill"
        } else if isSelected && !isCorrect {
            return "xmark.circle.fill"
        } else {
            return nil
        }
    }
    
    private var iconColor: Color {
        if isCorrect {
            return .green
        } else {
            return .red
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Letter indicator
                Text(String(Character(UnicodeScalar(65 + index)!))) // A, B, C, D
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 36)
                    .background(backgroundColor)
                    .cornerRadius(8)
                
                // Option text
                Text(option)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Icon
                if let iconName = icon {
                    Image(systemName: iconName)
                        .foregroundColor(iconColor)
                }
            }
            .padding()
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 2)
            )
            .cornerRadius(12)
        }
    }
}

struct QuizResultsView: View {
    let score: Int
    let totalQuestions: Int
    let onDismiss: () -> Void
    
    private var emoji: String {
        if score >= 80 {
            return "🎉"
        } else if score >= 60 {
            return "👍"
        } else {
            return "📚"
        }
    }
    
    private var title: String {
        if score >= 80 {
            return "Mükemmel!"
        } else if score >= 60 {
            return "İyi İş!"
        } else {
            return "Öğrenmeye Devam Et!"
        }
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Text(emoji)
                .font(.system(size: 80))
            
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                Text("Skorunuz")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("\(score)%")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundColor(scoreColor)
                
                Text("\(correctAnswers)/\(totalQuestions) soru doğru")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(scoreColor.opacity(0.1))
            )
            
            if score < 70 {
                VStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                    
                    Text("Daha iyi anlamak için dersi tekrar gözden geçirmeyi düşünün")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.1))
                )
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Text("Tamam")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var correctAnswers: Int {
        Int((score * totalQuestions) / 100)
    }
    
    private var scoreColor: Color {
        if score >= 80 {
            return .green
        } else if score >= 60 {
            return .orange
        } else {
            return .red
        }
    }
}

#Preview {
    QuizView(
        quiz: Quiz(id: "1", lessonId: "lesson_1", questions: []),
        viewModel: LearningViewModel(),
        lessonId: "lesson_1"
    )
}

