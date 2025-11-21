//
//  BackgroundStyle.swift
//  Cafe
//
//  Advanced background style system supporting images, gradients, blur, and animations
//

import SwiftUI
#if canImport(PhotosUI)
import PhotosUI
#endif

// MARK: - Background Style Enum

enum BackgroundStyle: String, Codable, CaseIterable, Identifiable {
    case solid = "Solid"
    case gradient = "Gradient"
    case image = "Image"
    case animated = "Animated"
    case blur = "Blur"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .solid: return "circle.fill"
        case .gradient: return "rectangle.lefthalf.filled"
        case .image: return "photo.fill"
        case .animated: return "sparkles"
        case .blur: return "hexagon.fill"
        }
    }
}

// MARK: - Custom Background Model

struct CustomBackground: Codable, Hashable, Identifiable {
    var id: UUID
    var name: String
    var style: BackgroundStyle
    var solidColor: CodableColor?
    var gradient: CodableGradient?
    var imageData: Data?
    var pattern: BackgroundPattern?
    var blurIntensity: Double
    var animationType: AnimationType?
    var animationSpeed: Double
    var opacity: Double
    
    init(
        id: UUID = UUID(),
        name: String = "Custom Background",
        style: BackgroundStyle = .solid,
        solidColor: CodableColor? = nil,
        gradient: CodableGradient? = nil,
        imageData: Data? = nil,
        pattern: BackgroundPattern? = nil,
        blurIntensity: Double = 0.0,
        animationType: AnimationType? = nil,
        animationSpeed: Double = 1.0,
        opacity: Double = 1.0
    ) {
        self.id = id
        self.name = name
        self.style = style
        self.solidColor = solidColor
        self.gradient = gradient
        self.imageData = imageData
        self.pattern = pattern
        self.blurIntensity = blurIntensity
        self.animationType = animationType
        self.animationSpeed = animationSpeed
        self.opacity = opacity
    }
    
    static let `default` = CustomBackground(
        style: .solid,
        solidColor: CodableColor(Color(.systemBackground)),
        opacity: 1.0
    )
}

// MARK: - Background Pattern

enum BackgroundPattern: String, Codable, CaseIterable, Identifiable {
    case dots = "Dots"
    case grid = "Grid"
    case lines = "Lines"
    case waves = "Waves"
    case mesh = "Mesh"
    case none = "None"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .dots: return "circle.grid.3x3.fill"
        case .grid: return "square.grid.3x3.fill"
        case .lines: return "line.diagonal"
        case .waves: return "waveform.path"
        case .mesh: return "hexagon.grid.fill"
        case .none: return "nosign"
        }
    }
}

// MARK: - Animation Type

enum AnimationType: String, Codable, CaseIterable, Identifiable {
    case pulse = "Pulse"
    case shimmer = "Shimmer"
    case wave = "Wave"
    case gradientShift = "Gradient Shift"
    case particles = "Particles"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .pulse: return "waveform"
        case .shimmer: return "sparkles"
        case .wave: return "water.waves"
        case .gradientShift: return "slider.horizontal.3"
        case .particles: return "sparkles.rectangle.stack"
        }
    }
}

// MARK: - View Background Modifier

struct ViewBackgroundModifier: ViewModifier {
    let background: CustomBackground
    @State private var animationPhase: Double = 0
    
    func body(content: Content) -> some View {
        content
            .background(backgroundView)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        ZStack {
            baseBackground
            
            if let pattern = background.pattern, pattern != .none {
                patternOverlay(pattern: pattern)
            }
            
            if background.style == .blur && background.blurIntensity > 0 {
                blurOverlay
            }
        }
        .opacity(background.opacity)
        .onAppear {
            if background.animationType != nil {
                startAnimation()
            }
        }
    }
    
