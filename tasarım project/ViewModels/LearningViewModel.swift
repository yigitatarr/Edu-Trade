//
//  LearningViewModel.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation

class LearningViewModel: ObservableObject {
    @Published var lessons: [Lesson] = []
    @Published var quizzes: [Quiz] = []
    @Published var completedLessons: Set<String> = []
    @Published var quizResults: [String: Int] = [:] // [lessonId: score]
    @Published var levels: [Level] = []
    @Published var challenges: [Challenge] = []
    @Published var currentUser: User?
    
    private let dataManager = DataManager.shared
    
    init() {
        loadData()
        loadUserProgress()
        refreshUser()
    }
    
    func reloadChallenges() {
        challenges = DataManager.shared.challenges
    }
    
    func refreshUser() {
        currentUser = dataManager.loadUser()
    }
    
    func loadData() {
        lessons = DataManager.shared.lessons
        quizzes = DataManager.shared.quizzes
        levels = DataManager.shared.levels
        challenges = DataManager.shared.challenges
    }
    
    func loadUserProgress() {
        let userDefaults = UserDefaults.standard
        if let completed = userDefaults.array(forKey: "completedLessons") as? [String] {
            completedLessons = Set(completed)
        }
        
        if let results = userDefaults.dictionary(forKey: "quizResults") as? [String: Int] {
            quizResults = results
        }
    }
    
    func completeLesson(_ lessonId: String) {
        completedLessons.insert(lessonId)
        addXP(10) // Ders okuma için 10 XP
        updateStreak()
        checkLevelUnlocks()
        checkLevelCompletions() // Seviye tamamlama kontrolü
        
        // Haptic feedback
        HapticFeedback.light()
        
        // Challenge kontrolü (lesson completion challenge'ları için)
        let user = dataManager.loadUser()
        checkAllChallenges(user: user)
        
        saveProgress()
    }
    
    func submitQuizScore(lessonId: String, score: Int, totalQuestions: Int) {
        guard totalQuestions > 0 else { return }
        let percentage = (score * 100) / totalQuestions
        quizResults[lessonId] = percentage
        
        // XP hesaplama
        addXP(20) // Quiz tamamlama için 20 XP
        if percentage == 100 {
            addXP(5) // Mükemmel skor bonusu +5 XP
        }
        
        updateStreak()
        checkLevelUnlocks()
        checkLevelCompletions() // Seviye tamamlama kontrolü
        
        // Challenge kontrolü (quiz completion challenge'ları için)
        let user = dataManager.loadUser()
        checkAllChallenges(user: user)
        
        saveProgress()
        checkScholarAchievement()
        checkMasterQuizzerAchievement()
        
        // Update leaderboard
        LeaderboardViewModel.shared.updateCurrentUserEntry()
    }
    
    func checkLevelCompletions() {
        var user = dataManager.loadUser()
        
        for level in levels {
            // Zaten tamamlanmışsa atla
            if user.progress.completedLevels.contains(level.id) {
                continue
            }
            
            // Seviye unlock edilmemişse atla
            if !user.progress.unlockedLevels.contains(level.id) {
                continue
            }
            
            // Seviyedeki tüm dersler tamamlanmış mı?
            let allLessonsCompleted = level.lessons.allSatisfy { lessonId in
                completedLessons.contains(lessonId)
            }
            
            // Seviyedeki tüm quiz'ler tamamlanmış mı? (en az %70 skor)
            let allQuizzesCompleted = level.lessons.allSatisfy { lessonId in
                if let score = quizResults[lessonId] {
                    return score >= 70 // En az %70 skor gerekli
                }
                return false
            }
            
            // Hem dersler hem quiz'ler tamamlanmışsa seviyeyi tamamla
            if allLessonsCompleted && allQuizzesCompleted {
                user.progress.completedLevels.append(level.id)
                
                // Seviye tamamlama bonusu
                addXP(50) // Seviye tamamlama bonusu
                
                // Sonraki seviyeyi unlock et
                if let nextLevel = levels.first(where: { $0.number == level.number + 1 }) {
                    if !user.progress.unlockedLevels.contains(nextLevel.id) {
                        user.progress.unlockedLevels.append(nextLevel.id)
                    }
                }
            }
        }
        
        dataManager.saveUser(user)
    }
    
    func addXP(_ amount: Int) {
        var user = dataManager.loadUser()
        user.progress.totalXP += amount
        user.progress.currentLevelXP += amount
        
        // Seviye atlama kontrolü
        let requiredXP = user.progress.currentLevel * 100
        if user.progress.currentLevelXP >= requiredXP {
            levelUp()
            // levelUp içinde user güncelleniyor, tekrar yükle
            user = dataManager.loadUser()
        }
        
        dataManager.saveUser(user)
        
        // UI güncellemesi
        DispatchQueue.main.async {
            self.currentUser = user
            self.objectWillChange.send()
        }
    }
    
