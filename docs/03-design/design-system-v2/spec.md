---
name: Tanukonomy
colors:
  surface: '#f9f9f8'
  surface-dim: '#dadad9'
  surface-bright: '#f9f9f8'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f4f3'
  surface-container: '#eeeeed'
  surface-container-high: '#e8e8e7'
  surface-container-highest: '#e2e2e2'
  on-surface: '#1a1c1c'
  on-surface-variant: '#414941'
  inverse-surface: '#2f3130'
  inverse-on-surface: '#f1f1f0'
  outline: '#727971'
  outline-variant: '#c1c9bf'
  surface-tint: '#3c6846'
  primary: '#043417'
  on-primary: '#ffffff'
  primary-container: '#1f4b2c'
  on-primary-container: '#8bba93'
  inverse-primary: '#a2d2a9'
  secondary: '#54615a'
  on-secondary: '#ffffff'
  secondary-container: '#d8e6dc'
  on-secondary-container: '#5a6760'
  tertiary: '#2f2c25'
  on-tertiary: '#ffffff'
  tertiary-container: '#46423a'
  on-tertiary-container: '#b4aea4'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#bdefc4'
  primary-fixed-dim: '#a2d2a9'
  on-primary-fixed: '#00210c'
  on-primary-fixed-variant: '#244f30'
  secondary-fixed: '#d8e6dc'
  secondary-fixed-dim: '#bccac0'
  on-secondary-fixed: '#121e18'
  on-secondary-fixed-variant: '#3d4a42'
  tertiary-fixed: '#e8e2d7'
  tertiary-fixed-dim: '#ccc6bb'
  on-tertiary-fixed: '#1e1b15'
  on-tertiary-fixed-variant: '#4a463f'
  background: '#f9f9f8'
  on-background: '#1a1c1c'
  surface-variant: '#e2e2e2'
typography:
  display-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 44px
    fontWeight: '700'
    lineHeight: 52px
    letterSpacing: -0.03em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.025em
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 26px
    fontWeight: '600'
    lineHeight: 34px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.02em
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 26px
    letterSpacing: -0.015em
  title-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 26px
    letterSpacing: -0.005em
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 22px
    letterSpacing: 0em
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
    letterSpacing: 0.005em
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.04em
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.06em
  numerical-display:
    fontFamily: Plus Jakarta Sans
    fontSize: 36px
    fontWeight: '600'
    lineHeight: 44px
    letterSpacing: -0.03em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1.5rem
  gutter-mobile: 1rem
  margin: 3rem
  margin-mobile: 1.25rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2.5rem
---

## Brand & Style
The design system channels an interplay of modern Japanese spatial reduction (Ma) and precision fintech craft. It targets mindful individuals, independent professionals, and modern consumers who demand clarity, emotional calm, and purposeful discipline over their personal economy. 

The aesthetic is built on ultra-clean minimalism with high-end editorial restraint:
- **Atmospheric Clarity**: Pure canvas space prioritized over visual ornamentation. Elements breathe with intentional pacing.
- **Precision Architecture**: Micro-borders (1px hairline precision), razor-sharp data displays, and disciplined tabular alignment replace muddy fills and heavy cards.
- **Understated Tactility**: Tactile interactions are soft, crisp, and swift (150ms transitions), reminiscent of precise Japanese stationery and high-grade industrial hardware.
- **Restraint Over Decoration**: Zero decorative shadows or loud illustrative noise. Value is communicated through typography, pristine contrast ratios, and deliberate matcha green focal points.

## Colors
The palette pairs the tactile purity of Japanese rice-paper and warm mist tones with deep forest matcha green and balanced charcoal typography.

### Palette Architecture
- **Primary (`#1F4B2C`)**: Refined Forest Matcha Green. Used strictly for high-intent interactive states, confirmed financial balances, primary actions, and pivotal balance indicators.
- **Secondary (`#D8E6DC`)**: Soft Sage Tint. Applied as an ultra-light contextual surface tint, subtle pill backgrounds, and positive delta callouts.
- **Tertiary (`#F4EDE2`)**: Pale Warm Champagne. Reserved for secondary micro-badges, category tags (e.g., hospitality, living), and subtle warning accents.
- **Neutral Canvas (`#FAFAF9`)**: Warm mist canvas tint that softens glare without muddying contrast. Card and elevated surfaces rest upon crisp `#FFFFFF`.
- **Text & Border Hierarchy**:
  - `text-primary`: `#111827` (Deep Obsidian Ink)
  - `text-secondary`: `#4B5563` (Muted Slate)
  - `text-tertiary`: `#9CA3AF` (Refined Ash)
  - `border-hairline`: `#EAECEF` (Subtle 1px micro-border)
  - `border-focus`: `#1F4B2C`

## Typography
Plus Jakarta Sans provides geometric modernity, balanced counters, and human warmth. 

- **Numeric Treatment**: Enable tabular lining figures (`font-variant-numeric: tabular-nums lining-nums`) across all expense tables, ledger entries, metric monitors, and balances to maintain strict vertical column alignment.
- **Letter Spacing**: Tighter negative tracking (`-0.02em` to `-0.03em`) on titles and displays enhances structural cohesion, while labels and micro-metadata employ positive tracking (`0.04em` to `0.06em`) for legibility in dense financial contexts.
- **Line Heights**: Generous leading in editorial summaries contrasts against tight, rhythmically locked line heights in tabular views.

## Layout & Spacing
The layout follows an 8-point rhythmic grid with a 12-column desktop structure that scales gracefully down to 4 columns on mobile viewports.

