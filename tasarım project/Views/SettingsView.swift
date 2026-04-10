//
//  SettingsView.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @ObservedObject var tradingVM: TradingViewModel
    @ObservedObject var learningVM: LearningViewModel
    @ObservedObject var cloudSync = CloudSyncService.shared
    @ObservedObject var localizationHelper = LocalizationHelper.shared
    @State private var showingResetAlert = false
    @State private var showingExportSheet = false
    @State private var showingProfileEdit = false
    @State private var exportData: String?
    @State private var restoreDelegate: RestoreDelegate?
    @State private var showExportError = false
    @State private var exportErrorMessage = ""
    @Environment(\.dismiss) var dismiss
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Export Functions
    
    private func exportTradesCSV() {
        let csv = ExportService.shared.exportTradesToCSV(tradingVM.trades)
        shareCSV(csv, fileName: "trades_\(Date().timeIntervalSince1970)")
    }
    
    private func exportPortfolioCSV() {
        let portfolio = tradingVM.user.portfolio
        let coins = DataManager.shared.coins
        let csv = ExportService.shared.exportPortfolioToCSV(portfolio, coins: coins)
        shareCSV(csv, fileName: "portfolio_\(Date().timeIntervalSince1970)")
    }
    
    private func exportTradesPDF() {
        if let pdfData = ExportService.shared.exportTradesToPDF(tradingVM.trades, user: tradingVM.user) {
            sharePDF(pdfData, fileName: "trades_\(Date().timeIntervalSince1970)")
        }
    }
    
    private func exportPortfolioPDF() {
        let portfolio = tradingVM.user.portfolio
        let coins = DataManager.shared.coins
        if let pdfData = ExportService.shared.exportPortfolioToPDF(portfolio, coins: coins, user: tradingVM.user) {
            sharePDF(pdfData, fileName: "portfolio_\(Date().timeIntervalSince1970)")
        }
    }
    
    private func shareCSV(_ csv: String, fileName: String) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).csv")
        
        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = rootViewController.view
                    popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX, y: rootViewController.view.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
                rootViewController.present(activityVC, animated: true)
            }
        } catch {
            exportErrorMessage = "CSV dışa aktarma hatası: \(error.localizedDescription)"
            showExportError = true
        }
    }
    
    private func sharePDF(_ pdfData: Data, fileName: String) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).pdf")
        
        do {
            try pdfData.write(to: tempURL)
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = rootViewController.view
                    popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX, y: rootViewController.view.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
                rootViewController.present(activityVC, animated: true)
            }
        } catch {
            exportErrorMessage = "PDF dışa aktarma hatası: \(error.localizedDescription)"
            showExportError = true
        }
    }
    
    var body: some View {
        List {
            // Profile Section
            Section {
                ProfileSettingsRow(
                    userName: viewModel.settings.userName,
                    userAvatar: viewModel.settings.userAvatar,
                    onEdit: {
                        showingProfileEdit = true
                    }
                    )
                } header: {
                    Text("Profil")
                }
                
                // Appearance Section
                Section {
                    ThemePickerRow(theme: $viewModel.settings.theme)
                } header: {
                    Text("Görünüm")
                } footer: {
                    Text("Uygulamanın görünüm temasını seçin")
                }
                
                // Language Section
                Section {
                    LanguagePickerRow(language: $viewModel.settings.language)
                } header: {
                    Text("Dil")
                }
                
                // Notifications Section
                Section {
                    Toggle("Bildirimler", isOn: $viewModel.settings.notificationsEnabled)
                        .onChange(of: viewModel.settings.notificationsEnabled) {
                            viewModel.saveSettings()
                            NotificationService.shared.updateNotificationSettings(settings: viewModel.settings)
                        }
                    
                    if viewModel.settings.notificationsEnabled {
                        Toggle("Günlük Hatırlatıcı", isOn: $viewModel.settings.dailyReminderEnabled)
                            .onChange(of: viewModel.settings.dailyReminderEnabled) {
                                viewModel.saveSettings()
                                NotificationService.shared.updateNotificationSettings(settings: viewModel.settings)
                            }
                        
                        Toggle("Seri Uyarısı", isOn: $viewModel.settings.streakReminderEnabled)
                            .onChange(of: viewModel.settings.streakReminderEnabled) {
                                viewModel.saveSettings()
                                NotificationService.shared.updateNotificationSettings(settings: viewModel.settings)
                            }
                        
                        Toggle("Başarım Bildirimleri", isOn: $viewModel.settings.achievementNotificationEnabled)
                            .onChange(of: viewModel.settings.achievementNotificationEnabled) {
                                viewModel.saveSettings()
                                NotificationService.shared.updateNotificationSettings(settings: viewModel.settings)
                            }
                        
                        Toggle("Seviye Açılma Bildirimleri", isOn: $viewModel.settings.levelUpNotificationEnabled)
                            .onChange(of: viewModel.settings.levelUpNotificationEnabled) {
                                viewModel.saveSettings()
                                NotificationService.shared.updateNotificationSettings(settings: viewModel.settings)
                            }
                        
                        Toggle("Fiyat Alarmları", isOn: $viewModel.settings.priceAlertEnabled)
                            .onChange(of: viewModel.settings.priceAlertEnabled) {
                                viewModel.saveSettings()
                                NotificationService.shared.updateNotificationSettings(settings: viewModel.settings)
                            }
                    }
                } header: {
                    Text("Bildirimler")
                } footer: {
                    Text("Bildirim tercihlerinizi yönetin")
                }
                
                // iCloud Sync Section
                Section {
                    Toggle("iCloud Yedekleme", isOn: Binding(
                        get: { CloudSyncService.shared.isAutoSyncEnabled },
                        set: { CloudSyncService.shared.enableAutoSync($0) }
                    ))
                    
                    if CloudSyncService.shared.isSyncing {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Senkronize ediliyor...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else if let lastSync = CloudSyncService.shared.lastSyncDate {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Son senkronizasyon: \(formatDate(lastSync))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        CloudSyncService.shared.syncToCloud()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Şimdi Yedekle")
                        }
                    }
                    
                    Button(action: {
                        CloudSyncService.shared.syncFromCloud()
                    }) {
                        HStack {
                            Image(systemName: "arrow.down.circle")
                            Text("iCloud'dan Geri Yükle")
                        }
                    }
                } header: {
                    Text("iCloud Yedekleme")
                } footer: {
                    Text("Verileriniz iCloud'da güvenli şekilde saklanır ve tüm cihazlarınızda senkronize edilir")
                }
                
                // Export Section
                Section {
                    Menu {
                        Button(action: {
                            exportTradesCSV()
                        }) {
                            Label("İşlemler (CSV)", systemImage: "doc.text")
                        }
                        
                        Button(action: {
                            exportPortfolioCSV()
                        }) {
                            Label("Portföy (CSV)", systemImage: "doc.text")
                        }
                        
                        Button(action: {
                            exportTradesPDF()
                        }) {
                            Label("İşlemler (PDF)", systemImage: "doc.fill")
                        }
                        
                        Button(action: {
                            exportPortfolioPDF()
                        }) {
                            Label("Portföy (PDF)", systemImage: "doc.fill")
                        }
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Raporları Dışa Aktar")
                        }
                    }
                    
                    Button(action: {
                        exportData = viewModel.exportData()
                        showingExportSheet = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up.on.square")
                            Text("Tüm Verileri Dışa Aktar (JSON)")
                        }
                    }
                } header: {
                    Text("Raporlar")
                } footer: {
                    Text("Trading verilerinizi CSV veya PDF formatında dışa aktarın")
                }
                
                // Data Management Section
                Section {
                    
                    Button(action: {
                        if let backupData = viewModel.createBackup() {
                            let activityVC = UIActivityViewController(activityItems: [backupData], applicationActivities: nil)
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let rootViewController = windowScene.windows.first?.rootViewController {
                                rootViewController.present(activityVC, animated: true)
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "icloud.and.arrow.up")
                            Text("Yedek Oluştur")
                        }
                    }
                    
                    Button(action: {
                        // Show document picker for restore
                        let delegate = RestoreDelegate(viewModel: viewModel)
                        restoreDelegate = delegate
                        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.json, .data])
                        documentPicker.delegate = delegate
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let rootViewController = windowScene.windows.first?.rootViewController {
                            rootViewController.present(documentPicker, animated: true)
                        }
                    }) {
                        HStack {
                            Image(systemName: "icloud.and.arrow.down")
                            Text("Yedekten Geri Yükle")
                        }
                    }
                    
                    Button(role: .destructive, action: {
                        showingResetAlert = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Tüm Verileri Sıfırla")
                        }
                    }
                } header: {
                    Text("Veri Yönetimi")
                } footer: {
                    Text("Verilerinizi yedekleyin, geri yükleyin veya sıfırlayın")
                }
                
                // Crash Reports Section
                Section {
                    let crashLogs = CrashReportingService.shared.getCrashLogs()
                    
                    if crashLogs.isEmpty {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Crash log yok")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("\(crashLogs.count) crash log bulundu")
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            exportData = CrashReportingService.shared.exportCrashLogs()
                            showingExportSheet = true
                        }) {
                            HStack {
                                Image(systemName: "doc.text")
                                Text("Crash Log'ları Dışa Aktar")
                            }
                        }
                        
                        Button(role: .destructive, action: {
                            CrashReportingService.shared.clearCrashLogs()
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Crash Log'ları Temizle")
                            }
                        }
                    }
                } header: {
                    Text("Crash Raporları")
                } footer: {
                    Text("Uygulama hataları otomatik olarak kaydedilir")
                }
                
                // About Section
                Section {
                    HStack {
                        Text("Versiyon")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Gizlilik Politikası")
                        Spacer()
                        Text("Yakında")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Kullanım Koşulları")
                        Spacer()
                        Text("Yakında")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Hakkında")
                }
        }
        .navigationTitle(LocalizationHelper.shared.string(for: "profile.settings"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Tamam") {
                    viewModel.saveSettings()
                    dismiss()
                }
            }
        }
        .alert("Tüm Verileri Sıfırla", isPresented: $showingResetAlert) {
            Button("İptal", role: .cancel) {}
            Button("Sıfırla", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("Tüm verilerinizi sıfırlamak istediğinizden emin misiniz? Bu işlem geri alınamaz.")
        }
        .alert("Dışa Aktarma Hatası", isPresented: $showExportError) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(exportErrorMessage)
        }
        .sheet(isPresented: $showingExportSheet) {
            if let exportData = exportData {
                ExportDataView(data: exportData)
            }
        }
        .sheet(isPresented: $showingProfileEdit) {
            ProfileEditView(viewModel: viewModel)
        }
        .onChange(of: viewModel.settings.theme) {
            viewModel.saveSettings()
            // Trigger app-wide theme update via notification
            NotificationCenter.default.post(name: NSNotification.Name("ThemeChanged"), object: nil)
        }
        .onChange(of: viewModel.settings.language) { _, newLanguage in
            viewModel.saveSettings()
            localizationHelper.updateLanguage(newLanguage)
            // Trigger app-wide language update via notification
            NotificationCenter.default.post(name: NSNotification.Name("LanguageChanged"), object: nil)
        }
        .onChange(of: viewModel.settings.notificationsEnabled) {
            viewModel.saveSettings()
            NotificationService.shared.updateNotificationSettings(settings: viewModel.settings)
        }
        .onChange(of: viewModel.settings.dailyReminderEnabled) {
            viewModel.saveSettings()
            NotificationService.shared.updateNotificationSettings(settings: viewModel.settings)
        }
        .onChange(of: viewModel.settings.streakReminderEnabled) {
            viewModel.saveSettings()
            NotificationService.shared.updateNotificationSettings(settings: viewModel.settings)
        }
    }
    
    private func resetAllData() {
        // Reset user data
        let user = User()
        tradingVM.user = user
        DataManager.shared.saveUser(user)
        DataManager.shared.saveTrades([])
        
        // Reset learning progress
        learningVM.completedLessons = []
        learningVM.quizResults = [:]
        let userDefaults = UserDefaults.standard
        userDefaults.set([], forKey: "completedLessons")
        userDefaults.set([:], forKey: "quizResults")
        
        // Reset trades
        tradingVM.trades = []
        
        // Reset settings
        viewModel.resetSettings()
    }
}

