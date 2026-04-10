//
//  CrashReportingService.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation
import UIKit

class CrashReportingService {
    static let shared = CrashReportingService()
    
    private let crashLogsKey = "crashLogs"
    private let maxCrashLogs = 50
    
    private init() {
        setupCrashHandling()
    }
    
    // MARK: - Setup
    
    private func setupCrashHandling() {
        // Handle uncaught exceptions
        NSSetUncaughtExceptionHandler { exception in
            CrashReportingService.shared.logCrash(
                type: "Exception",
                message: exception.description,
                stackTrace: exception.callStackSymbols.joined(separator: "\n")
            )
        }
        
        // Handle signals (SIGABRT, SIGSEGV, etc.)
        signal(SIGABRT) { _ in
            CrashReportingService.shared.logCrash(
                type: "SIGABRT",
                message: "Application abort signal",
                stackTrace: Thread.callStackSymbols.joined(separator: "\n")
            )
        }
        
        signal(SIGSEGV) { _ in
            CrashReportingService.shared.logCrash(
                type: "SIGSEGV",
                message: "Segmentation fault",
                stackTrace: Thread.callStackSymbols.joined(separator: "\n")
            )
        }
        
        signal(SIGILL) { _ in
            CrashReportingService.shared.logCrash(
                type: "SIGILL",
                message: "Illegal instruction",
                stackTrace: Thread.callStackSymbols.joined(separator: "\n")
            )
        }
    }
    
    // MARK: - Crash Logging
    
    func logCrash(type: String, message: String, stackTrace: String) {
        let crashLog = CrashLog(
            id: UUID().uuidString,
            type: type,
            message: message,
            stackTrace: stackTrace,
            timestamp: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            osVersion: UIDevice.current.systemVersion,
            deviceModel: UIDevice.current.model
        )
        
        saveCrashLog(crashLog)
        
        // In production, you would send this to a crash reporting service
        // For now, we just log it locally
        print("🚨 CRASH DETECTED: \(type) - \(message)")
    }
    
    func logError(_ error: Error, context: String? = nil) {
        let errorLog = CrashLog(
            id: UUID().uuidString,
            type: "Error",
            message: context.map { "\($0): \(error.localizedDescription)" } ?? error.localizedDescription,
            stackTrace: Thread.callStackSymbols.joined(separator: "\n"),
            timestamp: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            osVersion: UIDevice.current.systemVersion,
            deviceModel: UIDevice.current.model
        )
        
        saveCrashLog(errorLog)
    }
    
    // MARK: - Storage
    
    private func saveCrashLog(_ log: CrashLog) {
        var logs = getCrashLogs()
        logs.insert(log, at: 0)
        
        // Keep only the most recent logs
        if logs.count > maxCrashLogs {
            logs = Array(logs.prefix(maxCrashLogs))
        }
        
        if let encoded = try? JSONEncoder().encode(logs) {
            UserDefaults.standard.set(encoded, forKey: crashLogsKey)
        }
    }
    
    func getCrashLogs() -> [CrashLog] {
        guard let data = UserDefaults.standard.data(forKey: crashLogsKey),
              let logs = try? JSONDecoder().decode([CrashLog].self, from: data) else {
            return []
        }
        return logs
    }
    
    func clearCrashLogs() {
        UserDefaults.standard.removeObject(forKey: crashLogsKey)
    }
    
    // MARK: - Export
    
    func exportCrashLogs() -> String {
        let logs = getCrashLogs()
        var report = "CRASH REPORT\n"
        report += "Generated: \(Date())\n"
        report += "App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")\n"
        report += "OS Version: \(UIDevice.current.systemVersion)\n"
        report += "Device: \(UIDevice.current.model)\n"
        report += "Total Crashes: \(logs.count)\n\n"
        report += "=" * 80 + "\n\n"
        
        for (index, log) in logs.enumerated() {
            report += "CRASH #\(index + 1)\n"
            report += "ID: \(log.id)\n"
            report += "Type: \(log.type)\n"
            report += "Message: \(log.message)\n"
            report += "Timestamp: \(log.timestamp)\n"
            report += "App Version: \(log.appVersion)\n"
            report += "OS Version: \(log.osVersion)\n"
            report += "Device: \(log.deviceModel)\n"
            report += "\nStack Trace:\n\(log.stackTrace)\n"
            report += "\n" + "=" * 80 + "\n\n"
        }
        
        return report
    }
}

struct CrashLog: Codable, Identifiable {
    let id: String
    let type: String
    let message: String
    let stackTrace: String
    let timestamp: Date
    let appVersion: String
    let osVersion: String
    let deviceModel: String
}

// Helper extension for string multiplication
extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}
