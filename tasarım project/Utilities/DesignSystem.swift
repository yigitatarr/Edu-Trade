//
//  DesignSystem.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import SwiftUI

// MARK: - Design System Colors
extension Color {
    static var appPrimary: Color {
        Color.blue
    }
    
    static var appSecondary: Color {
        Color.purple
    }
    
    static var appSuccess: Color {
        Color.green
    }
    
    static var appWarning: Color {
        Color.orange
    }
    
    static var appDanger: Color {
        Color.red
    }
    
    static var appBackground: Color {
        Color(.systemGroupedBackground)
    }
    
    static var appCardBackground: Color {
        Color(.systemBackground)
    }
    
    // Gradient Colors
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [Color.blue, Color.purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var successGradient: LinearGradient {
        LinearGradient(
            colors: [Color.green.opacity(0.8), Color.green],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var dangerGradient: LinearGradient {
        LinearGradient(
            colors: [Color.red.opacity(0.8), Color.red],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Design System Spacing
struct AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
}

// MARK: - Design System Corner Radius
struct AppCornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xlarge: CGFloat = 20
}

// MARK: - Design System Shadows
struct AppShadow {
    static let small = Shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    static let medium = Shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    static let large = Shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Modern Card Style
struct ModernCardStyle: ViewModifier {
    let cornerRadius: CGFloat
    let shadow: Shadow
    
    init(cornerRadius: CGFloat = AppCornerRadius.large, shadow: Shadow = AppShadow.medium) {
        self.cornerRadius = cornerRadius
        self.shadow = shadow
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.appCardBackground)
                    .shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
            )
    }
}

extension View {
    func modernCard(cornerRadius: CGFloat = AppCornerRadius.large, shadow: Shadow = AppShadow.medium) -> some View {
        modifier(ModernCardStyle(cornerRadius: cornerRadius, shadow: shadow))
    }
}

// MARK: - Glassmorphism Effect
struct GlassmorphismModifier: ViewModifier {
    let opacity: Double
    
    init(opacity: Double = 0.1) {
        self.opacity = opacity
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.large)
                    .fill(.ultraThinMaterial)
                    .opacity(opacity > 0 ? 1.0 : 0.0)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppCornerRadius.large)
                            .fill(Color.white.opacity(opacity))
                    )
            )
    }
}

extension View {
    func glassmorphism(opacity: Double = 0.1) -> some View {
        modifier(GlassmorphismModifier(opacity: opacity))
    }
}

// MARK: - Animated Gradient Background
struct AnimatedGradientBackground: View {
    @State private var animateGradient = false
    let colors: [Color]
    
    init(colors: [Color] = [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]) {
        self.colors = colors
    }
    
    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: animateGradient ? .topLeading : .bottomTrailing,
            endPoint: animateGradient ? .bottomTrailing : .topLeading
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}