    @ViewBuilder
    private var baseBackground: some View {
        switch background.style {
        case .solid:
            if let color = background.solidColor {
                Color(color)
            } else {
                Color(.systemBackground)
            }
            
        case .gradient:
            if let gradient = background.gradient {
                LinearGradient(
                    colors: [
                        Color(gradient.startColor),
                        Color(gradient.endColor)
                    ],
                    startPoint: gradient.startPoint.unitPoint,
                    endPoint: gradient.endPoint.unitPoint
                )
            } else {
                Color(.systemBackground)
            }
            
        case .image:
            if let imageData = background.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            } else {
                Color(.systemBackground)
            }
            
        case .animated:
            animatedBackground
            
        case .blur:
            if let color = background.solidColor {
                Color(color)
            } else if let gradient = background.gradient {
                LinearGradient(
                    colors: [
                        Color(gradient.startColor),
                        Color(gradient.endColor)
                    ],
                    startPoint: gradient.startPoint.unitPoint,
                    endPoint: gradient.endPoint.unitPoint
                )
            } else {
                Color(.systemBackground)
            }
        }
    }
    
    @ViewBuilder
    private var animatedBackground: some View {
        switch background.animationType {
        case .pulse:
            pulseBackground
            
        case .shimmer:
            shimmerBackground
            
        case .wave:
            waveBackground
            
        case .gradientShift:
            gradientShiftBackground
            
        case .particles:
            particlesBackground
            
        case .none:
            if let color = background.solidColor {
                Color(color)
            } else {
                Color(.systemBackground)
            }
        }
    }
    
    @ViewBuilder
    private var pulseBackground: some View {
        let color = background.solidColor ?? CodableColor(Color(.systemBackground))
        Circle()
            .fill(Color(color))
            .scaleEffect(1.0 + 0.1 * sin(animationPhase))
            .opacity(0.5 + 0.3 * sin(animationPhase))
    }
    
    @ViewBuilder
    private var shimmerBackground: some View {
        let gradient = background.gradient ?? CodableGradient(
            startColor: CodableColor(Color.white.opacity(0.3)),
            endColor: CodableColor(Color.white.opacity(0.1)),
            startPoint: .leading,
            endPoint: .trailing
        )
        LinearGradient(
            colors: [
                Color(gradient.startColor),
                Color(gradient.endColor),
                Color(gradient.startColor)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .offset(x: -300 + 600 * (animationPhase / (2 * .pi)))
    }
    
    @ViewBuilder
    private var waveBackground: some View {
        let color = background.solidColor ?? CodableColor(Color(.systemBackground))
        WaveShape(phase: animationPhase)
            .fill(Color(color).opacity(0.6))
    }
    
    @ViewBuilder
    private var gradientShiftBackground: some View {
        if let gradient = background.gradient {
            AngularGradient(
                colors: [
                    Color(gradient.startColor),
                    Color(gradient.endColor),
                    Color(gradient.startColor)
                ],
                center: .center,
                angle: .degrees(animationPhase * 360 / (2 * .pi))
            )
        } else {
            Color(.systemBackground)
        }
    }
    
    @ViewBuilder
    private var particlesBackground: some View {
        let color = background.solidColor ?? CodableColor(Color(.systemBackground))
        GeometryReader { geometry in
            ForEach(0..<20, id: \.self) { index in
                Circle()
                    .fill(Color(color).opacity(0.3))
                    .frame(width: 20, height: 20)
                    .position(
                        x: CGFloat(index * 50) + 50 * CGFloat(sin(animationPhase + Double(index))),
                        y: CGFloat(index * 30) + 30 * CGFloat(cos(animationPhase + Double(index)))
                    )
            }
        }
    }
    
    @ViewBuilder
    private func patternOverlay(pattern: BackgroundPattern) -> some View {
        switch pattern {
        case .dots:
            DotsPattern()
                .fill(Color.gray.opacity(0.1))
        case .grid:
            GridPattern()
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        case .lines:
            LinesPattern()
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        case .waves:
            WavesPattern(phase: animationPhase)
                .stroke(Color.gray.opacity(0.1), lineWidth: 2)
        case .mesh:
            MeshPattern()
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        case .none:
            EmptyView()
        }
    }
    
    private var blurOverlay: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .opacity(background.blurIntensity)
    }
    
    private func startAnimation() {
        withAnimation(
            .linear(duration: background.animationSpeed)
            .repeatForever(autoreverses: false)
        ) {
            animationPhase = 2 * .pi
        }
    }
}

