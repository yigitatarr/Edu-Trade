//
//  tasar_m_projectApp.swift
//  tasarım project
//
//  Created by Yiğit on 28.10.2025.
//

import SwiftUI

@main
struct EduTradeApp: App {
    @StateObject private var settingsVM = SettingsViewModel()
    @StateObject private var onboardingVM = OnboardingViewModel()
    @StateObject private var localizationHelper = LocalizationHelper.shared
    @State private var colorScheme: ColorScheme? = nil
    
    init() {
        // Setup crash reporting
        _ = CrashReportingService.shared
        
        // Request notification permission on app launch
        NotificationService.shared.requestAuthorization()
        
        // Start iCloud sync if enabled
        if CloudSyncService.shared.isAutoSyncEnabled {
            CloudSyncService.shared.startAutoSync()
        }
        
        // API key kullanıcı tarafından AI Asistan ekranından girilir
        // Kaynak koda hardcode edilmez (güvenlik)
    }
    
    var body: some Scene {
        WindowGroup {
            if onboardingVM.hasCompletedOnboarding {
                HomeView()
                    .tint(.appPrimary)
                    .preferredColorScheme(colorScheme)
                    .environmentObject(settingsVM)
                    .environmentObject(localizationHelper)
                    .onAppear {
                        // Update notification settings
                        NotificationService.shared.updateNotificationSettings(settings: settingsVM.settings)
                        // Initialize color scheme
                        updateColorScheme()
                        // Initialize language
                        localizationHelper.updateLanguage(settingsVM.settings.language)
                    }
                    .onChange(of: settingsVM.settings.theme) {
                        updateColorScheme()
                    }
                    .onChange(of: settingsVM.settings.language) { _, newLanguage in
                        localizationHelper.updateLanguage(newLanguage)
                    }
            } else {
                OnboardingView(viewModel: onboardingVM)
                    .environmentObject(localizationHelper)
            }
        }
    }
    
    private func updateColorScheme() {
        switch settingsVM.settings.theme {
        case .light:
            colorScheme = .light
        case .dark:
            colorScheme = .dark
        case .system:
            colorScheme = nil // System default
        }
    }
}
