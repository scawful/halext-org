//
//  SparkleAnimation.swift
//  Cafe
//
//  Sparkle animation effects for magical UI touches
//

import SwiftUI

struct SparkleAnimation: View {
    @State private var sparkles: [Sparkle] = []
    let count: Int
    let duration: Double
    
    init(count: Int = 10, duration: Double = 2.0) {
        self.count = count
        self.duration = duration
    }
    
    var body: some View {
        ZStack {
            ForEach(sparkles) { sparkle in
                Image(systemName: "sparkle")
                    .font(.caption)
                    .foregroundColor(.yellow)
                    .opacity(sparkle.opacity)
                    .offset(x: sparkle.x, y: sparkle.y)
                    .scaleEffect(sparkle.scale)
            }
        }
        .onAppear {
            generateSparkles()
            animateSparkles()
        }
    }
    
    private func generateSparkles() {
        sparkles = (0..<count).map { _ in
            Sparkle(
                id: UUID(),
                x: Double.random(in: -50...50),
                y: Double.random(in: -50...50),
                opacity: 1.0,
                scale: 0.5
            )
        }
    }
    
    private func animateSparkles() {
        withAnimation(.easeOut(duration: duration)) {
            for index in sparkles.indices {
                sparkles[index].opacity = 0
                sparkles[index].scale = 1.5
                sparkles[index].x += Double.random(in: -20...20)
                sparkles[index].y += Double.random(in: -20...20)
            }
        }
    }
}

struct Sparkle: Identifiable {
    let id: UUID
    var x: Double
    var y: Double
    var opacity: Double
    var scale: Double
}

// MARK: - Heart Animation

struct HeartAnimation: View {
    @State private var hearts: [Heart] = []
    let count: Int
    let duration: Double
    
    init(count: Int = 5, duration: Double = 1.5) {
        self.count = count
        self.duration = duration
    }
    
    var body: some View {
        ZStack {
            ForEach(hearts) { heart in
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundColor(.pink)
                    .opacity(heart.opacity)
                    .offset(x: heart.x, y: heart.y)
                    .scaleEffect(heart.scale)
            }
        }
        .onAppear {
            generateHearts()
            animateHearts()
        }
    }
    
    private func generateHearts() {
        hearts = (0..<count).map { _ in
            Heart(
                id: UUID(),
                x: Double.random(in: -30...30),
                y: Double.random(in: -30...30),
                opacity: 1.0,
                scale: 0.5
            )
        }
    }
    
    private func animateHearts() {
        withAnimation(.easeOut(duration: duration)) {
            for index in hearts.indices {
                hearts[index].opacity = 0
                hearts[index].scale = 1.2
                hearts[index].y -= 50
            }
        }
    }
}

struct Heart: Identifiable {
    let id: UUID
    var x: Double
    var y: Double
    var opacity: Double
    var scale: Double
}

// MARK: - Celebration Animation

struct CelebrationAnimation: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            if isAnimating {
                SparkleAnimation(count: 20, duration: 2.0)
                HeartAnimation(count: 10, duration: 2.0)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

