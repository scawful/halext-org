//
//  MagicalThemeManager.swift
//  Cafe
//
//  Special theme manager for couple mode with magical touches
//

import SwiftUI

@Observable
class MagicalThemeManager {
    static let shared = MagicalThemeManager()
    
    var isCoupleModeEnabled = false
    var sparkleEnabled = true
    var heartAnimationsEnabled = true
    
    private init() {
        // Load preferences
        isCoupleModeEnabled = UserDefaults.standard.bool(forKey: "magicalCoupleMode")
        sparkleEnabled = UserDefaults.standard.bool(forKey: "magicalSparkles", defaultValue: true)
        heartAnimationsEnabled = UserDefaults.standard.bool(forKey: "magicalHearts", defaultValue: true)
    }
    
    func enableCoupleMode() {
        isCoupleModeEnabled = true
        UserDefaults.standard.set(true, forKey: "magicalCoupleMode")
    }
    
    func disableCoupleMode() {
        isCoupleModeEnabled = false
        UserDefaults.standard.set(false, forKey: "magicalCoupleMode")
    }
    
    var coupleGradient: LinearGradient {
        LinearGradient(
            colors: [.pink, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension UserDefaults {
    func bool(forKey key: String, defaultValue: Bool) -> Bool {
        if object(forKey: key) == nil {
            return defaultValue
        }
        return bool(forKey: key)
    }
}

