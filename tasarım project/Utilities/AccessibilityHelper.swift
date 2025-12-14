//
//  AccessibilityHelper.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import SwiftUI

struct AccessibilityModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .accessibilityElement(children: .combine)
    }
}

extension View {
    func accessibilitySupport() -> some View {
        modifier(AccessibilityModifier())
    }
}

// MARK: - Accessible Button Style
struct AccessibleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - High Contrast Support
extension Color {
    static var accessibleBackground: Color {
        if UIAccessibility.isReduceTransparencyEnabled {
            return Color(.systemBackground)
        }
        return Color(.systemGroupedBackground)
    }
    
    static var accessibleForeground: Color {
        if UIAccessibility.isDarkerSystemColorsEnabled {
            return Color.primary
        }
        return Color.primary
    }
}