// MARK: - Settings Rows

struct ProfileSettingsRow: View {
    let userName: String
    let userAvatar: String
    let onEdit: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: userAvatar)
                .font(.system(size: 40))
                .foregroundColor(.blue)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(userName)
                    .font(.system(size: 18, weight: .semibold))
                
                Text("Profil Düzenle")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit()
        }
    }
}

struct ThemePickerRow: View {
    @Binding var theme: AppTheme
    
    var body: some View {
        Picker("Tema", selection: $theme) {
            ForEach(AppTheme.allCases, id: \.self) { themeOption in
                Text(themeOption.displayName).tag(themeOption)
            }
        }
        .onChange(of: theme) {
            // Save immediately when theme changes
            NotificationCenter.default.post(name: NSNotification.Name("ThemeChanged"), object: nil)
        }
    }
}

struct LanguagePickerRow: View {
    @Binding var language: AppLanguage
    @ObservedObject var localizationHelper = LocalizationHelper.shared
    
    var body: some View {
        Picker("Dil", selection: $language) {
            ForEach(AppLanguage.allCases, id: \.self) { languageOption in
                Text(languageOption.displayName).tag(languageOption)
            }
        }
        .onChange(of: language) { _, newLanguage in
            localizationHelper.updateLanguage(newLanguage)
            // Trigger app-wide language update
            NotificationCenter.default.post(name: NSNotification.Name("LanguageChanged"), object: nil)
        }
    }
}

