# Habitz - Project Context

## Project Vision
> "This is not a productivity app. This is not a wellness tracker. This is a private space where commitment feels real."

Habitz (internal name 'space') is an emotional habit tracker designed for Gen-Z users, couples, and small groups who value intimacy and commitment over traditional gamification and productivity metrics.

## Core Value
The application uses a unique **Emotional State Design System** to communicate the status of habits and group synchronization:
- 🔴 **Tension**: Something is pending; waiting on a partner.
- 🟣 **Survival**: Showing up for the bare minimum.
- 🟡 **Momentum**: Maintaining a consistent rhythm.
- 🟢 **Flow**: Full synchronization and collective achievement.

## Target Audience
- **Gen-Z** (18-27): Appreciating intimacy, privacy, and curated aesthetics.
- **Couples**: Building habits together with partner-awareness features.
- **Small Groups**: Shared goals in a private setting.
- **Commitment-Oriented Users**: Those who prefer psychological depth over "confetti" gamification.

## Requirements

### Validated
- ✓ **Industry-Standard BLoC Architecture**: Clean architecture with BLoC/Cubit state management.
- ✓ **Supabase Integration**: Auth and database services implemented.
- ✓ **Emotional State System**: Visual language (vignettes, pulses, bursts) and haptic feedback mapped to states.
- ✓ **State-Aware UI Components**: Adapting icons, buttons, and cards.
- ✓ **Brand Discovery / Search**: Gen Z-style editorial UI for discovering brand spaces and challenges.

### Active
- [ ] **Full Brand Challenge Integration**: Closing the loop on backend RPC responses and Flutter models.
- [ ] **Unified Search Experience**: Providing consistent results across spaces, friends, and brands.
- [ ] **UX Polish**: Resizing UI components for proportional balance and removing high-intensity visual overloads.
- [ ] **Refactored Dashboard**: Streamlining the 'Today' view and removing redundant "Other Habits" sections.

### Out of Scope
- [ ] **Public Social Feed**: Generic likes/comments/feeds are excluded to maintain intimacy.
- [ ] **Ad-Driven Monetization**: Focus is on premium, ad-free brand discovery and private utility.

## Key Decisions
| Decision | Rationale | Outcome |
|----------|-----------|---------|
| **Feature-Based Structure** | Improves isolation and parallel development for a multi-faceted app. | Implemented |
| **Supabase as BaaS** | Fast iteration with RPC support for complex multi-user logic. | Implemented |
| **GSD Workflow** | Moving from "vibe coding" to production-grade systematic execution. | Initialized |

## Evolution
This document evolves at phase transitions and milestone boundaries.

**After each phase transition:**
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions

---
*Last updated: 2026-04-11 after GSD initialization*
