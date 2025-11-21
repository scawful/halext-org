//
//  BackgroundCustomizationView.swift
//  Cafe
//
//  Advanced background customization with image picker, gradient builder, blur, and animations
//

import SwiftUI
#if canImport(PhotosUI)
import PhotosUI
#endif

struct BackgroundCustomizationView: View {
    @State private var themeManager = ThemeManager.shared
    @State private var customBackground: CustomBackground
    #if canImport(PhotosUI)
    @State private var selectedImageItem: PhotosPickerItem?
    #endif
    @State private var showingGradientBuilder = false
    @State private var showingAnimationSettings = false
    
    init() {
        _customBackground = State(initialValue: ThemeManager.shared.customBackground)
    }
    
    var body: some View {
        List {
            // Background Style Picker
            backgroundStyleSection
            
            // Style-specific settings
            styleSettings
            
            // Pattern Overlay
            if customBackground.style != .blur {
                patternSection
            }
            
            // Blur Settings
            if customBackground.style == .blur || customBackground.style == .image {
                blurSettingsSection
            }
            
            // Opacity
            opacitySection
            
            // Preview
            previewSection
            
            // Per-View Backgrounds
            perViewSection
        }
        .navigationTitle("Background Customization")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingGradientBuilder) {
            GradientBuilderView(background: $customBackground)
        }
        #if canImport(PhotosUI)
        .onChange(of: selectedImageItem) { oldValue, newValue in
            if let newValue = newValue {
                loadImage(from: newValue)
            }
        }
        #endif
    }
    
    #if canImport(PhotosUI)
    private func loadImage(from item: PhotosPickerItem) {
        Task.detached { @MainActor in
            if let data = try? await item.loadTransferable(type: Data.self) {
                await MainActor.run {
                    customBackground.imageData = data
                    customBackground.style = .image
                    saveBackground()
                }
            }
        }
    }
    #endif
    
    private var backgroundStyleSection: some View {
        Section {
            Picker("Background Style", selection: $customBackground.style) {
                ForEach(BackgroundStyle.allCases) { style in
                    HStack {
                        Image(systemName: style.icon)
                        Text(style.rawValue)
                    }
                    .tag(style)
                }
            }
            .onChange(of: customBackground.style) { _, newStyle in
                updateBackgroundForStyle(newStyle)
                saveBackground()
            }
        } header: {
            Text("Style")
        } footer: {
            Text("Choose the type of background you want")
        }
    }
    
    private var patternSection: some View {
        Section {
            Picker("Pattern Overlay", selection: Binding(
                get: { customBackground.pattern ?? .none },
                set: { newPattern in
                    customBackground.pattern = newPattern == .none ? nil : newPattern
                    saveBackground()
                }
            )) {
                ForEach(BackgroundPattern.allCases) { pattern in
                    HStack {
                        Image(systemName: pattern.icon)
                        Text(pattern.rawValue)
                    }
                    .tag(pattern)
                }
            }
        } header: {
            Text("Pattern")
        } footer: {
            Text("Add a subtle pattern overlay to your background")
        }
    }
    
    private var blurSettingsSection: some View {
        Section {
            HStack {
                Text("Blur Intensity")
                Spacer()
                Text("\(Int(customBackground.blurIntensity * 100))%")
                    .foregroundColor(.secondary)
            }
            Slider(value: $customBackground.blurIntensity, in: 0.0...1.0, step: 0.1)
                .onChange(of: customBackground.blurIntensity) { _, _ in
                    saveBackground()
                }
        } header: {
            Text("Blur Effect")
        } footer: {
            Text("Apply a blur effect for glass morphism")
        }
    }
    
    private var opacitySection: some View {
        Section {
            HStack {
                Text("Opacity")
                Spacer()
                Text("\(Int(customBackground.opacity * 100))%")
                    .foregroundColor(.secondary)
            }
            Slider(value: $customBackground.opacity, in: 0.1...1.0, step: 0.1)
                .onChange(of: customBackground.opacity) { _, _ in
                    saveBackground()
                }
        } header: {
            Text("Opacity")
        }
    }
    
    private var previewSection: some View {
        Section {
            PreviewBackgroundView(background: customBackground)
                .frame(height: 200)
                .cornerRadius(12)
        } header: {
            Text("Preview")
        }
    }
    
    private var perViewSection: some View {
        Section {
            NavigationLink("Manage Per-View Backgrounds") {
                PerViewBackgroundSettingsView()
            }
        } header: {
            Text("Advanced")
        } footer: {
            Text("Set different backgrounds for different screens")
        }
    }
    
    @ViewBuilder
    private var styleSettings: some View {
        switch customBackground.style {
        case .solid:
            solidSettings
        case .gradient:
            gradientSettings
        case .image:
            imageSettings
        case .animated:
            animatedSettings
        case .blur:
            blurSettings
        }
    }
    
    private var solidSettings: some View {
        Section {
            ColorPicker("Background Color", selection: Binding(
                get: { customBackground.solidColor.map { Color($0) } ?? Color(.systemBackground) },
                set: { customBackground.solidColor = CodableColor($0); saveBackground() }
            ))
        } header: {
            Text("Solid Color")
        }
    }
    
    private var gradientSettings: some View {
        Section {
            Button(action: {
                showingGradientBuilder = true
            }) {
                HStack {
                    Text("Gradient Builder")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let gradient = customBackground.gradient {
                HStack {
                    Text("Start Color")
                    Spacer()
                    ColorPicker("", selection: Binding(
                        get: { Color(gradient.startColor) },
                        set: { newColor in
                            let newGradient = CodableGradient(
                                startColor: CodableColor(newColor),
                                endColor: gradient.endColor,
                                startPoint: gradient.startPoint,
                                endPoint: gradient.endPoint
                            )
                            customBackground.gradient = newGradient
                            saveBackground()
                        }
                    ))
                    .labelsHidden()
                }
                
                HStack {
                    Text("End Color")
                    Spacer()
                    ColorPicker("", selection: Binding(
                        get: { Color(gradient.endColor) },
                        set: { newColor in
                            let newGradient = CodableGradient(
                                startColor: gradient.startColor,
                                endColor: CodableColor(newColor),
                                startPoint: gradient.startPoint,
                                endPoint: gradient.endPoint
                            )
                            customBackground.gradient = newGradient
                            saveBackground()
                        }
                    ))
                    .labelsHidden()
                }
                
                Picker("Direction", selection: Binding(
                    get: { gradient.startPoint },
                    set: { newPoint in
                        let newGradient = CodableGradient(
                            startColor: gradient.startColor,
                            endColor: gradient.endColor,
                            startPoint: newPoint,
                            endPoint: gradient.endPoint
                        )
                        customBackground.gradient = newGradient
                        saveBackground()
                    }
                )) {
                    Text("Top to Bottom").tag(CodableGradient.Point.top)
                    Text("Left to Right").tag(CodableGradient.Point.leading)
                    Text("Top-Left to Bottom-Right").tag(CodableGradient.Point.topLeading)
                    Text("Top-Right to Bottom-Left").tag(CodableGradient.Point.topTrailing)
                }
            }
            
            // Gradient Presets
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(CodableGradient.allPresets, id: \.startColor) { preset in
                        Button(action: {
                            customBackground.gradient = preset
                            saveBackground()
                        }) {
                            LinearGradient(
                                colors: [Color(preset.startColor), Color(preset.endColor)],
                                startPoint: preset.startPoint.unitPoint,
                                endPoint: preset.endPoint.unitPoint
                            )
                            .frame(width: 60, height: 60)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(customBackground.gradient == preset ? Color.blue : Color.clear, lineWidth: 2)
                            )
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        } header: {
            Text("Gradient")
        }
    }
    
    private var imageSettings: some View {
        Section {
            #if canImport(PhotosUI)
            PhotosPicker(
                selection: $selectedImageItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                HStack {
                    if customBackground.imageData != nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    Text(customBackground.imageData != nil ? "Change Image" : "Select Image")
                    Spacer()
                    Image(systemName: "photo")
                        .foregroundColor(.secondary)
                }
            }
            #else
            Button(action: {
                // Fallback for platforms without PhotosUI
            }) {
                HStack {
                    if customBackground.imageData != nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    Text(customBackground.imageData != nil ? "Change Image" : "Select Image")
                    Spacer()
                    Image(systemName: "photo")
                        .foregroundColor(.secondary)
                }
            }
            .disabled(true)
            #endif
            
            if customBackground.imageData != nil {
                Button(role: .destructive, action: {
                    customBackground.imageData = nil
                    customBackground.style = .solid
                    saveBackground()
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Remove Image")
                    }
                }
            }
        } header: {
            Text("Image")
        } footer: {
            Text("Choose an image from your photo library")
        }
    }
    
    private var animatedSettings: some View {
        Section {
            Picker("Animation Type", selection: Binding(
                get: { customBackground.animationType ?? .pulse },
                set: { customBackground.animationType = $0; saveBackground() }
            )) {
                ForEach(AnimationType.allCases) { type in
                    HStack {
                        Image(systemName: type.icon)
                        Text(type.rawValue)
                    }
                    .tag(type as AnimationType?)
                }
            }
            
            HStack {
                Text("Animation Speed")
                Spacer()
                Text("\(String(format: "%.1f", customBackground.animationSpeed))x")
                    .foregroundColor(.secondary)
            }
            Slider(value: $customBackground.animationSpeed, in: 0.5...3.0, step: 0.1)
                .onChange(of: customBackground.animationSpeed) { _, _ in
                    saveBackground()
                }
            
            ColorPicker("Base Color", selection: Binding(
                get: { customBackground.solidColor.map { Color($0) } ?? Color(.systemBackground) },
                set: { customBackground.solidColor = CodableColor($0); saveBackground() }
            ))
        } header: {
            Text("Animation")
        } footer: {
            Text("Animated backgrounds use subtle motion effects")
        }
    }
    
    private var blurSettings: some View {
        Section {
            ColorPicker("Base Color", selection: Binding(
                get: { customBackground.solidColor.map { Color($0) } ?? Color(.systemBackground) },
                set: { customBackground.solidColor = CodableColor($0); saveBackground() }
            ))
            
            Button(action: {
                showingGradientBuilder = true
            }) {
                HStack {
                    Text("Use Gradient Instead")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Blur Base")
        } footer: {
            Text("Choose a base color or gradient for the blur effect")
        }
    }
    
    private func updateBackgroundForStyle(_ style: BackgroundStyle) {
        switch style {
        case .solid:
            if customBackground.solidColor == nil {
                customBackground.solidColor = CodableColor(Color(.systemBackground))
            }
        case .gradient:
            if customBackground.gradient == nil {
                customBackground.gradient = CodableGradient.ocean
            }
        case .image:
            // Keep existing image data if any
            break
        case .animated:
            if customBackground.animationType == nil {
                customBackground.animationType = .pulse
            }
            if customBackground.solidColor == nil {
                customBackground.solidColor = CodableColor(Color(.systemBackground))
            }
        case .blur:
            if customBackground.solidColor == nil {
                customBackground.solidColor = CodableColor(Color(.systemBackground))
            }
            if customBackground.blurIntensity == 0 {
                customBackground.blurIntensity = 0.5
            }
        }
    }
    
    private func saveBackground() {
        themeManager.customBackground = customBackground
    }
}

// MARK: - Gradient Builder View

struct GradientBuilderView: View {
    @Binding var background: CustomBackground
    @Environment(\.dismiss) var dismiss
    @State private var startColor: Color
    @State private var endColor: Color
    @State private var startPoint: CodableGradient.Point
    @State private var endPoint: CodableGradient.Point
    
    init(background: Binding<CustomBackground>) {
        self._background = background
        let gradient = background.wrappedValue.gradient ?? CodableGradient.ocean
        _startColor = State(initialValue: Color(gradient.startColor))
        _endColor = State(initialValue: Color(gradient.endColor))
        _startPoint = State(initialValue: gradient.startPoint)
        _endPoint = State(initialValue: gradient.endPoint)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ColorPicker("Start Color", selection: $startColor)
                    ColorPicker("End Color", selection: $endColor)
                    
                    Picker("Start Point", selection: $startPoint) {
                        Text("Top").tag(CodableGradient.Point.top)
                        Text("Bottom").tag(CodableGradient.Point.bottom)
                        Text("Leading").tag(CodableGradient.Point.leading)
                        Text("Trailing").tag(CodableGradient.Point.trailing)
                        Text("Top Leading").tag(CodableGradient.Point.topLeading)
                        Text("Top Trailing").tag(CodableGradient.Point.topTrailing)
                        Text("Bottom Leading").tag(CodableGradient.Point.bottomLeading)
                        Text("Bottom Trailing").tag(CodableGradient.Point.bottomTrailing)
                    }
                    
                    Picker("End Point", selection: $endPoint) {
                        Text("Top").tag(CodableGradient.Point.top)
                        Text("Bottom").tag(CodableGradient.Point.bottom)
                        Text("Leading").tag(CodableGradient.Point.leading)
                        Text("Trailing").tag(CodableGradient.Point.trailing)
                        Text("Top Leading").tag(CodableGradient.Point.topLeading)
                        Text("Top Trailing").tag(CodableGradient.Point.topTrailing)
                        Text("Bottom Leading").tag(CodableGradient.Point.bottomLeading)
                        Text("Bottom Trailing").tag(CodableGradient.Point.bottomTrailing)
                    }
                } header: {
                    Text("Gradient Settings")
                }
                
                Section {
                    LinearGradient(
                        colors: [startColor, endColor],
                        startPoint: startPoint.unitPoint,
                        endPoint: endPoint.unitPoint
                    )
                    .frame(height: 150)
                    .cornerRadius(12)
                } header: {
                    Text("Preview")
                }
            }
            .navigationTitle("Gradient Builder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        background.gradient = CodableGradient(
                            startColor: CodableColor(startColor),
                            endColor: CodableColor(endColor),
                            startPoint: startPoint,
                            endPoint: endPoint
                        )
                        background.style = .gradient
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview Background View

struct PreviewBackgroundView: View {
    let background: CustomBackground
    
    var body: some View {
        ZStack {
            // Background
            CustomBackgroundView(background: background)
            
            // Sample content
            VStack {
                Image(systemName: "app.fill")
                    .font(.largeTitle)
                    .foregroundColor(.white.opacity(0.8))
                Text("Preview")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

// MARK: - Custom Background View

struct CustomBackgroundView: View {
    let background: CustomBackground
    
    var body: some View {
        Rectangle()
            .customBackground(background)
    }
}

// MARK: - Per-View Background Settings

struct PerViewBackgroundSettingsView: View {
    @State private var themeManager = ThemeManager.shared
    @State private var viewIds: [String] = ["dashboard", "tasks", "calendar", "messages", "settings"]
    
    var body: some View {
        List {
            ForEach(viewIds, id: \.self) { viewId in
                NavigationLink(destination: BackgroundCustomizationViewForView(viewId: viewId)) {
                    HStack {
                        Text(viewId.capitalized)
                        Spacer()
                        if themeManager.getBackgroundForView(viewId: viewId) != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
            }
        }
        .navigationTitle("Per-View Backgrounds")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Background Customization for Specific View

struct BackgroundCustomizationViewForView: View {
    let viewId: String
    @State private var themeManager = ThemeManager.shared
    @State private var customBackground: CustomBackground
    
    init(viewId: String) {
        self.viewId = viewId
        let existing = ThemeManager.shared.getBackgroundForView(viewId: viewId) ?? .default
        _customBackground = State(initialValue: existing)
    }
    
    var body: some View {
        BackgroundCustomizationView()
            .onAppear {
                if let existing = themeManager.getBackgroundForView(viewId: viewId) {
                    customBackground = existing
                }
            }
            .onChange(of: customBackground) { _, newBackground in
                themeManager.setBackgroundForView(viewId: viewId, background: newBackground)
            }
    }
}

#Preview {
    NavigationStack {
        BackgroundCustomizationView()
    }
}