struct ExportDataView: View {
    let data: String
    @Environment(\.dismiss) var dismiss
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Verilerinizi kopyalayın veya paylaşın")
                        .font(.headline)
                        .padding()
                    
                    Text(data)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    
                    Button(action: {
                        UIPasteboard.general.string = data
                    }) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Panoya Kopyala")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    Button(action: {
                        showingShareSheet = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Paylaş")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("Veri Dışa Aktarma")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(activityItems: [data])
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Profile Edit View
struct ProfileEditView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var userName: String = ""
    @State private var selectedAvatar: String = "person.circle.fill"
    @Environment(\.dismiss) var dismiss
    
    private let avatarOptions = [
        "person.circle.fill",
        "person.crop.circle.fill",
        "face.smiling.inverse",
        "star.circle.fill",
        "bitcoinsign.circle.fill",
        "chart.line.uptrend.xyaxis.circle.fill",
        "shield.checkered",
        "graduationcap.circle.fill",
        "flame.circle.fill",
        "bolt.circle.fill"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Kullanıcı Adı") {
                    TextField("Kullanıcı adınız", text: $userName)
                        .textFieldStyle(.plain)
                }
                
                Section("Avatar") {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(avatarOptions, id: \.self) { avatar in
                            Button(action: {
                                selectedAvatar = avatar
                                HapticFeedback.selection()
                            }) {
                                Image(systemName: avatar)
                                    .font(.system(size: 32))
                                    .foregroundColor(selectedAvatar == avatar ? .white : .blue)
                                    .frame(width: 56, height: 56)
                                    .background(
                                        Circle()
                                            .fill(selectedAvatar == avatar ? Color.blue : Color.blue.opacity(0.1))
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Profil Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        viewModel.settings.userName = userName.isEmpty ? "Trader" : userName
                        viewModel.settings.userAvatar = selectedAvatar
                        viewModel.saveSettings()
                        HapticFeedback.success()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                userName = viewModel.settings.userName
                selectedAvatar = viewModel.settings.userAvatar
            }
        }
    }
}