// MARK: - Pattern Shapes

struct DotsPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let spacing: CGFloat = 20
        for x in stride(from: 0, through: rect.width, by: spacing) {
            for y in stride(from: 0, through: rect.height, by: spacing) {
                path.addEllipse(in: CGRect(x: x, y: y, width: 2, height: 2))
            }
        }
        return path
    }
}

struct GridPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let spacing: CGFloat = 30
        for x in stride(from: 0, through: rect.width, by: spacing) {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
        }
        for y in stride(from: 0, through: rect.height, by: spacing) {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
        }
        return path
    }
}

struct LinesPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let spacing: CGFloat = 20
        for y in stride(from: 0, through: rect.height, by: spacing) {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
        }
        return path
    }
}

struct WavesPattern: Shape {
    var phase: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let frequency: Double = 2
        let amplitude: CGFloat = 10
        
        path.move(to: CGPoint(x: 0, y: rect.midY))
        for x in stride(from: 0, through: rect.width, by: 1) {
            let y = rect.midY + amplitude * CGFloat(sin((Double(x) / rect.width) * 2 * .pi * frequency + phase))
            path.addLine(to: CGPoint(x: x, y: y))
        }
        return path
    }
}

struct MeshPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let spacing: CGFloat = 40
        for x in stride(from: 0, through: rect.width, by: spacing) {
            for y in stride(from: 0, through: rect.height, by: spacing) {
                let hexagon = HexagonShape()
                path.addPath(hexagon.path(in: CGRect(x: x, y: y, width: spacing, height: spacing)))
            }
        }
        return path
    }
}

struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let angle: CGFloat = .pi / 3
        
        for i in 0..<6 {
            let x = center.x + radius * cos(CGFloat(i) * angle)
            let y = center.y + radius * sin(CGFloat(i) * angle)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}

struct WaveShape: Shape {
    var phase: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let frequency: Double = 3
        let amplitude: CGFloat = rect.height * 0.1
        
        path.move(to: CGPoint(x: 0, y: rect.midY))
        for x in stride(from: 0, through: rect.width, by: 1) {
            let y = rect.midY + amplitude * CGFloat(sin((Double(x) / rect.width) * 2 * .pi * frequency + phase))
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

// MARK: - View Extension

extension View {
    func customBackground(_ background: CustomBackground) -> some View {
        self.modifier(ViewBackgroundModifier(background: background))
    }
}

// MARK: - Gradient Presets

extension CodableGradient {
    static let ocean = CodableGradient(
        startColor: CodableColor(Color(red: 0.0, green: 0.48, blue: 0.8)),
        endColor: CodableColor(Color(red: 0.0, green: 0.7, blue: 0.9)),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let sunset = CodableGradient(
        startColor: CodableColor(Color(red: 1.0, green: 0.6, blue: 0.4)),
        endColor: CodableColor(Color(red: 1.0, green: 0.3, blue: 0.5)),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let aurora = CodableGradient(
        startColor: CodableColor(Color(red: 0.2, green: 0.8, blue: 0.6)),
        endColor: CodableColor(Color(red: 0.3, green: 0.4, blue: 0.9)),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let midnight = CodableGradient(
        startColor: CodableColor(Color(red: 0.05, green: 0.08, blue: 0.12)),
        endColor: CodableColor(Color(red: 0.1, green: 0.15, blue: 0.25)),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let forest = CodableGradient(
        startColor: CodableColor(Color(red: 0.2, green: 0.5, blue: 0.3)),
        endColor: CodableColor(Color(red: 0.4, green: 0.7, blue: 0.5)),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let allPresets: [CodableGradient] = [
        .ocean, .sunset, .aurora, .midnight, .forest
    ]
}
