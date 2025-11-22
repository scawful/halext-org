//
//  DashboardAnimations.swift
//  Cafe
//
//  Reusable animation components and view modifiers for dashboard polish
//

import SwiftUI

// MARK: - Staggered Entrance Animation Modifier

/// Applies a staggered entrance animation with offset and opacity
struct StaggeredEntranceModifier: ViewModifier {
    let index: Int
    let isVisible: Bool
    let baseDelay: Double
    let staggerDelay: Double

    @State private var hasAppeared = false

    init(index: Int, isVisible: Bool = true, baseDelay: Double = 0.1, staggerDelay: Double = 0.05) {
        self.index = index
        self.isVisible = isVisible
        self.baseDelay = baseDelay
        self.staggerDelay = staggerDelay
    }

    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 20)
            .scaleEffect(hasAppeared ? 1 : 0.95)
            .onAppear {
                guard isVisible else { return }
                let delay = baseDelay + (Double(index) * staggerDelay)
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay)) {
                    hasAppeared = true
                }
            }
    }
}

extension View {
    /// Applies staggered entrance animation based on index
    func staggeredEntrance(index: Int, baseDelay: Double = 0.1, staggerDelay: Double = 0.05) -> some View {
        modifier(StaggeredEntranceModifier(index: index, baseDelay: baseDelay, staggerDelay: staggerDelay))
    }
}

// MARK: - Card Press Animation Modifier

/// Adds a subtle scale animation on press for cards and buttons
struct CardPressAnimationModifier: ViewModifier {
    @State private var isPressed = false
    let enableHaptic: Bool
    let scale: CGFloat

    init(enableHaptic: Bool = true, scale: CGFloat = 0.97) {
        self.enableHaptic = enableHaptic
        self.scale = scale
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            if enableHaptic {
                                HapticManager.lightImpact()
                            }
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
    }
}

extension View {
    /// Adds press animation with optional haptic feedback
    func cardPressAnimation(enableHaptic: Bool = true, scale: CGFloat = 0.97) -> some View {
        modifier(CardPressAnimationModifier(enableHaptic: enableHaptic, scale: scale))
    }
}

// MARK: - Shimmer Loading Effect

/// A shimmer loading effect for skeleton views
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    let duration: Double
    let delay: Double

    init(duration: Double = 1.5, delay: Double = 0) {
        self.duration = duration
        self.delay = delay
    }

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0),
                            .init(color: Color.white.opacity(0.4), location: 0.4),
                            .init(color: Color.white.opacity(0.6), location: 0.5),
                            .init(color: Color.white.opacity(0.4), location: 0.6),
                            .init(color: .clear, location: 1)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (phase * geometry.size.width * 2))
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(
                    .linear(duration: duration)
                    .delay(delay)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

extension View {
    /// Applies shimmer loading effect
    func shimmer(duration: Double = 1.5, delay: Double = 0) -> some View {
        modifier(ShimmerModifier(duration: duration, delay: delay))
    }
}

// MARK: - Skeleton View Components

/// A skeleton placeholder for loading states
struct SkeletonView: View {
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat

    init(width: CGFloat? = nil, height: CGFloat = 16, cornerRadius: CGFloat = 4) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color(.systemGray5))
            .frame(width: width, height: height)
            .shimmer()
    }
}

/// A skeleton card for dashboard loading states
struct SkeletonCard: View {
    let height: CGFloat

    init(height: CGFloat = 120) {
        self.height = height
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SkeletonView(width: 24, height: 24, cornerRadius: 4)
                SkeletonView(width: 120, height: 16)
                Spacer()
            }

            SkeletonView(height: 14)
            SkeletonView(width: UIScreen.main.bounds.width * 0.6, height: 14)
        }
        .padding()
        .frame(height: height)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
    }
}

/// Skeleton loading view for the entire dashboard
struct DashboardSkeletonView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Welcome header skeleton
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    SkeletonView(width: 150, height: 24, cornerRadius: 4)
                    SkeletonView(width: 200, height: 16, cornerRadius: 4)
                }
                Spacer()
                SkeletonView(width: 44, height: 44, cornerRadius: 22)
            }
            .padding(.horizontal)

            // Stats cards skeleton
            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(spacing: 8) {
                        SkeletonView(width: 24, height: 24, cornerRadius: 4)
                        SkeletonView(width: 30, height: 28, cornerRadius: 4)
                        SkeletonView(width: 60, height: 12, cornerRadius: 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                    )
                }
            }
            .padding(.horizontal)

            // Card skeletons
            ForEach(0..<3, id: \.self) { index in
                SkeletonCard(height: index == 0 ? 160 : 120)
                    .padding(.horizontal)
                    .staggeredEntrance(index: index, baseDelay: 0.05, staggerDelay: 0.1)
            }
        }
    }
}

// MARK: - Enhanced Empty State

/// Enhanced empty state view with customizable illustration and animation
struct DashboardEmptyState: View {
    @Environment(ThemeManager.self) var themeManager

