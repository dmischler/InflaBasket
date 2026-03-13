# UI Overhaul Plan — Matrix Neo-Cyberpunk Terminal

## Vision & Creative Direction
The "Matrix Neo-Cyberpunk Terminal" direction transforms InflaBasket into a high-tech decryption tool that reveals the hidden realities of macroeconomic decay. Glowing terminal aesthetics, stark monospace data, and subtle digital glitch effects frame the app as the red pill against the fiat matrix — empowering users to see Bitcoin as the definitive, uncorrupted standard.

## Design Philosophy & Emotional Impact
- Core aesthetic principles: Stark contrast, glowing neon accents, sharp geometric containers, visible grid lines, terminal-style data presentation.
- Emotional tone: Empowering, analytical, subversive, and highly secure — users feel like financial hackers uncovering hidden truths.
- Problem resolution: Replaces the generic accounting-app feel with a striking, gamified experience that makes inflation data undeniable and the premium AI scanner addictive.

## Updated Design System Foundations
- Color Palette:
  - Base: Void Black (#050505), Deep Terminal (#0A110F), Matrix Surface (#121A16)
  - Fiat (The Illusion): Glitch Magenta (#FF003C) + Cyan Wireframe (#00F0FF)
  - Bitcoin (The Truth): Satoshi Neon (#F28C0F) + Electric Gold (#FFDF00)
  - Terminal Primary: #00FF41 (Bright Green), #008F11 (Dim)
- Typography System:
  - UI/Headers: 'Rajdhani' or 'Share Tech Mono'
  - Data: 'JetBrains Mono' + 'Fira Code' (ligatures + tabular-nums)
- Elevation, Shadows, Spacing & Motion:
  - Flat with 1px neon borders + glowing box-shadow
  - Strict 8pt grid
  - Motion: Subtle CRT flicker, text-decoding animations, 60 fps spring physics

## Component Library Strategy
- Major redesigns: Sharp-edged terminal cards, glowing concentric FAB, oscilloscope-style fl_chart
- InflaBasket specifics: Speed Dial as locking concentric circles, receipt strips as printed terminal logs, StateMessageCard as blinking-cursor prompt

## Key Screen Overhauls
1. Dashboard & Macro Charts: Main command center with massive glowing balance + hardware-style toggle
2. Add Entry + AI Receipt Scanner: Targeting brackets + rapid “decoding” text effect on parse
3. History List & Receipt Review: Continuous scrolling server log with [OK]/[ERR] tags
4. Settings & Subscription Paywall: Framed as “Access Protocol Clearance” with encrypted nodes

## Safe Implementation Roadmap
**Phase 1**: Design Tokens + Core Components  
**Phase 2**: Navigation & Foundation Screens  
**Phase 3**: Advanced Components & Interactions  
**Phase 4**: Theming (Fiat/Bitcoin) + Accessibility (Reduce Motion toggle)  
**Phase 5**: Polish, Performance & Developer Handoff

## Risks & Mitigation Strategies
1. Motion sensitivity → Reduce Motion toggle + system preference respect  
2. Neon contrast → Core text always #FFFFFF or #E0E0E0; neon only for accents  
3. Scroll jank from glows → Limit complex shadows to static areas + CustomPaint fallback  
4. Alienating non-tech users → Standard UX patterns underneath the aesthetic

## Success Metrics
- 100% custom terminal widgets
- 0 WCAG AA violations + Reduce Motion support
- 60 fps guaranteed on mid-range devices
- 15–20% uplift in premium conversions + manual entries

## Appendix: Sample Token Preview
```css
/* Matrix Neo-Cyberpunk Tokens (2026 refined) */
:root {
  --bg-void: #050505;
  --neon-green: #00FF41;
  --fiat-magenta: #FF003C;
  --btc-orange: #F28C0F; /* deeper 2026 orange for comfort */
  --text-primary: #FFFFFF;
  --glow-green: 0 0 8px rgb(0 255 65 / 0.5);
}
[data-theme="bitcoin"] { --accent: var(--btc-orange); }