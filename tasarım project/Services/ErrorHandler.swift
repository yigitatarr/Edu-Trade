//
//  ErrorHandler.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation
import SwiftUI

class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()
    
    @Published var currentError: AppError?
    @Published var showError = false
    
    private init() {}
    
    func handle(_ error: AppError) {
        DispatchQueue.main.async {
            self.currentError = error
            self.showError = true
            
            // Log to crash reporting
            CrashReportingService.shared.logError(error, context: "App Error")
        }
    }
    
    func clear() {
        currentError = nil
        showError = false
    }
}

// MARK: - Error View Modifier
struct ErrorAlertModifier: ViewModifier {
    @ObservedObject var errorHandler: ErrorHandler
    
    func body(content: Content) -> some View {
        content
            .alert("Hata", isPresented: $errorHandler.showError) {
                Button("Tamam", role: .cancel) {
                    errorHandler.clear()
                }
            } message: {
                if let error = errorHandler.currentError {
                    Text(error.errorDescription ?? "Bilinmeyen hata")
                }
            }
    }
}

extension View {
    func errorAlert(errorHandler: ErrorHandler = .shared) -> some View {
        modifier(ErrorAlertModifier(errorHandler: errorHandler))
    }
}