    func levelUp() {
        var user = dataManager.loadUser()
        user.progress.currentLevel += 1
        user.progress.currentLevelXP = 0
        
        // Yeni seviyeyi unlock et
        if let newLevel = levels.first(where: { $0.number == user.progress.currentLevel }) {
            if !user.progress.unlockedLevels.contains(newLevel.id) {
                user.progress.unlockedLevels.append(newLevel.id)
            }
        }
        
        dataManager.saveUser(user)
        
        // Haptic feedback
        HapticFeedback.success()
        
        // Send level up notification if enabled
        if SettingsViewModel().settings.levelUpNotificationEnabled {
            NotificationService.shared.sendLevelUpNotification(level: user.progress.currentLevel)
        }
    }
    
    func updateStreak() {
        var user = dataManager.loadUser()
        let calendar = Calendar.current
        let today = Date()
        
        if let lastDate = user.progress.lastActivityDate {
            if calendar.isDateInToday(lastDate) {
                // Bugün zaten aktivite yapılmış, streak artırma
                return
            } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                      calendar.isDate(lastDate, inSameDayAs: yesterday) {
                // Dün aktivite yapılmış, streak artır
                user.progress.streak += 1
            } else {
                // Streak kırıldı
                user.progress.streak = 1
            }
        } else {
            // İlk aktivite
            user.progress.streak = 1
        }
        
        user.progress.lastActivityDate = today
        dataManager.saveUser(user)
    }
    
    func checkLevelUnlocks() {
        var user = dataManager.loadUser()
        
        for level in levels {
            // Zaten unlock edilmişse atla
            if user.progress.unlockedLevels.contains(level.id) {
                continue
            }
            
            // Unlock koşullarını kontrol et
            var shouldUnlock = false
            
            if let condition = level.unlockCondition {
                switch condition {
                case .previousLevelCompleted:
                    let previousLevelNumber = level.number - 1
                    if let previousLevel = levels.first(where: { $0.number == previousLevelNumber }) {
                        shouldUnlock = user.progress.completedLevels.contains(previousLevel.id)
                    }
                case .xpRequired(let requiredXP):
                    shouldUnlock = user.progress.totalXP >= requiredXP
                case .lessonsCompleted(let lessonIds):
                    shouldUnlock = lessonIds.allSatisfy { completedLessons.contains($0) }
                }
            } else {
                // Koşul yoksa, ilk seviye ise unlock et
                shouldUnlock = level.number == 1
            }
            
            if shouldUnlock {
                user.progress.unlockedLevels.append(level.id)
            }
        }
        
        dataManager.saveUser(user)
    }
    
    func isLevelUnlocked(_ levelId: String) -> Bool {
        let user = getCurrentUser()
        return user.progress.unlockedLevels.contains(levelId)
    }
    
    func isLevelCompleted(_ levelId: String) -> Bool {
        let user = getCurrentUser()
        return user.progress.completedLevels.contains(levelId)
    }
    
    func checkScholarAchievement() {
        guard completedLessons.count >= 5 else {
            return
        }
        
        var user = dataManager.loadUser()
        if !user.unlockedAchievements.contains("scholar") {
            user.unlockedAchievements.append("scholar")
            dataManager.saveUser(user)
        }
    }
    
    func checkMasterQuizzerAchievement() {
        // Check if all quiz results are 100%
        let allPerfect = quizResults.values.allSatisfy { $0 >= 100 }
        guard allPerfect && !quizResults.isEmpty else {
            return
        }
        
        var user = dataManager.loadUser()
        if !user.unlockedAchievements.contains("master_quizzer") {
            user.unlockedAchievements.append("master_quizzer")
            dataManager.saveUser(user)
        }
    }
    
    func getQuizResult(for lessonId: String) -> Int? {
        return quizResults[lessonId]
    }
    
    func isLessonCompleted(_ lessonId: String) -> Bool {
        return completedLessons.contains(lessonId)
    }
    
    private func saveProgress() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(Array(completedLessons), forKey: "completedLessons")
        userDefaults.set(quizResults, forKey: "quizResults")
        
