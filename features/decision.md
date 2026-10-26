---
type: DecisionLog
title: Architectural & Design Decisions
description: Authoritative log of architectural decisions, project constraints, and coding styles established for TodoCat across mobile and web.
tags: [decisions, architecture, coding-style, theme-rules, constraints]
status: active
last_updated: 2026-10-26
---

# Architectural & Design Decisions

## 1. Typography & Branding
- **Sniglet Font**: Universal rounded font for TodoCat across mobile and web platforms.

## 2. Color System & Theming
- **No Glowing/Neon Colors**: Avoid bright neon yellow, neon green (`#10B981`, `#22C55E`), or glowing red accents.
- **Theme Modes**:
  - **Light Mode Palette (Warm Cream & Peachy Ivory)**:
    - App Title: Deep warm charcoal-brown `#2B1D16`
    - Main screen background: Pale warm cream `#FDF2DD`
    - Cards / Elevated: Soft ivory/peachy cream `#F7E9DD`
    - Cat card / Home status banner: Pure white `#FFFFFF`
    - Task items & Profile cards: Pure white `#FFFFFF`
    - Selected status (All, Active, Completed): `#413025` (Text: `#FFF8E8`)
    - Add task button / FAB: `#413025` (Symbol/Text: `#FFF8E8`)
    - Primary text: Deep warm charcoal-brown `#2B1D16`
    - Secondary text: Muted warm brown `#8A7867`
    - Borders: Warm beige `#E8D9C2`
    - Search bar: Pale cream `#F8EEDF`
    - Inactive chips: Pure white `#FFFFFF`
    - Progress bar track: Pale beige `#EADCC6` (Fill: Soft amber `#FFC65C`)
    - Priority badge / Accent: Warm amber `#FFC65C`
    - Checkbox outline: Brown `#6F5A48`
    - Paw prints & trail: Taupe beige `#B49A83`
    - Kitten blush: Soft pink `#F4A6A0`
    - Bottom navigation: Pale cream `#FFF8E8`
    - Soft shadow: Warm grey-brown `#8C7860` at low opacity
  - **Dark Mode Palette (Carbon & Amber)**:
    - Background (`--bg`): `#0E0E0E`
    - Cards (`--card`): `#1A1A1A` (`--card-elevated`: `#222222`)
    - Search bar (`--search-bg`): `#1C1C1C`
    - Inactive chips (`--chip-bg`): `#242424`
    - Bottom navigation (`--nav-bg`): `#181818`
    - Primary text (`--text-primary`): `#F5F5F5`
    - Secondary text (`--text-secondary`): `#A6A6A6`
    - Borders (`--border`): `#353535`
    - Soft shadow (`--shadow`): `0 4px 16px rgba(0, 0, 0, 0.25)`
    - Accent / Priority / Progress fill (`--accent`): `#FFC65C`
    - Progress track (`--progress-track`): `#3A3A3A`
    - Active chip (`--active-chip`): `#F5F5F5` (`--active-chip-text`: `#0E0E0E`)
    - Paw prints & trail (`--paw`): `#777777`
    - Cat body (`--cat-body`): `#F5F5F5`, Kitten blush (`--cat-blush`): `#F4A6A0`
    - Floating action button (`--fab-bg`): `#F5F5F5` (`--fab-icon`: `#0E0E0E`)
- **Subtle Green / Sage Accents**:
  - For public productivity indicators, stats visibility switch, friend public stats badges, and public globe icons, use a muted whitish shade of green rather than bright/light green:
    - Dark mode: `Color(0xFFD4E7DC)` (subtle whitish sage green) with soft dark sage background `Color(0xFF1B241F)` and border `Color(0xFF2C3B32)`.
    - Light mode: `Color(0xFF476251)` (warm muted sage) with pale cream-sage background `Color(0xFFEDF3EE)` and border `Color(0xFFD8E4DC)`.
- **Centralized Palettes**:
  - All element colors must be defined in central palette registries: `app/lib/core/theme/app_colors.dart` (`AppPalette`, `AppColors`) on Mobile and `Web/lib/theme/colors.ts` on Web.
  - Adding a new color token requires defining paired values for both Light and Dark themes simultaneously.

## 3. Icons & Visual Assets
- **Outlined SVG Art**: All status indicators, priority icons, and common controls must use hand-drawn/rounded 2.2px outlined SVGs rather than solid fills or generic AI graphics.
- **Pure Outlined Status Badges**: Completed and Pending indicators render as outlined SVG icons without extraneous text labels.
- **Priority Indicators**: Pure outlined SVG art (flame for high, dual bars for medium, chevron for low) without text labels.
- **Handwritten Friend Request Actions**: Friend request accept (tick) and decline (cross) icons match handwritten Sniglet stroke aesthetics.

## 4. Multi-Platform Consistency
- Web (Next.js 16 + React 19 + Tailwind) and Mobile (Flutter 3.27+) must maintain full feature and visual token parity.
- Functions must not be duplicated within files or services; maintain modular reusable helpers.

## 5. In-App Notifications & Real-Time Alerts
- **Dual-Layer Delivery**: In-app notifications are delivered via FCM foreground listeners with an automatic real-time polling fallback (every 25s) so alerts work even if push permissions or Google Play Services are absent.
- **In-App Notification Banners**: Incoming friend requests and task updates display floating animated banners with direct action triggers ('View' button navigating to the relevant tab).
- **Navigation Badging**: Tab navigation items display pending count badges for unacknowledged events.

## 6. Android Home Screen Widgets & Floating Cat Overlay
- **Strict Theme Parity**: Native Android widgets (`todocat_list_widget`, `todocat_cat_widget`, `todocat_widget_small`, `todocat_widget_wide`) and system overlays (`FloatingCatService`, `QuickAddActivity`) must strictly mirror the centralized light and dark palette tokens:
  - **Light Mode**: widget background `#FDF2DD`, cards `#F7E9DD`, primary text `#2B1D16`, secondary text `#8A7867`, borders `#E8D9C2`, search/input `#F8EEDF`, checkbox outline `#6F5A48`, checked background `#2B1D16`, progress track `#EADCC6`, progress fill `#FFC65C`.
  - **Dark Mode**: widget background `#0E0E0E`, cards `#1A1A1A` / elevated `#222222`, primary text `#F5F5F5`, secondary text `#A6A6A6`, borders `#353535`, search/input `#1C1C1C`, checkbox outline `#353535`, checked background `#F5F5F5`, progress track `#3A3A3A`, progress fill `#FFC65C`.
- **Dynamic System Adaptation**: Handled via `Configuration.UI_MODE_NIGHT_MASK` and Flutter app preferences for real-time automatic theme switching across both native and Flutter UI components.
- **Rounded Widget Asset Clipping**: Android widgets enforce `android:clipToOutline="true"` and bottom artwork (`widget_cat_grass.png`, `grass.svg`) has pre-clipped transparent bottom corners (128px radius matching 24dp at widget scale) to guarantee that launcher RemoteViews render smoothly without square corner clipping artifacts.

## 7. Optimistic Task Deletion & 5-Second Undo
- **Delayed Deletion Pattern**: Task deletions across Mobile (Flutter) and Web (Next.js) are processed optimistically:
  - The task is immediately removed from the active list view and widget state.
  - An undo toast notification is displayed with an interactive "Undo" button for 5 seconds.
  - If the user triggers "Undo", the timer is cancelled and the task is immediately restored to its exact index without executing any backend DELETE request.
  - If 5 seconds elapse without undo, the permanent `DELETE /api/tasks/:id` request is executed.
  - Any pending deletions are flushed immediately upon app backgrounding/detach or window `beforeunload`.
