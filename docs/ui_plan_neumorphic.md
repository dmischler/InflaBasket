UI Overhaul Plan — Sophisticated Neumorphic FinTech (The Standard Dichotomy)
Executive Summary
InflaBasket is not just an expense tracker; it is a lens into personal purchasing power against macroeconomic realities. This UI overhaul adopts a "Sophisticated Neumorphic FinTech" direction, intentionally designed to highlight the dichotomy between traditional fiat structures and the modern Bitcoin standard. By utilizing deep, trustworthy navy and muted gold tones for default fiat interactions, juxtaposed against vibrant, high-energy orange and sleek glassmorphic data panels for the Bitcoin view, the interface elevates an ordinary utility into a premium, eye-opening analytical tool. The tactile, soft-shadowed surfaces make manual data entry satisfying, while the sophisticated typography makes complex inflation indices instantly legible.
Design Philosophy

Core aesthetic approach and emotional tone: Tactile, soft-edged neumorphism paired with crisp glassmorphic overlays. The tone is authoritative, analytical, and highly responsive.
Why this specific direction solves current UI issues: The current flat Material 3 implementation lacks the premium, data-dense feel required to justify a paid subscription for AI receipts. Neumorphic cards provide a satisfying "physical" boundary for receipt items, while glass overlays allow complex macro-charts (CPI/M2) to float elegantly above the data without causing visual clutter.
Key improvements over the existing interface: Eliminates "generic app" syndrome. Introduces the highly requested visual contrast between Fiat (classic finance) and Bitcoin (future finance) directly into the token architecture, making the toggle a dramatic, app-wide environmental shift rather than a simple unit change.
Updated Design System Foundations
Color Palette:
  - Fiat Mode (Default): Navy Blue (#0F172A) backgrounds, muted Gold (#D97706) accents, and crisp Slate (#64748B) secondary text.
  - Bitcoin Mode (Active): Deep Charcoal (#121212), high-visibility Bitcoin Orange (#F7931A), and bright neon accents for data visualization.
  - Semantic: Desaturated emerald (#10B981) for deflation, soft crimson (#EF4444) for inflation/price spikes.
Typography Scale and Hierarchy:
  - Primary (Headers/UI): Inter (weights: 400, 500, 600) for clean readability.
  - Secondary (Data/Prices/Indices): JetBrains Mono (weights: 500, 700) to align decimals perfectly and give a "terminal/trading desk" feel to the analytics.
Spacing, Elevation, Shadows, and Motion System:
  - Spacing: Strict 8-point system (8, 16, 24, 32, 48).
  - Elevation: Replaces flat borders with subtle double-shadows (a light highlight on top-left, dark shadow on bottom-right) to create extruded components.
  - Motion: Physics-based spring animations for all transitions, particularly the HistoryList swipe-to-delete and the expanding Speed Dial FAB.
Component Library Strategy
Major component updates and new additions:
  - Neumorphic Data Cards: Used for the StateMessageCard and History items. They appear slightly raised from the background, depressing into an "inset" state when tapped.
  - Glassmorphic Bottom Nav & Modal Sheets: The bottom navigation and filter bottom-sheets will use heavy background blur (backdrop-filter: blur(16px)) with a semi-transparent tint, maximizing screen real estate.
  - Animated Speed Dial FAB: Replaces the static add button with an expandable, animated FAB separating "Manual Entry" and "Scan Receipt".
Interaction patterns, micro-animations, and state handling:
  - Haptic Feedback: Distinct vibration patterns for typing on the calculator, saving an entry, or toggling the Bitcoin Standard mode.
  - Skeleton Loaders: Pulsing, soft-edged blocks replacing circular spinners during AI receipt parsing to maintain layout stability.
Key Interface Overhauls


Dashboard & Overview Chart (/home):
   - The chart area becomes an edge-to-edge glassmorphic panel. The lines for CPI/M2 overlays will glow with a subtle drop-shadow (box-shadow in CSS / Shadow in Flutter's Paint).
   - A dramatic, physics-based toggle switch at the top right for "Fiat / Sats", which seamlessly morphs the entire color scheme when activated.
Add Entry & AI Receipt Scanner (/home/add & /scanner):
   - The manual entry form adopts inset neumorphic fields (looking "carved" into the screen).
   - The AI receipt processing screen gets a high-tech "scanning" laser animation overlaying the image, creating anticipation and justifying the premium feature.
Per-Item Receipt Review Dialog (_ReceiptReviewDialog):
   - Redesigned as a paginated or tightly scrollable list of physical-looking "receipt strips."
   - Price anomalies highlight with a pulsing red outline, demanding user verification before saving.
Settings & Paywall (/settings & /paywall):
   - The Paywall becomes an immersive, dark-themed glass modal highlighting the AI features with premium gold or orange gradients (depending on the active standard), emphasizing the value of upgrading.
Safe Implementation Roadmap
Phase 1: Design System Foundation (tokens + core components)


Translate CSS/Figma tokens into Flutter ThemeData and ThemeExtension.
Build the base neumorphic container widgets and glassmorphic wrappers without replacing existing UI.
Phase 2: Core Screens & Navigation
Replace the default NavigationBar with the new floating glassmorphic nav.
Apply the new token system to HistoryTab and CategoriesTab, ensuring JetBrains Mono is applied to all numerical data.
Phase 3: Advanced Components & Interactions
Overhaul the DashboardScreen charts with the new glowing visuals and responsive touch tooltips.
Implement the "Speed Dial" FAB and the "Fiat vs. Bitcoin" app-wide theme toggle logic.
Phase 4: Dark Mode, Polish & Full Accessibility Audit
Refine the contrast ratios of the neumorphic shadows (ensuring WCAG AA compliance even with soft edges).
Integrate custom lottie/rive animations for empty states (StateMessageCard).
Phase 5: Developer Handoff, QA & Testing
Final visual QA against both iOS and Android (and desktop Linux) to ensure shaders and blurs render performantly.
Verify that fl_chart tooltips and boundaries haven't broken due to new padding constraints.
Risks & Mitigation Strategies
Risk: Neumorphism often fails WCAG AA contrast requirements due to low-contrast shadow boundaries.
  - Mitigation: We will strictly use neumorphism for container boundaries, but ensure all text, icons, and interactive focus states use high-contrast primary/secondary tokens (minimum 4.5:1).
Risk: Heavy glassmorphism (BackdropFilter) can cause frame drops on older Android devices or Linux desktop.
  - Mitigation: Implement a performance-tier check. If the device struggles, gracefully degrade the blur to a flat, semi-transparent color overlay.
Risk: Breaking existing Drift data inputs with new UI paradigms.
  - Mitigation: UI components will perfectly wrap the existing Riverpod controllers (AddEntryController, VisionClient). No underlying state logic will be altered during the UI refactor.
Success Metrics
Aesthetic Consistency: 100% of numerical data uses the monospaced font system.
Accessibility: 100% pass rate on WCAG AA contrast checks for text and critical icons.
Conversion: A measurable 15%+ increase in premium conversions on the new Paywall UI.
Performance: Zero UI jank (maintaining 60fps) during the AI scanner transitions and History list scrolling.
Appendix: Sample Token Preview
(Note: These structural design tokens are defined in CSS for platform-agnostic handoff, to be mapped directly to Flutter's ThemeExtension)
/* Design Token System: Sophisticated Neumorphic FinTech */
:root {
  /* Fiat Standard (Default) Tokens */
  --color-bg-base: #F1F5F9;
  --color-surface: #E2E8F0;
  --color-primary: #0F172A;
  --color-accent: #D97706; /* Muted Gold */
 
  --color-text-main: #0F172A;
  --color-text-data: #334155;
 
  /* Neumorphic Shadows (Light Mode) */
  --shadow-neumorphic-out:
    6px 6px 12px rgba(163, 177, 198, 0.6),
    -6px -6px 12px rgba(255, 255, 255, 0.8);
  --shadow-neumorphic-in:
    inset 4px 4px 8px rgba(163, 177, 198, 0.6),
    inset -4px -4px 8px rgba(255, 255, 255, 0.8);
   
  /* Glassmorphism */
  --glass-bg: rgba(226, 232, 240, 0.65);
  --glass-border: 1px solid rgba(255, 255, 255, 0.4);
  --glass-blur: blur(12px);
  /* Typography */
  --font-ui: 'Inter', system-ui, sans-serif;
  --font-data: 'JetBrains Mono', monospace;
  --transition-spring: 500ms cubic-bezier(0.175, 0.885, 0.32, 1.275);
}
/* Bitcoin Standard (Active) Tokens */
[data-theme="bitcoin"] {
  --color-bg-base: #0F0F0F;
  --color-surface: #1A1A1A;
  --color-primary: #F7931A; /* BTC Orange */
  --color-accent: #10B981; /* Neon Green for positive sats purchasing power */
 
  --color-text-main: #F8FAFC;
  --color-text-data: #E2E8F0;
 
  /* Neumorphic Shadows (Dark Mode) */
  --shadow-neumorphic-out:
    4px 4px 10px rgba(0, 0, 0, 0.8),
    -4px -4px 10px rgba(45, 45, 45, 0.5);
  --shadow-neumorphic-in:
    inset 4px 4px 10px rgba(0, 0, 0, 0.8),
    inset -4px -4px 10px rgba(45, 45, 45, 0.5);
   
  /* Glassmorphism */
  --glass-bg: rgba(26, 26, 26, 0.65);
  --glass-border: 1px solid rgba(247, 147, 26, 0.15);
}
/* Base Component Applications */
.data-card {
  background-color: var(--color-surface);
  border-radius: 20px;
  box-shadow: var(--shadow-neumorphic-out);
  transition: all var(--transition-spring);
}
.data-card:active {
  box-shadow: var(--shadow-neumorphic-in);
}
.inflation-index-text {
  font-family: var(--font-data);
  font-weight: 700;
  color: var(--color-primary);
  letter-spacing: -0.05em;
}
.glass-nav-bar {
  background: var(--glass-bg);
  backdrop-filter: var(--glass-blur);
  -webkit-backdrop-filter: var(--glass-blur);
  border-top: var(--glass-border);
}