    let icon: String
    let title: String
    let message: String
    let suggestion: String?
    let actionTitle: String?
    let action: (() -> Void)?
    let accentColor: Color

    @State private var animateIcon = false
    @State private var showContent = false

    init(
        icon: String,
        title: String,
        message: String,
        suggestion: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil,
        accentColor: Color = .blue
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.suggestion = suggestion
        self.actionTitle = actionTitle
        self.action = action
        self.accentColor = accentColor
    }

    var body: some View {
        VStack(spacing: 16) {
            // Animated icon with background
            ZStack {
                // Outer ring
                Circle()
                    .stroke(accentColor.opacity(0.1), lineWidth: 2)
                    .frame(width: 80, height: 80)
                    .scaleEffect(animateIcon ? 1.2 : 1.0)
                    .opacity(animateIcon ? 0 : 0.5)

                // Inner filled circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [accentColor.opacity(0.15), accentColor.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)

                // Icon
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .opacity(showContent ? 1 : 0)
            .scaleEffect(showContent ? 1 : 0.8)
            .accessibilityHidden(true)

            // Text content
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                if let suggestion = suggestion {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)

                        Text(suggestion)
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    .padding(.top, 4)
                }
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 10)

            // Action button
            if let actionTitle = actionTitle, let action = action {
                Button {
                    HapticManager.selection()
                    action()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.subheadline)
                        Text(actionTitle)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [accentColor, accentColor.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .shadow(color: accentColor.opacity(0.3), radius: 6, y: 3)
                }
                .cardPressAnimation()
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.9)
                .accessibilityLabel(actionTitle)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .onAppear {
            // Start entrance animation
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                showContent = true
            }

            // Start pulsing animation for outer ring
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false)) {
                animateIcon = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }
}

// MARK: - Bounce Animation Modifier

/// Adds a subtle bounce animation on value change
struct BounceAnimationModifier<T: Equatable>: ViewModifier {
    let trigger: T
    @State private var scale: CGFloat = 1.0

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onChange(of: trigger) { _, _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    scale = 1.15
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        scale = 1.0
                    }
                }
            }
    }
}

extension View {
    /// Adds bounce animation when value changes
    func bounceOnChange<T: Equatable>(of value: T) -> some View {
        modifier(BounceAnimationModifier(trigger: value))
    }
}

// MARK: - Pulse Animation

/// A pulsing animation for attention-grabbing elements
struct PulseAnimationModifier: ViewModifier {
    @State private var isPulsing = false
    let color: Color
    let duration: Double

    init(color: Color = .blue, duration: Double = 1.5) {
        self.color = color
        self.duration = duration
    }

    func body(content: Content) -> some View {
        content
            .overlay(
                Circle()
                    .stroke(color, lineWidth: 2)
                    .scaleEffect(isPulsing ? 2.5 : 1.0)
                    .opacity(isPulsing ? 0 : 0.6)
            )
            .onAppear {
                withAnimation(.easeOut(duration: duration).repeatForever(autoreverses: false)) {
                    isPulsing = true
                }
            }
    }
}

extension View {
    /// Adds pulsing animation overlay
    func pulse(color: Color = .blue, duration: Double = 1.5) -> some View {
        modifier(PulseAnimationModifier(color: color, duration: duration))
    }
}

// MARK: - Number Counter Animation

/// Animated number display that counts up/down
struct AnimatedNumber: View {
    let value: Int
    let font: Font
    let color: Color

    @State private var displayedValue: Int = 0

    init(_ value: Int, font: Font = .title, color: Color = .primary) {
        self.value = value
        self.font = font
        self.color = color
    }

    var body: some View {
        Text("\(displayedValue)")
            .font(font)
            .fontWeight(.bold)
            .foregroundColor(color)
            .contentTransition(.numericText())
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: displayedValue)
            .onAppear {
                displayedValue = value
            }
            .onChange(of: value) { _, newValue in
                displayedValue = newValue
            }
    }
}

// MARK: - Slide Transition

/// Custom slide transitions for entering/exiting views
extension AnyTransition {
    static var slideFromBottom: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        )
    }

    static var slideFromTop: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }

    static var scaleAndFade: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .scale(scale: 1.1).combined(with: .opacity)
        )
    }
}

// MARK: - Preview

#Preview("Shimmer Effect") {
    VStack(spacing: 20) {
        SkeletonView(width: 200, height: 20)
        SkeletonView(width: 150, height: 16)
        SkeletonCard()
    }
    .padding()
}

#Preview("Empty State") {
    DashboardEmptyState(
        icon: "checkmark.circle",
        title: "All caught up!",
        message: "You have no tasks for today. Enjoy your free time or plan ahead.",
        suggestion: "Try adding a new task to stay productive",
        actionTitle: "Add Task",
        action: {},
        accentColor: .green
    )
    .padding()
}

#Preview("Staggered Animation") {
    VStack(spacing: 16) {
        ForEach(0..<5, id: \.self) { index in
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.2))
                .frame(height: 60)
                .staggeredEntrance(index: index)
        }
    }
    .padding()
}
