---
name: Terminal Utility Archetype
colors:
  surface: '#0b141c'
  surface-dim: '#0b141c'
  surface-bright: '#313a43'
  surface-container-lowest: '#060f16'
  surface-container-low: '#141c24'
  surface-container: '#182028'
  surface-container-high: '#222b33'
  surface-container-highest: '#2d363e'
  on-surface: '#dae3ee'
  on-surface-variant: '#c0c7d4'
  inverse-surface: '#dae3ee'
  inverse-on-surface: '#29313a'
  outline: '#8b919d'
  outline-variant: '#414752'
  surface-tint: '#a2c9ff'
  primary: '#a2c9ff'
  on-primary: '#00315c'
  primary-container: '#58a6ff'
  on-primary-container: '#003a6b'
  inverse-primary: '#0060aa'
  secondary: '#67df70'
  on-secondary: '#00390d'
  secondary-container: '#27a640'
  on-secondary-container: '#00320a'
  tertiary: '#fabc45'
  on-tertiary: '#422c00'
  tertiary-container: '#d29922'
  on-tertiary-container: '#4d3500'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#d3e4ff'
  primary-fixed-dim: '#a2c9ff'
  on-primary-fixed: '#001c38'
  on-primary-fixed-variant: '#004882'
  secondary-fixed: '#83fc89'
  secondary-fixed-dim: '#67df70'
  on-secondary-fixed: '#002105'
  on-secondary-fixed-variant: '#005317'
  tertiary-fixed: '#ffdeaa'
  tertiary-fixed-dim: '#fabc45'
  on-tertiary-fixed: '#271900'
  on-tertiary-fixed-variant: '#5f4100'
  background: '#0b141c'
  on-background: '#dae3ee'
  surface-variant: '#2d363e'
typography:
  headline-lg:
    fontFamily: Geist
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Geist
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.015em
  headline-sm:
    fontFamily: Geist
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Geist
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 22px
    letterSpacing: 0em
  body-md:
    fontFamily: Geist
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
    letterSpacing: 0em
  body-sm:
    fontFamily: Geist
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
    letterSpacing: 0em
  code-lg:
    fontFamily: JetBrains Mono
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 18px
    letterSpacing: -0.01em
  code-md:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
    letterSpacing: 0em
  code-sm:
    fontFamily: JetBrains Mono
    fontSize: 11px
    fontWeight: '400'
    lineHeight: 14px
    letterSpacing: 0em
  label-md:
    fontFamily: Geist
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: JetBrains Mono
    fontSize: 10px
    fontWeight: '600'
    lineHeight: 12px
    letterSpacing: 0.05em
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  space-2xs: 2px
  space-xs: 4px
  space-sm: 8px
  space-md: 12px
  space-lg: 16px
  space-xl: 20px
  space-2xl: 24px
  space-3xl: 32px
  gutter-screen: 12px
  gutter-terminal: 8px
---

## Brand & Style

This design system is engineered for infrastructure engineers, backend specialists, and site reliability operators who need high-signal, immediate command capabilities in mission-critical environments. Built to eliminate cognitive friction during on-call triages and remote incident response, the aesthetic prioritizes information density, legibility under pressure, and precise execution over decorative fluff.

The visual posture draws inspiration from modern developer workbenches and classic command-line utilities. It balances utilitarian minimalism with structural precision: ultra-crisp 1px border demarcations, tight content packing, explicit status indicators, and clear mechanical tactile states. The emotional impact is calm, controlled, authoritative, and deterministic—instilling absolute confidence in destructive, read-heavy, and operational workflows alike.

## Colors

The system is constructed with a dark-first philosophy modeled after deep terminal spaces and low-light operations. Contrast meets strict accessibility thresholds while avoiding harsh pure-white and pure-black glare.

### Surface System
- **Base Canvas (`#0d1117`):** The primary root application background behind all list views, sheets, and terminal viewports.
- **Surface Level 1 (`#161b22`):** Primary card surfaces, top app bars, bottom navigation panels, and persistent toolbars.
- **Surface Level 2 (`#21262d`):** Nested containers, inner terminal command buffers, chip backgrounds, and input wells.
- **Surface Level 3 (`#30363d`):** Active selections, row hover/pressed states, and primary divider/border lines.

### Functional Accents & Semantic States
- **Primary Accent (`#58a6ff`):** Interactive focal points, links, active terminal tokens, and selection indicators.
- **Success / Healthy (`#238636` dark base, `#3fb950` bright foreground):** Active nodes, operational services, low latencies, and valid SSH handshakes.
- **Warning / Degraded (`#d29922`):** CPU throttling, memory spikes, untrusted fingerprints, and non-blocking sync warnings.
- **Error / Critical (`#da3633` dark base, `#f85149` bright foreground):** Dropped connections, process halts, unresponsive ports, and destructive confirmation barriers.
- **Muted Content (`#8b949e`):** Secondary metadata, timestamps, port numbers, and inactive parameters.
- **High-Contrast Text (`#f0f6fc`):** Primary command labels, server identifiers, and primary logs.

## Typography

The typographic hierarchy implements a high-efficiency dual pairing: **Geist** for crisp, scalable structural UI labels and headings, and **JetBrains Mono** for all technical outputs, including IP addresses, timestamps, hash fingerprints, key-value configurations, and terminal streams.

