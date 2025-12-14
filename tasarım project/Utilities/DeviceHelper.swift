//
//  DeviceHelper.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import SwiftUI

struct DeviceHelper {
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    static var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    static var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }
    
    static var screenHeight: CGFloat {
        UIScreen.main.bounds.height
    }
    
    static var isLandscape: Bool {
        screenWidth > screenHeight
    }
    
    // Adaptive spacing for iPad
    static func adaptiveSpacing(_ base: CGFloat) -> CGFloat {
        isIPad ? base * 1.5 : base
    }
    
    // Adaptive padding for iPad
    static func adaptivePadding(_ base: CGFloat) -> CGFloat {
        isIPad ? base * 1.5 : base
    }
    
    // Adaptive font size for iPad
    static func adaptiveFontSize(_ base: CGFloat) -> CGFloat {
        isIPad ? base * 1.2 : base
    }
    
    // Column count for grid layouts
    static func adaptiveColumnCount(compact: Int, regular: Int) -> Int {
        isIPad ? regular : compact
    }
}

// View extension for responsive layouts
extension View {
    func adaptivePadding(_ base: CGFloat = 16) -> some View {
        self.padding(DeviceHelper.adaptivePadding(base))
    }
    
    func adaptiveSpacing(_ base: CGFloat = 16) -> some View {
        self.padding(.vertical, DeviceHelper.adaptiveSpacing(base))
    }
    
    // iPad-specific layout modifier
    func iPadLayout<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        Group {
            if DeviceHelper.isIPad {
                content()
            } else {
                self
            }
        }
    }
}



