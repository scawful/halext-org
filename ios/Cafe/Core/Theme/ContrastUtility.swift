//
//  ContrastUtility.swift
//  Cafe
//
//  Utility for ensuring WCAG contrast ratios for accessibility
//

import SwiftUI

struct ContrastUtility {
    /// Calculate relative luminance of a color (0.0 to 1.0)
    static func relativeLuminance(_ color: Color) -> Double {
        #if canImport(UIKit)
        let uiColor = UIColor(color)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        // Convert to linear RGB
        let rLinear = r <= 0.03928 ? r / 12.92 : pow((r + 0.055) / 1.055, 2.4)
        let gLinear = g <= 0.03928 ? g / 12.92 : pow((g + 0.055) / 1.055, 2.4)
        let bLinear = b <= 0.03928 ? b / 12.92 : pow((b + 0.055) / 1.055, 2.4)
        
        return 0.2126 * Double(rLinear) + 0.7152 * Double(gLinear) + 0.0722 * Double(bLinear)
        #else
        return 0.5 // Fallback
        #endif
    }
    
    /// Calculate contrast ratio between two colors
    static func contrastRatio(_ color1: Color, _ color2: Color) -> Double {
        let l1 = relativeLuminance(color1)
        let l2 = relativeLuminance(color2)
        
        let lighter = max(l1, l2)
        let darker = min(l1, l2)
        
        return (lighter + 0.05) / (darker + 0.05)
    }
    
    /// Check if contrast meets WCAG AA standard (4.5:1 for normal text, 3:1 for large text)
    static func meetsWCAGAA(foreground: Color, background: Color, isLargeText: Bool = false) -> Bool {
        let ratio = contrastRatio(foreground, background)
        return ratio >= (isLargeText ? 3.0 : 4.5)
    }
    
    /// Check if contrast meets WCAG AAA standard (7:1 for normal text, 4.5:1 for large text)
    static func meetsWCAGAAA(foreground: Color, background: Color, isLargeText: Bool = false) -> Bool {
        let ratio = contrastRatio(foreground, background)
        return ratio >= (isLargeText ? 4.5 : 7.0)
    }
    
    /// Adjust color to meet minimum contrast ratio
    static func adjustForContrast(foreground: Color, background: Color, minimumRatio: Double = 4.5) -> Color {
        let currentRatio = contrastRatio(foreground, background)
        
        if currentRatio >= minimumRatio {
            return foreground
        }
        
        // Darken or lighten foreground to meet contrast
        #if canImport(UIKit)
        let uiColor = UIColor(foreground)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let bgLuminance = relativeLuminance(background)
        let targetLuminance = bgLuminance > 0.5 ? 0.0 : 1.0 // Darken if background is light, lighten if dark
        
        // Simple adjustment - in production, use more sophisticated algorithm
        let adjustment = (minimumRatio - currentRatio) / 10.0
        let newR = max(0, min(1, r + (targetLuminance > 0.5 ? -adjustment : adjustment)))
        let newG = max(0, min(1, g + (targetLuminance > 0.5 ? -adjustment : adjustment)))
        let newB = max(0, min(1, b + (targetLuminance > 0.5 ? -adjustment : adjustment)))
        
        return Color(red: Double(newR), green: Double(newG), blue: Double(newB), opacity: Double(a))
        #else
        return foreground
        #endif
    }
}

// MARK: - Theme Extension for Contrast

extension Theme {
    /// Get text color that meets contrast requirements
    func textColorForBackground(_ background: Color, isLargeText: Bool = false) -> Color {
        let text = Color(self.textColor)
        if ContrastUtility.meetsWCAGAA(foreground: text, background: background, isLargeText: isLargeText) {
            return text
        }
        return ContrastUtility.adjustForContrast(foreground: text, background: background)
    }
    
    /// Get secondary text color that meets contrast requirements
    func secondaryTextColorForBackground(_ background: Color, isLargeText: Bool = false) -> Color {
        let text = Color(self.secondaryTextColor)
        if ContrastUtility.meetsWCAGAA(foreground: text, background: background, isLargeText: isLargeText) {
            return text
        }
        return ContrastUtility.adjustForContrast(foreground: text, background: background)
    }
}

