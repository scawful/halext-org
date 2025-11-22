//
//  ColorThemes.swift
//  Cafe
//
//  Additional vibrant color themes for the app
//

import SwiftUI

extension Theme {
    // MARK: - Vibrant Themes
    
    static let vibrant = Theme(
        id: "vibrant",
        name: "Vibrant",
        accentColor: CodableColor(Color(red: 0.4, green: 0.2, blue: 0.9)), // Deep Purple
        backgroundColor: CodableColor(Color(red: 0.98, green: 0.97, blue: 1.0)),
        secondaryBackgroundColor: CodableColor(Color(red: 0.95, green: 0.93, blue: 0.98)),
        textColor: CodableColor(Color(red: 0.15, green: 0.1, blue: 0.25)),
        secondaryTextColor: CodableColor(Color(red: 0.5, green: 0.4, blue: 0.6)),
        backgroundGradient: CodableGradient(
            startColor: CodableColor(Color(red: 0.98, green: 0.96, blue: 1.0)),
            endColor: CodableColor(Color(red: 0.95, green: 0.92, blue: 0.98)),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        isDark: false
    )
    
    static let electric = Theme(
        id: "electric",
        name: "Electric",
        accentColor: CodableColor(Color(red: 0.0, green: 0.8, blue: 1.0)), // Cyan
        backgroundColor: CodableColor(Color(red: 0.95, green: 0.98, blue: 1.0)),
        secondaryBackgroundColor: CodableColor(Color(red: 0.9, green: 0.95, blue: 0.98)),
        textColor: CodableColor(Color(red: 0.1, green: 0.2, blue: 0.3)),
        secondaryTextColor: CodableColor(Color(red: 0.4, green: 0.5, blue: 0.6)),
        backgroundGradient: CodableGradient(
            startColor: CodableColor(Color(red: 0.95, green: 0.98, blue: 1.0)),
            endColor: CodableColor(Color(red: 0.9, green: 0.95, blue: 0.98)),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        isDark: false
    )
    
    static let tropical = Theme(
        id: "tropical",
        name: "Tropical",
        accentColor: CodableColor(Color(red: 0.0, green: 0.9, blue: 0.5)), // Green
        backgroundColor: CodableColor(Color(red: 0.95, green: 1.0, blue: 0.98)),
        secondaryBackgroundColor: CodableColor(Color(red: 0.9, green: 0.98, blue: 0.95)),
        textColor: CodableColor(Color(red: 0.1, green: 0.25, blue: 0.2)),
        secondaryTextColor: CodableColor(Color(red: 0.3, green: 0.6, blue: 0.5)),
        backgroundGradient: CodableGradient(
            startColor: CodableColor(Color(red: 0.95, green: 1.0, blue: 0.98)),
            endColor: CodableColor(Color(red: 0.9, green: 0.98, blue: 0.95)),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        isDark: false
    )
    
    static let fire = Theme(
        id: "fire",
        name: "Fire",
        accentColor: CodableColor(Color(red: 1.0, green: 0.3, blue: 0.2)), // Red-Orange
        backgroundColor: CodableColor(Color(red: 1.0, green: 0.96, blue: 0.94)),
        secondaryBackgroundColor: CodableColor(Color(red: 0.98, green: 0.92, blue: 0.9)),
        textColor: CodableColor(Color(red: 0.3, green: 0.15, blue: 0.1)),
        secondaryTextColor: CodableColor(Color(red: 0.6, green: 0.4, blue: 0.3)),
        backgroundGradient: CodableGradient(
            startColor: CodableColor(Color(red: 1.0, green: 0.96, blue: 0.94)),
            endColor: CodableColor(Color(red: 0.98, green: 0.92, blue: 0.9)),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        isDark: false
    )
    
    // MARK: - Enhanced Dark Themes
    
    static let vibrantDark = Theme(
        id: "vibrantDark",
        name: "Vibrant Dark",
        accentColor: CodableColor(Color(red: 0.6, green: 0.4, blue: 1.0)), // Bright Purple
        backgroundColor: CodableColor(Color(red: 0.08, green: 0.06, blue: 0.12)),
        secondaryBackgroundColor: CodableColor(Color(red: 0.12, green: 0.1, blue: 0.18)),
        textColor: CodableColor(Color(red: 0.95, green: 0.93, blue: 1.0)),
        secondaryTextColor: CodableColor(Color(red: 0.7, green: 0.65, blue: 0.8)),
        backgroundGradient: CodableGradient(
            startColor: CodableColor(Color(red: 0.08, green: 0.06, blue: 0.12)),
            endColor: CodableColor(Color(red: 0.12, green: 0.1, blue: 0.18)),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        isDark: true
    )
    
    static let electricDark = Theme(
        id: "electricDark",
        name: "Electric Dark",
        accentColor: CodableColor(Color(red: 0.0, green: 0.9, blue: 1.0)), // Bright Cyan
        backgroundColor: CodableColor(Color(red: 0.06, green: 0.08, blue: 0.12)),
        secondaryBackgroundColor: CodableColor(Color(red: 0.1, green: 0.13, blue: 0.18)),
        textColor: CodableColor(Color(red: 0.9, green: 0.95, blue: 1.0)),
        secondaryTextColor: CodableColor(Color(red: 0.65, green: 0.75, blue: 0.85)),
        backgroundGradient: CodableGradient(
            startColor: CodableColor(Color(red: 0.06, green: 0.08, blue: 0.12)),
            endColor: CodableColor(Color(red: 0.1, green: 0.13, blue: 0.18)),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        isDark: true
    )
}

// MARK: - Theme Collection Extension

extension Theme {
    static let vibrantThemes: [Theme] = [
        .vibrant, .electric, .tropical, .fire,
        .vibrantDark, .electricDark
    ]
    
    static let allThemesIncludingVibrant: [Theme] = [
        .light, .ocean, .forest, .sunset, .pastel,
        .cherryBlossom, .sakura, .lavender, .mint, .coral, .autumn, .monochromeLight, .sunrise,
        .vibrant, .electric, .tropical, .fire,
        .dark, .midnight, .amoled, .neon, .aurora,
        .vibrantDark, .electricDark
    ]
}

