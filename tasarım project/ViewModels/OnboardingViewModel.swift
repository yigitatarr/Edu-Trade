//
//  OnboardingViewModel.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation

class OnboardingViewModel: ObservableObject {
    @Published var currentPage = 0
    @Published var hasCompletedOnboarding = false
    
    private let userDefaults = UserDefaults.standard
    private let onboardingKey = "hasCompletedOnboarding"
    
    init() {
        hasCompletedOnboarding = userDefaults.bool(forKey: onboardingKey)
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        userDefaults.set(true, forKey: onboardingKey)
    }
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
        currentPage = 0
        userDefaults.set(false, forKey: onboardingKey)
    }
}


