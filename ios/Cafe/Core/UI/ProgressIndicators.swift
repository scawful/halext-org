//
//  ProgressIndicators.swift
//  Cafe
//
//  Reusable progress indicators for task completion
//

import SwiftUI

// MARK: - Progress Bar

struct ProgressBar: View {
    let completed: Int
    let total: Int
    var height: CGFloat = 8
    var cornerRadius: CGFloat = 4
    var backgroundColor: Color = .secondary.opacity(0.2)
    var foregroundColor: Color = .blue
    var showPercentage: Bool = true
    var animate: Bool = true

    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    var percentageText: String {
        let percentage = Int(progress * 100)
        return "\(percentage)%"
    }

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(backgroundColor)

                    // Progress fill
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(foregroundColor)
                        .frame(width: geometry.size.width * progress)
                        .animation(animate ? .easeInOut(duration: 0.3) : nil, value: progress)
                }
            }
            .frame(height: height)

            if showPercentage {
                HStack {
                    Text("\(completed) of \(total) completed")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(percentageText)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(foregroundColor)
                }
            }
        }
    }
}

// MARK: - Progress Wheel (Circular)

struct ProgressWheel: View {
    let completed: Int
    let total: Int
    var size: CGFloat = 100
    var lineWidth: CGFloat = 12
    var backgroundColor: Color = .secondary.opacity(0.2)
    var foregroundColor: Color = .blue
    var showPercentage: Bool = true
    var showCount: Bool = false
    var animate: Bool = true

    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    var percentageText: String {
        let percentage = Int(progress * 100)
        return "\(percentage)%"
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)

            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    foregroundColor,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(animate ? .easeInOut(duration: 0.3) : nil, value: progress)

            // Center content
            VStack(spacing: 4) {
                if showPercentage {
                    Text(percentageText)
                        .font(.system(size: size * 0.25, weight: .bold))
                        .foregroundColor(.primary)
                }

                if showCount {
                    Text("\(completed)/\(total)")
                        .font(.system(size: size * 0.15))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Mini Progress Wheel (for list rows)

struct MiniProgressWheel: View {
    let completed: Int
    let total: Int
    var size: CGFloat = 32
    var lineWidth: CGFloat = 3
    var foregroundColor: Color = .blue

    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    foregroundColor,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)

            Text("\(completed)")
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(foregroundColor)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Segmented Progress Bar (for multiple categories)

struct SegmentedProgressBar: View {
    let segments: [ProgressSegment]
    var height: CGFloat = 8
    var cornerRadius: CGFloat = 4
    var spacing: CGFloat = 2
    var animate: Bool = true

    var total: Int {
        segments.reduce(0) { $0 + $1.count }
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: spacing) {
                ForEach(segments) { segment in
                    let segmentWidth = total > 0 ? (CGFloat(segment.count) / CGFloat(total)) * geometry.size.width : 0

                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(segment.color)
                        .frame(width: segmentWidth)
                        .animation(animate ? .easeInOut(duration: 0.3) : nil, value: segmentWidth)
                }
            }
        }
        .frame(height: height)
    }
}

struct ProgressSegment: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
    let color: Color
}

// MARK: - Preview

#Preview("Progress Bar") {
    VStack(spacing: 32) {
        ProgressBar(completed: 7, total: 10)
            .padding()

        ProgressBar(completed: 3, total: 10, foregroundColor: .green)
            .padding()

        ProgressBar(completed: 10, total: 10, foregroundColor: .purple)
            .padding()
    }
}

#Preview("Progress Wheel") {
    HStack(spacing: 32) {
        ProgressWheel(completed: 7, total: 10)

        ProgressWheel(completed: 3, total: 10, foregroundColor: .green, showCount: true)

        ProgressWheel(completed: 10, total: 10, size: 80, foregroundColor: .purple)
    }
    .padding()
}

#Preview("Mini Progress Wheel") {
    HStack(spacing: 16) {
        MiniProgressWheel(completed: 7, total: 10)
        MiniProgressWheel(completed: 3, total: 10, foregroundColor: .green)
        MiniProgressWheel(completed: 10, total: 10, foregroundColor: .purple)
    }
    .padding()
}

#Preview("Segmented Progress Bar") {
    VStack(spacing: 32) {
        SegmentedProgressBar(segments: [
            ProgressSegment(name: "Completed", count: 7, color: .green),
            ProgressSegment(name: "In Progress", count: 2, color: .blue),
            ProgressSegment(name: "Not Started", count: 1, color: .gray)
        ])
        .padding()

        SegmentedProgressBar(segments: [
            ProgressSegment(name: "High", count: 3, color: .red),
            ProgressSegment(name: "Medium", count: 5, color: .orange),
            ProgressSegment(name: "Low", count: 2, color: .green)
        ])
        .padding()
    }
}