### Hierarchy & Application Rules
- **Display & Section Headers:** Use compact, tight tracking (`-0.02em` to `-0.01em`) to preserve screen real estate on mobile screens while anchoring complex dashboards.
- **Technical Outputs & Metas:** All port designations (e.g., `:22`, `:443`), memory sizes (`16GiB`), latencies (`14ms`), and system addresses must use `JetBrains Mono` at `code-md` or `code-sm`.
- **Labels:** Micro status badges, protocol chips (e.g., `SSH`, `SFTP`, `MOSH`), and tag indicators enforce uppercase styling via `label-sm` with widened tracking (`0.05em`).

## Layout & Spacing

This design system uses a strict **4px baseline rhythm** optimized for high-density mobile displays. Layouts lean on fluid column containment bounded by fixed edge gutters to maximize visible screen space on handheld devices.

### Density & Compact Layout Principles
- **Screen Margins:** Fixed at `12px` (standard) or `8px` (terminal viewports) to avoid wasted lateral margin on small screens.
- **Card Spacing:** Rows within a group use `2px` to `4px` inner gap spacing or simple `1px` rule dividers without margins.
- **Touch Bounds vs. Visual Bounds:** Visual elements can sit as compact as `28px` to `32px` in height, but hit-test areas must span a minimum of `44px` vertically using transparent hit-box expansion (`HitTestBehavior.translucent` in Flutter) to ensure accurate, rapid thumb tapping during emergency interventions.
- **Breakpoints:**
  - `Mobile Compact` (< 360dp): Reduces gutters to `8px`, collapses sub-metadata into single-line overflow truncations.
  - `Mobile Standard` (360dp – 480dp): Default layout with two-tier metric telemetry lines.
  - `Tablet / Foldable Expanded` (> 480dp): Splits into master-detail side-by-side terminal session panels with pinned server monitors.

## Elevation & Depth

This design system rejects heavy, blurred drop shadows in favor of **Tonal Layering** accompanied by **Subtle 1px Borders**. Depth indicates contextual priority and operational focus rather than physical loft.

### Depth Hierarchy
1. **Level 0 (Canvas):** `#0d1117` base. Flat, zero elevation.
2. **Level 1 (Card & Module Layer):** `#161b22` fill with a crisp `1px` border of `#30363d`. No drop shadow.
3. **Level 2 (Active/Pressed or Nested Group):** `#21262d` fill with `#30363d` or `#58a6ff` (when focused) border outline.
4. **Floating Overlays & Action Bars:** Command palettes, contextual drop-downs, and sticky virtual keys sit on `#161b22` with a `1px` border of `#30363d` and a controlled, dark tint ambient shadow (`box-shadow: 0 8px 24px rgba(1, 4, 9, 0.75)`).
5. **Backdrop Overlays:** Modal dismiss scrims utilize `#010409` at `70%` opacity to keep focused modals in sharp contrast.

## Shapes

The shape system leverages a clean, precise **Soft (`1`)** radius geometry. Rounding is intentionally restrained to maintain an industrial, developer-tool look.

### Radius Assignments
- **Corner Micro (2px):** Metric bars, internal status dots, and inline code tags.
- **Corner Small (4px):** Standard buttons, input wells, virtual terminal keys, and protocol badges.
- **Corner Base (6px):** Server list cards, telemetry charts, container blocks, and bottom sheets.
- **Corner Full (Pill / 999px):** Exclusively reserved for status dots (`8px` diameter) and compact live ping indicators.

## Components

### Buttons
- **Primary Action:** Solid background (`#238636` for standard execute/deploy, `#58a6ff` for system actions), `#f0f6fc` text, `4px` radius, `36px` height. Flat without shadow, transitions to active brightness on press.
- **Secondary Action:** Transparent fill, `1px` border `#30363d`, text `#f0f6fc`. Pressed state sets background to `#21262d`.
- **Destructive Action:** Transparent fill with `1px` border `#da3633`, text `#f85149`. Confirmed states flash to `#da3633` background with white text.
- **Compact Keyboard/Key Bar Buttons:** Height `32px`, background `#21262d`, border `#30363d`, text in `JetBrains Mono` (`#f0f6fc`).

### Status Dots & Badges
- **Status Dot:** Exact `8px × 8px` circular indicator. Active healthy: `#3fb950` with an optional 2px `#238636` glow border; Warning: `#d29922`; Down: `#f85149`.
- **Protocol Chip:** Height `20px`, padding `0 6px`, radius `3px`. Fill `#21262d`, border `1px solid #30363d`, text `JetBrains Mono` (`10px` uppercase).

### Server List Row Item
- **Layout:** Two-row dense card. Top row contains Status Dot (`8px`), Hostname (`Geist Medium 14px`), and latency badge (`JetBrains Mono 11px`). Bottom row contains IP address (`JetBrains Mono 12px`, `#8b949e`), active SSH user, and load average gauges.
- **Borders:** Separated by a single `1px` solid line (`#21262d`) inside a continuous `#161b22` container.

### Inputs & Terminal Shell Fields
- **Fields:** Fill `#0d1117`, border `1px solid #30363d`, active focus border `1px solid #58a6ff`. Zero glow/bloom. Monospaced input text (`#f0f6fc`), placeholder text (`#8b949e`).
- **Terminal Viewport:** Background `#0d1117` edge-to-edge, zero radius, mono text with hardware-accelerated rendering.

### Selection Controls
- **Checkboxes & Radios:** Square/circular with `1px solid #30363d`, `16px` size. Checked state uses fill `#58a6ff` with white icon mark.
- **Toggles:** Ultra-compact `36px × 20px` track with `#21262d` inactive fill and `#238636` active fill; `16px` white thumb with zero springiness for instant mechanical snap.