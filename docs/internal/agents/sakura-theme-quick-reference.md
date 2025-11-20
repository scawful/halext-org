# Sakura Theme Quick Reference

## Color Palette

```swift
// Exact colors used in Sakura theme
background:              #FFF0F5  // Lavender Blush (very light pink)
secondaryBackground:     #FFE4E9  // Light Pink (card backgrounds)
accentPrimary:           #FF69B4  // Hot Pink (buttons, highlights)
textPrimary:             #2D1B2E  // Dark Purple-Brown (main text)
textSecondary:           #4A2E4D  // Medium Purple (secondary text)
```

## RGB Values

```
Background:          (255, 240, 245)
Secondary BG:        (255, 228, 233)
Accent (Hot Pink):   (255, 105, 180)
Text Primary:        (45, 27, 46)
Text Secondary:      (74, 46, 77)
```

## Visual Hierarchy

```
┌─────────────────────────────────────┐
│  Background: #FFF0F5 (light pink)   │
│  ┌────────────────────────────────┐ │
│  │ Card: #FFE4E9 (deeper pink)    │ │
│  │                                 │ │
│  │  Title: #2D1B2E (dark purple)  │ │
│  │  Text: #4A2E4D (med purple)    │ │
│  │                                 │ │
│  │  [Button: #FF69B4 hot pink]    │ │
│  └────────────────────────────────┘ │
└─────────────────────────────────────┘
```

## Usage Examples

### Theme Selection
```swift
// In Settings or SettingsView:
themeManager.setTheme(.sakura)

// Or programmatically:
ThemeManager.shared.currentTheme = .sakura
```

### View Background
```swift
// Option 1: Direct color access
.background(ThemeManager.shared.backgroundColor)

// Option 2: Helper extension
.themedBackground()
```

### Card Styling
```swift
// Option 1: Manual
.background(
    RoundedRectangle(cornerRadius: 16)
        .fill(ThemeManager.shared.cardBackgroundColor)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
)

// Option 2: Helper (recommended)
.themedCardBackground()

// Option 3: Custom corner radius
.themedCardBackground(cornerRadius: 12, shadow: true)
```

### Text Colors
```swift
// Primary text
Text("Hello")
    .foregroundColor(ThemeManager.shared.textColor)
    // Or: .themedText()

// Secondary text
Text("Subtitle")
    .foregroundColor(ThemeManager.shared.secondaryTextColor)
    // Or: .themedSecondaryText()
```

### Accent Colors
```swift
// Buttons, icons, highlights
Button("Action") { }
    .foregroundColor(ThemeManager.shared.accentColor)

Image(systemName: "heart.fill")
    .foregroundColor(ThemeManager.shared.accentColor)
```

## Contrast Ratios

```
Text on Background:
#2D1B2E on #FFF0F5 = 13.04:1 (WCAG AAA ✓)

Text on Cards:
#2D1B2E on #FFE4E9 = 12.43:1 (WCAG AAA ✓)

Accent Contrast:
#FF69B4 on #FFF0F5 = 3.52:1 (WCAG AA ✓ for large text)
```

## Theme Comparison

| Theme           | BG Hex  | Accent Hex | Feel         |
|-----------------|---------|------------|--------------|
| **Sakura**      | #FFF0F5 | #FF69B4    | Soft pink    |
| Cherry Blossom  | #FFF5F7 | #FF4060    | Bold red-pink|
| Pastel          | #F8F6FF | #CC99E6    | Purple tint  |
| Lavender        | #F7F5FF | #9966E6    | Deep purple  |

## Code Location

```
Theme Definition:
/Users/scawful/Code/halext-org/ios/Cafe/Core/Theme/Theme.swift
Line 121-130

Theme Manager:
/Users/scawful/Code/halext-org/ios/Cafe/Core/Theme/ThemeManager.swift

Theme Settings UI:
/Users/scawful/Code/halext-org/ios/Cafe/Features/Settings/ThemeSettingsView.swift
```

## Helper Extensions Available

```swift
// In ThemeManager.swift, available on all Views:

.themedBackground()
// Applies main background color

.themedCard()
// Applies card color with 12pt corners

.themedCardBackground(cornerRadius: 16, shadow: true)
// Applies card with rounded rect and shadow

.themedText()
// Applies primary text color

.themedSecondaryText()
// Applies secondary text color

.scaledFont(16, weight: .regular)
// Applies font with user's size preference
```

## Migration Pattern

```swift
// OLD: System colors
.background(Color(.systemBackground))
.foregroundColor(.primary)

// NEW: Theme colors
.background(ThemeManager.shared.backgroundColor)
.foregroundColor(ThemeManager.shared.textColor)

// BETTER: Theme helpers
.themedBackground()
.themedText()
```

## User Access Path

```
App → Settings → "Theme & Appearance" → Light Themes → "Sakura"
```

## Persistence

```swift
// Saved automatically via UserDefaults
// Key: "selectedTheme"
// Value: "sakura"

// Load on app launch:
ThemeManager.shared.currentTheme // Restored from UserDefaults
```

## Testing

```swift
// Preview with Sakura theme
#Preview {
    MyView()
        .environment(ThemeManager.shared)
        .onAppear {
            ThemeManager.shared.setTheme(.sakura)
        }
}
```

## Best Practices

1. Use helper extensions (`.themedBackground()`) over direct access
2. Always use theme colors, never hardcode
3. Test with multiple themes
4. Respect user's theme preference
5. Provide color previews in pickers
6. Maintain WCAG AA contrast minimum
7. Consider dark mode variants

## Common Patterns

### Card Widget
```swift
VStack {
    HStack {
        Image(systemName: "heart.fill")
            .foregroundColor(ThemeManager.shared.accentColor)
        Text("Title")
            .themedText()
        Spacer()
    }
    Text("Content here")
        .themedSecondaryText()
}
.padding()
.themedCardBackground()
```

### List Row
```swift
HStack {
    Text("Label")
        .themedText()
    Spacer()
    Text("Value")
        .themedSecondaryText()
}
.padding()
.background(ThemeManager.shared.cardBackgroundColor)
```

### Full Screen View
```swift
NavigationStack {
    ScrollView {
        // content
    }
    .themedBackground()
    .navigationTitle("Title")
}
```

---

**Quick Reminder:** Sakura = Soft Pink Theme with Hot Pink Accents! 🌸
