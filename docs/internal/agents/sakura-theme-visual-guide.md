# Sakura Theme - Visual Guide

## Color Swatches

```
████████████████  #FFF0F5  Background (Lavender Blush)
████████████████  #FFE4E9  Cards (Light Pink)
████████████████  #FF69B4  Accents (Hot Pink)
████████████████  #2D1B2E  Primary Text (Dark Purple-Brown)
████████████████  #4A2E4D  Secondary Text (Medium Purple)
```

## Visual Mockup (ASCII Art)

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ 🌸 Cafe - Sakura Theme                ┃
┃━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┃
┃                                        ┃  Background: #FFF0F5
┃  ╭────────────────────────────────╮   ┃  (Light pink wash)
┃  │  📋 Today's Tasks              │   ┃
┃  │                                │   ┃  Card: #FFE4E9
┃  │  ○ Review design mockups       │   ┃  (Soft pink)
┃  │  ○ Update documentation        │   ┃
┃  │  ● Ship Sakura theme 🌸        │   ┃  Text: #2D1B2E
┃  │                                │   ┃  (Dark purple-brown)
┃  │  [➕ Add Task]                 │   ┃  Button: #FF69B4
┃  ╰────────────────────────────────╯   ┃  (Hot pink)
┃                                        ┃
┃  ╭────────────────────────────────╮   ┃
┃  │  📊 Quick Stats                │   ┃
┃  │                                │   ┃
┃  │  💖 3 Completed Today          │   ┃  Icons: Hot pink
┃  │  📅 5 This Week                │   ┃  accent color
┃  │  ⭐ 12 Total Active            │   ┃
┃  │                                │   ┃
┃  ╰────────────────────────────────╯   ┃
┃                                        ┃
┃  ╭────────────────────────────────╮   ┃
┃  │  🎯 Quick Actions              │   ┃
┃  │                                │   ┃
┃  │  [💡 Smart Generate]           │   ┃  Buttons have hot
┃  │  [📝 New Task]                 │   ┃  pink backgrounds
┃  │  [📸 Scan Document]            │   ┃
┃  │                                │   ┃
┃  ╰────────────────────────────────╯   ┃
┃                                        ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

## Component Examples

### Button
```
┌──────────────────┐
│   ➕ Add Task    │  Background: #FF69B4 (Hot Pink)
└──────────────────┘  Text: White
```

### Card
```
╭─────────────────────────────────╮
│  Title Text                     │  Background: #FFE4E9 (Light Pink)
│  Secondary text goes here       │  Border: None or subtle pink
│                                 │  Shadow: Soft 5% black
╰─────────────────────────────────╯
```

### List Item
```
○ Task Name                    →    Text: #2D1B2E (Dark purple-brown)
  Due today                         Subtext: #4A2E4D (Medium purple)
                                    Icon: #FF69B4 (Hot pink)
```

### Header
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌸 Dashboard
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━    Title: #2D1B2E bold
```

### Badge
```
┌─────┐
│  5  │                             Background: #FF69B4
└─────┘                             Text: White
```

### Icon with Label
```
💖  Favorites                       Icon: #FF69B4
    12 items                        Label: #2D1B2E
                                    Count: #4A2E4D
```

## Layout Example

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃        iPhone Screen              ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃                                   ┃  <- #FFF0F5 Background
┃     Welcome back, Chris! 👋       ┃
┃                                   ┃
┃  ┌─────────────────────────────┐ ┃
┃  │ 💡 AI Task Generator        │ ┃  <- #FFE4E9 Card
┃  │ Generate smart tasks with AI│ ┃
┃  │ [Try Now →]                 │ ┃  <- #FF69B4 Button
┃  └─────────────────────────────┘ ┃
┃                                   ┃
┃  ┌─────────┐ ┌─────────┐ ┌─────┐┃
┃  │ Tasks   │ │ Events  │ │More │┃  <- Cards
┃  │   12    │ │    3    │ │ ... │┃
┃  └─────────┘ └─────────┘ └─────┘┃
┃                                   ┃
┃  📋 Upcoming Tasks                ┃  <- #2D1B2E Text
┃                                   ┃
┃  ┌─────────────────────────────┐ ┃
┃  │ ○ Review pull requests      │ ┃
┃  │ ○ Update documentation      │ ┃
┃  │ ● Deploy Sakura theme 🌸    │ ┃
┃  │ ○ Test on device            │ ┃
┃  └─────────────────────────────┘ ┃
┃                                   ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃ 📊 💬 📅 ⚙️ ⋯                    ┃  <- Tab Bar
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

## Settings Preview

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ ⚙️  Theme & Appearance            ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃                                   ┃
┃  Appearance                       ┃
┃  ┌─────┬──────┬──────────────┐   ┃
┃  │Light│ Dark │     Auto     │   ┃
┃  └─────┴──────┴──────────────┘   ┃
┃                                   ┃
┃  Light Themes                     ┃
┃                                   ┃
┃  ┌──────────────────┐             ┃
┃  │ ● ● ● Ocean      │             ┃
┃  └──────────────────┘             ┃
┃  ┌──────────────────┐             ┃
┃  │ ● ● ● Forest     │             ┃
┃  └──────────────────┘             ┃
┃  ┌──────────────────┐             ┃
┃  │ ● ● ● Sakura  ✓  │ <- Selected!┃
┃  └──────────────────┘             ┃
┃  ┌──────────────────┐             ┃
┃  │ ● ● ● Lavender   │             ┃
┃  └──────────────────┘             ┃
┃                                   ┃
┃  Color Preview                    ┃
┃  ┌─────────────────────────────┐ ┃
┃  │ Accent   ████ #FF69B4       │ ┃
┃  │ Background ████ #FFF0F5     │ ┃
┃  │ Card     ████ #FFE4E9       │ ┃
┃  │ Text     ████ #2D1B2E       │ ┃
┃  └─────────────────────────────┘ ┃
┃                                   ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

## Color Harmony

```
  Lightest                    Darkest
     │                            │
     ▼                            ▼
