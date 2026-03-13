UI Overhaul Plan — Matrix Neo-Cyberpunk Terminal
Vision & Creative Direction
The "Matrix Neo-Cyberpunk Terminal" direction leans heavily into InflaBasket’s rebellious, anti-fiat undertones. It frames the application not merely as a tracker, but as a high-tech decryption tool revealing the hidden realities of macroeconomic decay. By combining glowing terminal aesthetics, stark monospace data, and subtle digital glitch effects, the interface empowers users to see through the "fiat matrix" and recognize Bitcoin as the definitive, uncorrupted standard of value. 
Design Philosophy & Emotional Impact
- Core aesthetic principles: Stark contrast, glowing neon accents, sharp geometric containers, visible grid lines, and terminal-style data presentation.
- Emotional tone: Empowering, analytical, subversive, and highly secure. It should make the user feel like a financial hacker uncovering hidden truths.
- Problem Resolution: Replaces the generic "accounting app" feel with a striking, gamified experience. The strong visual hierarchy uses high-contrast typography to make inflation data undeniably clear, while the premium experience is delivered through fluid, high-framerate micro-interactions and custom shader effects rather than traditional luxury tropes.
Updated Design System Foundations
- Color Palette:
  - Base Backgrounds: Void Black (#050505), Deep Terminal (#0A110F), Matrix Surface (#121A16).
  - Terminal Green (Primary):  #00FF41 (Bright), #008F11 (Dim).
  - Fiat Mode (The Illusion): Glitch Magenta (#FF003C), Cyan Wireframe (#00F0FF).
  - Bitcoin Mode (The Truth): Satoshi Neon (#F7931A), Electric Gold (#FFDF00).
  - Error/Inflation Alert: Critical Red (#FF2A2A).
- Typography System:
  - Primary UI/Headers: 'Rajdhani' or 'Share Tech' (technical, squared-off sans-serif).
  - Data/Monospace: 'JetBrains Mono' or 'Fira Code' with ligatures for all numeric data and cryptographic hashes.
  - Scale: Standardized 8pt scale (12px micro, 14px base, 16px lead, 24px header, 36px macro-data).
- Elevation, Shadows, Spacing & Motion: 
  - Elevation: Flat surfaces defined by 1px bright borders rather than drop shadows.
  - Shadows: "Neon glow" (box-shadow with high spread, low opacity matching the border color) instead of traditional directional shading.
  - Motion: CRT flicker on screen load, subtle text decoding animations (random characters resolving to numbers), and smooth ease-out transitions for charts.
Component Library Strategy
- Cards & Containers: Sharp 0px or 2px border-radius. Borders are 1px solid with varying opacities. Backgrounds use very subtle scanline patterns or dotted grids.
- Speed Dial FAB: A glowing, multi-layered concentric circle that expands with a digital "locking" animation, revealing sharp, angular options for Receipt Scan or Manual Entry.
- Receipt Strips (History): Designed to look like printed terminal logs. Monospace text, dotted dividers (-----------), and status indicators formatted as [ OK ] or [ ERR ].
- Macro Charts (fl_chart): Styled like oscilloscope or radar readouts. Glowing lines, visible data points as crosshairs (+), and glowing horizontal baseline limits.
- StateMessageCard: Styled as a system terminal prompt (root@inflabasket:~#) outputting system status or AI parsing results with a blinking cursor block (█).
Key Screen Overhauls
1. Dashboard & Macro Charts: 
   The dashboard becomes the "Main Command Center." Total purchasing power is displayed in massive, glowing monospace digits. The Fiat/Bitcoin toggle is a heavy, tactile hardware switch; flipping to Bitcoin transitions the UI glows from Magenta/Green to pure Satoshi Orange, stabilizing subtle background glitches.
2. Add Entry + AI Receipt Scanner flow: 
   The camera view features an overlay of targeting brackets and running technical coordinates. When the AI parses the receipt, the screen displays a "decoding" effect (random characters rapidly cycling before locking into the extracted item names and prices).
3. History List & Receipt Review Dialog: 
   A continuous scrolling log resembling a server terminal. Clicking an entry opens a modal that "wipes" in from the side, presenting data in a strict key-value pair format with raw, unstyled aesthetic precision.
4. Settings & Subscription Paywall: 
   The paywall is framed as an "Access Protocol Clearance." Premium features are listed as encrypted nodes. The UI utilizes high-contrast cyan and magenta to emphasize the exclusivity and advanced nature of the premium analytics tools.
Safe Implementation Roadmap
Phase 1: Design Tokens + Core Components  
Implement the new color scheme, typography (google_fonts), and basic glowing borders in Flutter's ThemeData. Update text styles without altering layout logic.
Phase 2: Navigation & Foundation Screens  
Convert the AppBar and BottomNavigationBar/Drawer into the angular, sharp-edged terminal aesthetic. Apply background grid patterns using Flutter CustomPaint.
Phase 3: Advanced Components & Interactions  
Overhaul the FAB, History list tiles, and fl_chart styling to match the neon oscilloscope look. Integrate the blinking cursor (StateMessageCard) component.
Phase 4: Theming (Dark + Fiat/Bitcoin) + Accessibility  
Wire the Riverpod theme state to handle the dramatic color shifts between Fiat (Magenta/Green) and Bitcoin (Orange/Gold) modes. Verify all neon colors pass the 4.5:1 WCAG contrast ratio against pure black.
Phase 5: Polish, Performance & Developer Handoff  
Add the decoding text animations and subtle CRT flickers. Profile the application in --profile mode to ensure shader and glow effects do not drop the framerate below 60fps on mid-range devices.
Risks & Mitigation Strategies
1. Risk: Motion Sickness / Sensory Overload. Glitch and flicker effects can be overwhelming or trigger accessibility issues.
   Mitigation: Keep animations extremely subtle and brief. Provide a "Reduce Motion" toggle in settings that disables CRT flickers and decoding effects, defaulting to system preferences.
2. Risk: Poor Contrast with "Neon" Colors. Glowing effects can muddy text legibility on lower-brightness screens.
   Mitigation: Ensure the core text color is always pure white (#FFFFFF) or high-value bright (#E0E0E0), using the neon colors strictly for borders, accents, and charts. Adhere strictly to WCAG AA.
3. Risk: Performance Drops from Shadows. Heavy use of glowing BoxShadow in Flutter lists can cause scroll jank.
   Mitigation: Use simplified border rendering or pre-rasterized CustomPaint shapes for repeating list elements. Limit complex glows to static dashboard elements.
4. Risk: Alienating Non-Technical Users. The terminal aesthetic might be too complex or confusing.
   Mitigation: Maintain standard UX patterns (clear buttons, standard navigation placement). The look is complex, but the interaction remains intuitive and predictable.
Success Metrics
- Aesthetic Distinction: 100% replacement of default Material widgets with custom Matrix/Terminal counterparts.
- Accessibility: 0 WCAG AA contrast violations using automated testing tools; full support for Flutter's ReduceMotion accessibility feature.
- Performance: Maintain 60fps on target devices during list scrolling and chart rendering, verified via Flutter DevTools.
- Conversion: 15% increase in premium subscriptions, driven by the highly gamified and premium "Access Protocol" paywall experience.
- Engagement: 20% increase in manual receipt entries due to the satisfying "decoding" interaction loop.
Appendix: Sample Token Preview
/* Matrix Neo-Cyberpunk Tokens */
:root {
  /* Surface & Background */
  --bg-void: #050505;
  --bg-surface: #0A110F;
  --bg-elevated: #121A16;
  /* Terminal Colors */
  --neon-green-bright: #00FF41;
  --neon-green-dim: #008F11;
  --fiat-magenta: #FF003C;
  --btc-orange: #F7931A;
  --text-primary: #FFFFFF;
  --text-muted: #8F9A95;
  /* Typography */
  --font-ui: 'Rajdhani', sans-serif;
  --font-data: 'JetBrains Mono', monospace;
  /* Glow Definitions */
  --glow-sm-green: 0 0 4px rgb(0 255 65 / 0.4);
  --glow-md-btc: 0 0 8px rgb(247 147 26 / 0.5);
}
/* Sample Component: Terminal Button */
.btn-terminal {
  background-color: var(--bg-void);
  border: 1px solid var(--neon-green-dim);
  color: var(--neon-green-bright);
  font-family: var(--font-ui);
  text-transform: uppercase;
  letter-spacing: 0.1em;
  padding: 12px 24px;
  position: relative;
  transition: all 0.2s ease;
}
.btn-terminal:hover {
  background-color: rgb(0 255 65 / 0.1);
  border-color: var(--neon-green-bright);
  box-shadow: var(--glow-sm-green);
  text-shadow: 0 0 2px var(--neon-green-bright);
}
.btn-terminal::before {
  content: '>';
  margin-right: 8px;
  animation: blink 1s step-end infinite;
}
[data-theme="bitcoin"] .btn-terminal {
  border-color: var(--btc-orange);
  color: var(--btc-orange);
}
[data-theme="bitcoin"] .btn-terminal:hover {
  background-color: rgb(247 147 26 / 0.1);
  box-shadow: var(--glow-md-btc);
  text-shadow: 0 0 2px var(--btc-orange);
}