### Breakpoints & Geometry
- **Mobile (< 640px)**: 4-column layout, `margin-mobile` (1.25rem), `gutter-mobile` (1rem). Financial logs stack vertically into modular cards; secondary columns (e.g., category chips, timestamps) collapse into subtitled metadata.
- **Tablet (641px - 1024px)**: 8-column layout, 2rem margins, 1.25rem gutters. Split panels introduce a persistent side-drawer for ledger categorization.
- **Desktop (> 1025px)**: 12-column layout, `margin` (3rem), `gutter` (1.5rem), maximum content constraint capped at 1280px for optimal visual scanning.

### Spatial Rhythm
Prioritize generous macro-whitespace (`space-xl` / 40px) between major architectural regions (e.g., monthly summary vs. real-time feed), paired with disciplined micro-spacing (`space-xs` and `space-sm`) inside interactive components to reflect Japanese craftsmanship.

## Elevation & Depth
This design system avoids heavy drop shadows, skeuomorphic bevels, and artificial drop glows. Visual depth is established purely through micro-borders and high-precision tonal layering.

- **Surface Layering**:
  - **Base Canvas**: Neutral Warm Mist (`#FAFAF9`).
  - **Surface Container (Level 1)**: Pure White (`#FFFFFF`) with a 1px solid `#EAECEF` perimeter border.
  - **Surface Overlay (Level 2 / Popovers, Modals)**: Pure White (`#FFFFFF`) framed with a 1px `#E2E5E9` border and a barely perceptible ambient aura (`0 8px 24px -4px rgba(17, 24, 39, 0.04)`).
- **Interactive State Elevation**: Hover and active states do not lift physical elevation; instead, they shift border luminescence (transitioning from `#EAECEF` to `#1F4B2C`) or invoke a micro-fill transition to `#F4F6F4`.
- **Dividers & Hairlines**: All divider lines utilize a 1px solid stroke with `#EAECEF` to construct clean editorial frameworks.

## Shapes
Geometry is engineered with calibrated roundedness (`roundedness: 2` — default `0.5rem` / 8px) to establish a balance between Swiss-inspired structure and organic minimalism:

- **Standard Containers & Inputs**: 8px (`0.5rem`) for form inputs, interactive cells, standard buttons, and data widgets.
- **Cards & Data Groups**: 16px (`1rem` / `rounded-lg`) for major financial summary panels and chart containers.
- **Modal Sheets & Overlays**: 24px (`1.5rem` / `rounded-xl`) on desktop, or 20px top-radius on mobile bottom sheets.
- **Badges, Tags & Transaction Avatars**: Complete pill radii (`9999px`) to cleanly demarcate status indicators and category metadata against rectilinear containers.

## Components

### Buttons
- **Primary Button**: Solid Forest Matcha (`#1F4B2C`) background with pure white text (`#FFFFFF`). `rounded: 0.5rem`, padding `0.625rem 1.25rem`. Transitions smoothly on hover to `#163720`.
- **Secondary Button**: Crisp `#FFFFFF` surface with a 1px `#EAECEF` border and `#111827` text. On hover, background shifts to `#F8F9FA` and border darkens to `#D1D5DB`.
- **Ghost/Tertiary Button**: No border or background; `#4B5563` text. On hover, subtle `#F3F4F6` background tint.

### Badges & Category Chips
- **Format**: Pill-shaped (`rounded-full`), padding `0.25rem 0.625rem`, typography set to `label-md`.
- **Positive Delta / Income**: Soft Sage background (`#D8E6DC`) paired with deep matcha ink (`#1F4B2C`).
- **Discretionary / Living**: Pale Warm Champagne background (`#F4EDE2`) paired with refined bistre ink (`#5C4D3C`).
- **Neutral / Internal**: Pure `#FFFFFF` background with 1px `#EAECEF` border and `#4B5563` text.

### Inputs & Financial Entry Fields
- **Standard Field**: 1px `#EAECEF` border on `#FFFFFF` base, 8px radius. Text `#111827`, placeholder `#9CA3AF`. On focus, transitions to a crisp 1px ring of `#1F4B2C` without aggressive glowing drop-shadows.
- **Amount Quick-Entry**: Borderless inline field utilizing `numerical-display` sizing. The currency symbol sits locked in `#9CA3AF` with value input styled in `#111827`.

### Financial Transaction Rows & Lists
- **Structure**: Clean 1-row spatial block. Left-aligned category avatar (subtle monochromatic or matcha-tinted 36px icon container), title in `title-md`, timestamp in `body-sm` (`#9CA3AF`).
- **Right Alignment**: Tabular-figure numerical amounts. Expense entries in `#111827`, income credits in `#1F4B2C`.
- **Separators**: 1px subtle divider (`#EAECEF`) between entries, extending from the text margin rather than edge-to-edge.

### Cards & Metrics Panels
- **Container**: White `#FFFFFF` foundation enclosed by a 1px `#EAECEF` micro-border, 16px radius, `1.5rem` internal padding.
- **Header Structure**: Minimalist section label (`label-md` uppercase in `#9CA3AF`) paired with micro-period selectors.
- **Value Reveal**: High-impact metrics using `headline-lg` or `numerical-display`, anchored with contextual delta chips directly below.

### Checkboxes & Segmented Controls
- **Checkboxes**: Crisp 16px squares with 4px corners, 1px `#D1D5DB` borders. Checked state fills with `#1F4B2C` featuring a pure white micro-checkmark.
- **Segmented Time Filters (Day / Week / Month / Year)**: Contained inside a light mist container (`#F3F4F6`), each segment has 6px radius. Selected segment is `#FFFFFF` with 1px hairline border `#EAECEF` and obsidian typography.