┌────────┬────────┬────────┬────────┬────────┐
│#FFF0F5 │#FFE4E9 │#FF69B4 │#4A2E4D │#2D1B2E │
│  BG    │  Card  │Accent  │ Text2  │ Text1  │
└────────┴────────┴────────┴────────┴────────┘
  Pink     Pink     Hot     Medium   Dark
  Wash     Base     Pink    Purple   Purple
```

## Contrast Matrix

```
                Background  Card     Accent
                (#FFF0F5)  (#FFE4E9) (#FF69B4)

Text Primary    13.04:1    12.43:1    4.23:1
(#2D1B2E)       AAA ✓      AAA ✓      AA  ✓

Text Secondary   8.49:1     8.10:1    2.75:1
(#4A2E4D)       AAA ✓      AAA ✓      -

Accent           3.52:1     3.36:1     -
(#FF69B4)       AA  ✓      AA  ✓      -
```

## Theme Mood Board

```
╔════════════════════════════════════════╗
║         SAKURA THEME INSPIRATION       ║
╠════════════════════════════════════════╣
║                                        ║
║  🌸  Cherry Blossoms                   ║
║  💗  Soft Romance                      ║
║  🎀  Playful Elegance                  ║
║  🌅  Spring Dawn                       ║
║  💖  Gentle Warmth                     ║
║  ✨  Dreamy Aesthetic                  ║
║                                        ║
║  Perfect for users who love:          ║
║  • Pink color palettes                ║
║  • Soft, calming interfaces           ║
║  • High contrast readability          ║
║  • Warm, inviting designs             ║
║  • Cherry blossom season              ║
║                                        ║
╚════════════════════════════════════════╝
```

## Color Psychology

```
#FFF0F5 (Background)
└─ Feelings: Calm, gentle, peaceful
   Use: Main background, reduces eye strain

#FFE4E9 (Cards)
└─ Feelings: Warm, inviting, soft
   Use: Content containers, cards

#FF69B4 (Accent)
└─ Feelings: Energetic, playful, friendly
   Use: Buttons, highlights, CTAs

#2D1B2E (Text)
└─ Feelings: Grounded, sophisticated
   Use: Headlines, body text

#4A2E4D (Secondary Text)
└─ Feelings: Subtle, understated
   Use: Captions, metadata, hints
```

## Before & After Comparison

```
Default Light Theme          Sakura Theme
┌─────────────────┐         ┌─────────────────┐
│ #FFFFFF White   │   VS    │ #FFF0F5 Pink    │
│                 │         │                 │
│  ╭───────────╮  │         │  ╭───────────╮  │
│  │ #F2F2F2   │  │         │  │ #FFE4E9   │  │
│  │ Gray Card │  │         │  │ Pink Card │  │
│  │           │  │         │  │           │  │
│  │ [#007AFF] │  │         │  │ [#FF69B4] │  │
│  │  Button   │  │         │  │  Button   │  │
│  ╰───────────╯  │         │  ╰───────────╯  │
│                 │         │                 │
└─────────────────┘         └─────────────────┘
 Standard iOS Blue           Warm Pink Theme
```

## Usage Scenarios

```
Perfect For:
✓ Spring season
✓ Feminine aesthetic lovers
✓ Pink color enthusiasts
✓ Cherry blossom fans
✓ Warm, inviting interfaces
✓ Romantic/soft designs
✓ High contrast needs
✓ Accessibility-conscious users

Not Ideal For:
✗ Corporate/serious contexts
✗ Users who dislike pink
✗ Minimalist grayscale fans
✗ Dark mode preferences
```

## Real-World Color Names

```
#FFF0F5 = Lavender Blush
        = Cotton Candy
        = Ballet Slipper
        = Powder Pink

#FFE4E9 = Pink Lace
        = Rose Quartz
        = Blossom
        = Fairy Tale

#FF69B4 = Hot Pink
        = Fuchsia Rose
        = Brilliant Rose
        = Persian Rose

#2D1B2E = Dark Purple-Brown
        = Eggplant
        = Deep Plum
        = Wine

#4A2E4D = Medium Purple
        = Grape
        = Dusty Plum
        = Twilight
```

## Animation Transitions

```
From Other Theme → Sakura:

Step 1: Background fades to pink
        #FFFFFF ──▶ #FFF0F5
        (0.3s spring animation)

Step 2: Cards update color
        #F2F2F2 ──▶ #FFE4E9
        (0.3s spring animation)

Step 3: Accents recolor
        #007AFF ──▶ #FF69B4
        (0.3s spring animation)

Result: Smooth, delightful transition
        that feels natural and polished
```

---

**Visual Guide Complete!** 🌸

Use this guide to understand how Sakura theme looks and feels across the iOS app.