        // Sync to iCloud if enabled
        if CloudSyncService.shared.isAutoSyncEnabled {
            CloudSyncService.shared.syncToCloud()
        }
    }
    
    func getCompletionPercentage() -> Int {
        guard !lessons.isEmpty else { return 0 }
        return Int((Double(completedLessons.count) / Double(lessons.count)) * 100)
    }
    
    func getCurrentUser() -> User {
        if let user = currentUser {
            return user
        }
        let user = dataManager.loadUser()
        currentUser = user
        return user
    }
    
    func getDailyChallenges() -> [Challenge] {
        return challenges.filter { $0.type == .daily }
    }
    
    func getWeeklyChallenges() -> [Challenge] {
        return challenges.filter { $0.type == .weekly }
    }
    
    func getPracticeChallenges() -> [Challenge] {
        return challenges.filter { $0.type == .practice }
    }
    
    // MARK: - Challenge Completion
    
    func checkChallengeCompletion(challengeId: String, user: User) -> Bool {
        guard let challenge = challenges.first(where: { $0.id == challengeId }) else {
            return false
        }
        
        let req = challenge.requirements
        
        // Trade count kontrolü
        if let requiredTrades = req.tradeCount {
            if user.numberOfTrades < requiredTrades {
                return false
            }
        }
        
        // Coin count kontrolü
        if let requiredCoins = req.coinCount {
            if user.portfolio.count < requiredCoins {
                return false
            }
        }
        
        // Lesson completion kontrolü
        if let lessonId = req.lessonId {
            if !completedLessons.contains(lessonId) {
                return false
            }
        }
        
        // Quiz score kontrolü
        if let requiredScore = req.quizScore {
            // Bu challenge için quiz sayısı kontrolü
            let completedQuizzes = quizResults.count
            if completedQuizzes < requiredScore {
                return false
            }
        }
        
        return true
    }
    
    func completeChallenge(_ challengeId: String, user: User) -> Bool {
        // Her zaman güncel user'ı yükle (trade sonrası değişiklikler için)
        var updatedUser = dataManager.loadUser()
        
        // Zaten tamamlanmışsa atla
        if updatedUser.progress.completedChallenges.contains(challengeId) {
            return false
        }
        
        guard let challenge = challenges.first(where: { $0.id == challengeId }) else {
            return false
        }
        
        // Challenge tamamlanmış mı kontrol et
        if checkChallengeCompletion(challengeId: challengeId, user: updatedUser) {
            updatedUser.progress.completedChallenges.append(challengeId)
            
            // XP ödülü ver - direkt user'a ekle
            updatedUser.progress.totalXP += challenge.xpReward
            updatedUser.progress.currentLevelXP += challenge.xpReward
            
            // Seviye atlama kontrolü
            let requiredXP = updatedUser.progress.currentLevel * 100
            if updatedUser.progress.currentLevelXP >= requiredXP {
                updatedUser.progress.currentLevel += 1
                updatedUser.progress.currentLevelXP = 0
                
                // Yeni seviyeyi unlock et
                if let newLevel = levels.first(where: { $0.number == updatedUser.progress.currentLevel }) {
                    if !updatedUser.progress.unlockedLevels.contains(newLevel.id) {
                        updatedUser.progress.unlockedLevels.append(newLevel.id)
                    }
                }
            }
            
            // Günlük/haftalık challenge ise tarih kaydet
            if challenge.type == .daily {
                updatedUser.progress.dailyChallenges[challengeId] = Date()
            } else if challenge.type == .weekly {
                updatedUser.progress.weeklyChallenges[challengeId] = Date()
            }
            
            // User'ı kaydet
            dataManager.saveUser(updatedUser)
            
            // UI güncellemesi için currentUser'ı güncelle
            DispatchQueue.main.async {
                self.currentUser = updatedUser
                self.objectWillChange.send()
            }
            
            return true
        }
        
        return false
    }
    
    func checkAllChallenges(user: User) {
        // Her zaman güncel user'ı yükle
        var updatedUser = dataManager.loadUser()
        var xpToAdd = 0
        var challengesCompleted: [String] = []
        
        for challenge in challenges {
            // Zaten tamamlanmışsa atla
            if updatedUser.progress.completedChallenges.contains(challenge.id) {
                continue
            }
            
            // Challenge tamamlanmış mı kontrol et
            if checkChallengeCompletion(challengeId: challenge.id, user: updatedUser) {
                challengesCompleted.append(challenge.id)
                xpToAdd += challenge.xpReward
                
                // Günlük/haftalık challenge ise tarih kaydet
                if challenge.type == .daily {
                    updatedUser.progress.dailyChallenges[challenge.id] = Date()
                } else if challenge.type == .weekly {
                    updatedUser.progress.weeklyChallenges[challenge.id] = Date()
                }
            }
        }
        
        // Eğer challenge tamamlandıysa
        if !challengesCompleted.isEmpty {
            // Challenge'ları tamamlanmış olarak işaretle
            updatedUser.progress.completedChallenges.append(contentsOf: challengesCompleted)
            
            // XP ödülü ver
            updatedUser.progress.totalXP += xpToAdd
            updatedUser.progress.currentLevelXP += xpToAdd
            
            // Seviye atlama kontrolü
            let requiredXP = updatedUser.progress.currentLevel * 100
            if updatedUser.progress.currentLevelXP >= requiredXP {
                updatedUser.progress.currentLevel += 1
                updatedUser.progress.currentLevelXP = 0
                
                // Yeni seviyeyi unlock et
                if let newLevel = levels.first(where: { $0.number == updatedUser.progress.currentLevel }) {
                    if !updatedUser.progress.unlockedLevels.contains(newLevel.id) {
                        updatedUser.progress.unlockedLevels.append(newLevel.id)
                    }
                }
            }
            
            // User'ı kaydet
            dataManager.saveUser(updatedUser)
            
            // UI güncellemesi için currentUser'ı güncelle
            DispatchQueue.main.async {
                self.currentUser = updatedUser
                self.objectWillChange.send()
            }
        }
    }
}

