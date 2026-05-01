# Habitz - Light Theme Implementation

## 🎨 Design Overview

This project now uses a clean, minimal light theme inspired by a nursery habit tracker design. The old dark emotional theme system has been archived.

## Color Palette

### Base Colors
- **Background**: `#F5F5F0` - Warm cream/beige
- **Card Background**: `#FFFFFF` - Pure white
- **Text Primary**: `#1A1A1A` - Almost black
- **Text Secondary**: `#666666` - Medium gray
- **Text Hint**: `#999999` - Light gray
- **Shadow**: `#00000008` - Subtle shadow (5% opacity)

### Accent Colors (Pastels)
- **Mint Green**: `#C8E6C9` - For nature/health habits
- **Soft Blue**: `#BBDEFB` - For productivity habits
- **Peach Orange**: `#FFE0B2` - For creativity habits
- **Lavender Purple**: `#E1BEE7` - For mindfulness habits
- **Lemon Yellow**: `#FFF9C4` - For energy habits

### Interactive States
- **Selected**: `#2D5F5D` - Dark teal (for active day/habit)
- **Success**: `#4CAF50` - Green checkmark

## Typography

### Fonts
- **All Text**: Nunito (rounded, friendly sans-serif)
  - Headings: Bold (700 weight)
  - Subheadings: Semi-bold (600 weight)
  - Body: Regular (400 weight)

### Text Styles
- **Greeting**: 32px, Nunito Bold
- **Section Headers**: 18px, Nunito Bold
- **Habit Names**: 16px, Nunito Semi-bold
- **Body Text**: 14px, Nunito Regular
- **Captions**: 12px, Nunito Regular

## Layout Specifications

### Spacing
- **Page Padding**: 24px
- **Card Spacing**: 16px (between cards)
- **Card Padding**: 16px
- **Element Spacing**: 12px (within cards)

### Border Radius
- **Cards**: 16px
- **Icon Containers**: 12px
- **Checkboxes**: 6px

### Elevations
- **Cards**: 0 elevation (flat design with subtle shadow)
- **Shadow**: 0px 2px 8px with 5% opacity

## Component Structure

### Home Screen Components

1. **Header**
   - Greeting text: "Good morning, [Name]"
   - Date display
   - Clean white background with subtle shadow

2. **Week Calendar**
   - 7 day buttons (S M T W T F S)
   - Selected state: Dark teal background, white text
   - Unselected state: White background, gray text

3. **Habit Cards**
   - White background with subtle shadow
   - Pastel colored icon containers (left)
   - Habit name and streak counter
   - Completion checkbox (right)
   - Checkmark turns green when completed

4. **Bottom Navigation**
   - 5 tabs: Home, Habits, Profile, Stats, Settings
   - Selected tab: Dark teal color
   - Unselected tabs: Gray color

## File Structure

```
lib/
├── main.dart                          # App entry point (uses LightTheme)
├── core/
│   ├── routes/
│   │   └── app_router.dart           # Routes to HomeScreen
│   └── theme/
│       └── light_theme.dart          # Complete light theme definition
└── features/
    └── home/
        └── presentation/
            └── screens/
                └── home_screen.dart  # Main habit tracker screen
```

## Archived Files

The old dark emotional theme system has been moved to `.archive/old_dark_theme/`:
- `app_theme.dart` - Dark theme with 4 emotional states
- `app_states.dart` - Emotional state system (Tension/Survival/Momentum/Flow)
- `state_indicator.dart` - State-aware widgets
- `state_manager.dart` - State determination logic
- `emotional_states_demo.dart` - Demo screen for dark theme
- `EMOTIONAL_STATES.md` - Documentation for emotional states
- `STATE_THEME_SPECS.md` - Specifications for dark theme

## Running the App

```bash
flutter run
```

The app will launch with the new light theme showing:
- Week calendar with today highlighted
- Sample habits with pastel colored icons
- Clean, minimal interface matching the design screenshot

## Future Enhancements

- [ ] Implement actual habit tracking logic
- [ ] Add habit creation/editing screens
- [ ] Connect to backend/database
- [ ] Add statistics and charts
- [ ] Implement profile management
- [ ] Add settings screen
- [ ] Implement bottom navigation
- [ ] Add animations and transitions
- [ ] Implement streak tracking
- [ ] Add notifications/reminders
