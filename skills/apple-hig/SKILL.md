---
name: apple-hig
description: Audit and improve Apple platform UI against the Human Interface Guidelines — layout, typography, color, components, interaction, accessibility
compatibility: opencode
---

Looking at the interface code — audit and improve it to follow Apple's Human Interface Guidelines for the target platform(s). Cover layout, typography, color, components, interaction, and accessibility.

> Reference: [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

> [!NOTE]
> **No preservation requirement.** Existing UI patterns, custom components, and layout decisions are not sacred. If HIG calls for replacing or removing something — replace or remove it entirely. A native system component that does the job is always preferred over a hand-rolled one, even if the hand-rolled version was deliberate. The goal is a fully HIG-compliant UI, not a patched version of the existing one.

> [!NOTE]
> **When NOT to use:** Don't use on non-Apple platforms — this is Apple-specific; Material/web UIs have their own guidelines. Don't use to override deliberate brand decisions without team input; flag conflicts for discussion.

## Protocol

1. Identify the target platform(s) from the codebase. **Audit only the platform-specific sections that apply — skip the rest.**
2. Read the relevant UI files — SwiftUI views, UIKit view controllers, AppKit views, storyboards, XIBs, asset catalogs.
3. Audit against the checklist below, noting each violation.
4. State findings and fixes, then implement. Do not pause for confirmation. Replace or remove non-compliant UI wholesale where needed — do not preserve it out of caution.
5. Verify the project builds with no new layout warnings or preview errors. Run SwiftUI previews in Dark Mode, RTL (`.environment(\.layoutDirection, .rightToLeft)`), and at least one large Dynamic Type size (e.g. `.sizeCategory(.accessibilityExtraExtraLarge)`) — these are the three most common regressions that compile cleanly but break visually.

> [!TIP]
> For large projects with many UI files, delegate per-screen or per-module audits to subagents — _"Use a subagent to audit the views in src/Onboarding against the HIG checklist."_ Keeps your main context clean for synthesis and implementation.

---

## Platform Detection

```bash
# Identify frameworks and deployment targets
grep -rn "import SwiftUI\|import UIKit\|import AppKit\|import WatchKit\|import TVUIKit" --include="*.swift" .
grep -E "IPHONEOS_DEPLOYMENT_TARGET|MACOSX_DEPLOYMENT_TARGET|WATCHOS_DEPLOYMENT_TARGET|TVOS_DEPLOYMENT_TARGET" *.xcodeproj/project.pbxproj 2>/dev/null

# Detect widgets and Live Activities
grep -rn "Widget\|WidgetConfiguration\|ActivityConfiguration" --include="*.swift" .
```

---

## Cross-Platform Audit

These apply to all Apple platforms.

### Color

- [ ] **Semantic colors over hardcoded values** — use `.label`, `.secondaryLabel`, `.tertiaryLabel`, `.systemBackground`, `.secondarySystemBackground`, `.systemFill`, `.tintColor`, `.systemBlue` etc.; hardcoded hex or `UIColor(red:green:blue:)` breaks Dark Mode
- [ ] **Asset catalog color sets have Dark Appearance variants** — open `.xcassets`; every named color must have both Any and Dark slots populated; missing Dark slots are a common source of Dark Mode breakage invisible to Swift grep
- [ ] **Dark Mode** — all views adapt; test explicitly; no content disappears or becomes unreadable
- [ ] **Contrast ratio** — ≥ 4.5:1 for body text, ≥ 3:1 for large text (≥18pt regular or ≥14pt bold) and UI components
- [ ] **Color not the sole conveyor of meaning** — pair color with text, shape, or icon; colorblind users must understand the UI without color
- [ ] **High Contrast mode** — respect `UIAccessibility.isDarkerSystemColorsEnabled` / `.colorSchemeContrast == .increased`

### Typography

- [ ] **System fonts** — SF Pro (iOS/macOS), SF Rounded (friendly UI), SF Mono (code); no custom fonts unless explicitly brand-mandated
- [ ] **Dynamic Type** — all text uses text styles (`.body`, `.headline`, `.subheadline`, `.caption`, `.footnote`, etc.) or scales via `UIFontMetrics`; no hard-coded point sizes
- [ ] **Minimum size** — Caption 2 (11pt) is the floor; nothing smaller in any context
- [ ] **Line length** — comfortable reading width (~66 characters); avoid edge-to-edge text on wider screens

### SF Symbols

- [ ] **SF Symbols for standard actions** — share, edit, delete, search, settings, compose, filter, sort — use system symbols, not custom assets
- [ ] **Symbol weight matches surrounding text** — bold label → bold symbol; don't mix weights in the same composition
- [ ] **Rendering mode** — use hierarchical, palette, or multicolor where the symbol supports it and meaning benefits
- [ ] **Symbol scale** — `.small`, `.medium`, `.large` — match context; toolbar symbols typically `.medium`

### Localization & Layout Direction

- [ ] **Leading/trailing over left/right** — use `.leading` / `.trailing` in SwiftUI and `leadingAnchor` / `trailingAnchor` in UIKit/AppKit; hardcoded `.left` / `.right` breaks RTL layouts (Arabic, Hebrew, Persian, etc.)
- [ ] **Natural text alignment** — `NSTextAlignment.natural` / `.multilineTextAlignment(.leading)` instead of `.left`; text mirrors correctly in RTL without code changes
- [ ] **No hardcoded directional offsets** — padding, margin, and inset values that assume LTR (`x: 16` from the left) must use semantic equivalents or flip via `flipsForRightToLeftLayoutDirection`
- [ ] **Images and icons that carry direction** — back arrows, progress indicators, and directional glyphs must mirror in RTL; use SF Symbols that auto-mirror (check `RTL` badge in SF Symbols app) or apply `.environment(\.layoutDirection, .rightToLeft)` in previews to verify

### Motion

- [ ] **Respect Reduce Motion** — check `UIAccessibility.isReduceMotionEnabled` / `@Environment(\.accessibilityReduceMotion)`; substitute crossfades or instant transitions for movement-based animations
- [ ] **Purposeful animation** — every animation guides attention, confirms an action, or conveys hierarchy; no purely decorative motion
- [ ] **Duration** — micro-interactions 0.2–0.35s; view transitions 0.3–0.5s; nothing feels sluggish or abrupt

---

## iOS Audit

### Layout & Safe Areas

- [ ] **Safe area insets** — no content clipped by notch, Dynamic Island, Home indicator, or rounded corners; use `safeAreaInsets` / `.safeAreaInset()` / `.ignoresSafeArea()` only for intentional full-bleed backgrounds
- [ ] **Dynamic Island** — interactive and important content does not overlap the Dynamic Island on iPhone 14 Pro and later
- [ ] **Minimum touch target: 44×44pt** — all interactive elements meet this; use `.contentShape()` or `contentEdgeInsets` to expand hit area without changing visual size
- [ ] **Adaptive layout** — layout responds to `horizontalSizeClass` and `verticalSizeClass`; compact vs. regular size classes handle different content densities

### Navigation

- [ ] **Tab bar for top-level destinations** — 2–5 tabs; primary navigation never lives in a hamburger menu or custom drawer
- [ ] **Navigation stack for hierarchy** — `NavigationStack` / `UINavigationController` push/pop for drill-down; don't present modally for hierarchical navigation
- [ ] **Sheets for temporary tasks** — `.sheet()` / `.fullScreenCover()` for tasks requiring completion or cancellation before returning to context
- [ ] **Swipe-to-go-back preserved** — never disable `interactivePopGestureRecognizer`; custom back buttons must still support the swipe gesture
- [ ] **Large titles at root** — `.navigationBarTitleDisplayMode(.large)` on root views; `.inline` on deeper levels

### Components

- [ ] **System list styles** — `List` / `UITableView` / `UICollectionView` with system styles; no hand-rolled scroll containers replicating what system components already provide
- [ ] **System button styles** — `UIButton.Configuration` (`.filled()`, `.tinted()`, `.gray()`, `.plain()`) for standard actions; custom buttons only where brand genuinely requires it
- [ ] **Action sheets on iPhone, popovers on iPad** — `UIAlertController(.actionSheet)` presents correctly on each automatically if `popoverPresentationController` is configured; verify this works on both
- [ ] **Swipe actions** — trailing swipe for delete (`.destructive`), leading for quick-affirmative; destructive actions are red and require confirmation for irreversible operations
- [ ] **Context menus** — destructive items use `.destructive` attribute and appear last; preview provided where content is rich enough to justify it

### Interaction

- [ ] **Haptic feedback** — `UIImpactFeedbackGenerator` for selections and impacts; `UINotificationFeedbackGenerator` for success/warning/error; `UISelectionFeedbackGenerator` for value changes (pickers, toggles)
- [ ] **Pull to refresh** — `UIRefreshControl` / `.refreshable()` on scrollable content that can be updated
- [ ] **Keyboard avoidance** — no input field hidden behind the keyboard; use `.scrollDismissesKeyboard()` / `keyboardLayoutGuide`

---

## iPadOS Audit

- [ ] **Sidebar navigation** — `NavigationSplitView` / `UISplitViewController` preferred for content-heavy apps; sidebar replaces tab bar at regular size class
- [ ] **Stage Manager** — window is resizable; layout adapts gracefully to arbitrary window sizes, not just fixed iPhone/iPad dimensions
- [ ] **Keyboard shortcuts** — primary actions have `.keyboardShortcut()` / `UIKeyCommand` equivalents with `discoverabilityTitle` shown in the shortcut overlay (hold ⌘)
- [ ] **Pointer support** — interactive elements respond to hover (`.hoverEffect()` / `UIPointerInteraction`); system buttons apply pointer lift automatically
- [ ] **Drag and drop** — content (text, images, files) supports `onDrag` / `onDrop` / `UIDragInteraction` where moving or copying data between apps is meaningful
- [ ] **Orientation** — no unnecessary portrait lock; layout adapts to all orientations unless a specific orientation is genuinely required by the content type

---

## watchOS Audit

- [ ] **Glanceable layout** — every screen communicates its primary information within 2 seconds of a wrist raise; no dense text walls or information hierarchy that requires scrolling to understand
- [ ] **Digital Crown sensitivity** — scrollable content uses `.digitalCrownRotation()` with appropriate sensitivity; never ignore the Crown for navigable or adjustable content
- [ ] **Minimal interaction model** — interactions are brief and completable in seconds; no flows requiring sustained attention; complex tasks deferred to iPhone
- [ ] **Complications** — if the app provides watch complications, they use `WidgetKit` / `ClockKit` correctly; complication data is fresh via background refresh, not stale on wrist raise
- [ ] **Always-on display** — if targeting Apple Watch Series 5+, the always-on state dims but remains readable; no content that becomes invisible at reduced brightness
- [ ] **Haptic feedback** — use `WKHapticType` (`.notification`, `.directionUp`, `.directionDown`, `.success`, `.failure`, `.retry`, `.start`, `.stop`, `.click`) to confirm actions and signal state changes
- [ ] **No custom navigation chrome** — use `NavigationStack` / `WKInterfaceController` hierarchy; don't build custom tab bars or navigation structures that fight the Watch interaction model

---

## tvOS Audit

- [ ] **Focus-based navigation** — all interactive elements participate in the focus engine; use `focusable()` / `UIFocusEnvironment`; no tap-gesture-only interactions that a Siri Remote can't reach
- [ ] **Focus appearance** — focused elements have a clear, system-standard highlight; don't suppress or override the default focus halo unless you provide an equally clear custom style
- [ ] **Remote interaction model** — swipe navigates; click selects; Menu/Back goes up the hierarchy; never require gestures the remote doesn't support (no pinch, no drag)
- [ ] **Top shelf** — if the app declares a top-shelf extension, it provides rich content (images, deep links) that refreshes; a blank or static shelf wastes prime real estate
- [ ] **Layout for the 10-foot view** — text is legible from across a room; minimum ~30pt for body text; generous padding; no dense information layouts designed for hand-held viewing distances
- [ ] **No on-screen keyboard dependence** — text input is a last resort; offer search-as-you-type or preset options wherever possible; if a keyboard is unavoidable, use the system keyboard
- [ ] **Parallax on primary content** — featured images and cards use the system parallax effect (`.focusEffectDisabled(false)` / `UIMotionEffect`) to signal depth and focusability

---

## macOS Audit

### Window & Chrome

- [ ] **Standard title bar** — use default `NSWindow` chrome; hide only for full-screen media or justified custom chrome
- [ ] **Window minimum size** — `minSize` set; content doesn't collapse below a usable state
- [ ] **Toolbar** — primary actions in `NSToolbar` / `.toolbar()`; icons use SF Symbols; labels visible or in overflow menu

### Navigation

- [ ] **Sidebar** — `NavigationSplitView` / `NSSplitViewController` for multi-column navigation; sidebar items use SF Symbols with labels
- [ ] **Menu bar completeness** — every primary action reachable from the menu bar with a keyboard shortcut; no action exists only in the UI
- [ ] **Standard shortcuts** — ⌘N new, ⌘O open, ⌘S save, ⌘W close, ⌘Q quit, ⌘Z/⇧⌘Z undo/redo, ⌘C/V/X copy/paste/cut; don't override these

### Controls & Interaction

- [ ] **Native macOS controls** — `NSButton`, `NSTextField`, `NSPopUpButton`, `NSSlider`, `NSStepper`; don't port iOS controls directly — they look and feel wrong on Mac
- [ ] **Tooltips** — all icon-only toolbar buttons and controls have `.help("description")` / `toolTip:`
- [ ] **Inspector panel** — per-selection settings/metadata in a trailing inspector, not a modal dialog
- [ ] **Right-click context menus** — contextual actions available via right-click / Control-click on all relevant content

---

## visionOS Audit

### Presentation Model

- [ ] **Correct container for content type** — flat 2D content uses `WindowGroup`; bounded 3D content uses a volumetric `WindowGroup` (`.windowStyle(.volumetric)`); immersive experiences use `ImmersiveSpace` — don't force all content into a flat window
- [ ] **Ornaments for chrome** — toolbar actions, tab bars, and secondary controls placed as ornaments (`.ornament()`) floating beside the window boundary, not inside the content area where they consume spatial real estate
- [ ] **Glass material for window backgrounds** — use `.glassBackgroundEffect()` so windows blend naturally with the user's physical environment; don't hardcode opaque backgrounds that fight passthrough

### Interaction

- [ ] **No direct touch assumptions** — all interaction is indirect (look + pinch) or via hands at a distance; no code assumes a finger makes contact with the screen; gesture recognizers must work without touch
- [ ] **Hover effects on every interactive element** — `.hoverEffect()` is the primary affordance that tells users an element is tappable; apply it to every button, card, and interactive surface — without it, the UI is unusable
- [ ] **Comfortable interaction distances** — interactive targets sized and spaced for selection at arm's length; nothing requiring fine precision that works on iPhone but is frustrating at a distance

### Spatial Layout

- [ ] **Depth used deliberately** — `.offset(z:)` and `RealityView` depth only where it adds meaning (layering, focus, hierarchy); gratuitous depth adds visual noise and discomfort
- [ ] **Viewing distance and scale** — content intended to be read placed at comfortable depth (roughly 1–2 meters equivalent); text not so small it requires leaning in, not so large it dominates the field of view
- [ ] **No reliance on precise spatial positioning from code** — the user controls where windows appear; don't assume a window is at a fixed position in space or that two windows are adjacent

### Accessibility

- [ ] **VoiceOver for visionOS** — navigation works without sight; element labels and hints apply exactly as on other platforms; spatial position does not substitute for a label
- [ ] **Reduce Motion in spatial context** — movement-based transitions (flying elements, rapid depth changes) suppressed when Reduce Motion is on; spatial motion can cause more discomfort than on a flat screen

---

## Widgets & Live Activities

### WidgetKit

- [ ] **Size families declared correctly** — widget supports the size families it genuinely works for (`systemSmall`, `systemMedium`, `systemLarge`, `systemExtraLarge` on iPad, `accessoryCircular`, `accessoryRectangular`, `accessoryInline` for Lock Screen and Watch); don't claim sizes where the content is too dense or too sparse
- [ ] **Glanceable content** — primary information visible at a glance; no text-heavy layouts; no information requiring interaction to reveal — widgets are read, not used
- [ ] **No scrolling, no video** — widget views are static snapshots; scrollable or video content is not supported and will fail silently or be stripped
- [ ] **Interactivity limited to buttons and toggles** — iOS 17+ supports `Button` and `Toggle` in widgets; all other interactions must deep-link into the app via `Link` or `.widgetURL()`
- [ ] **`.widgetBackground()` modifier** — use the system widget background so the widget adapts to the user's wallpaper and system appearance correctly; don't hardcode a background color or shape
- [ ] **Privacy-aware placeholder** — sensitive content (account balance, health data, messages) uses `.privacySensitive()` so it is redacted on the Lock Screen when the device is locked
- [ ] **Timeline refresh strategy** — `.atEnd`, `.after(_:)`, or `.never` chosen deliberately; don't request more frequent refresh than the content requires; aggressive refresh drains battery

### Live Activities

- [ ] **Compact, minimal, and expanded presentations all designed** — the Dynamic Island has three distinct layouts; each must be legible on its own; don't just scale the expanded view down
- [ ] **No sensitive data on Lock Screen without authentication** — Live Activity content is visible without unlocking; redact anything that requires auth
- [ ] **Ends promptly when the activity is over** — call `activity.end()` with a final `ContentState`; stale Live Activities that linger erode trust and clutter the Lock Screen

---

## Accessibility Audit (All Platforms)

- [ ] **VoiceOver labels** — every interactive element has a meaningful `accessibilityLabel`; image-only buttons and icons have labels; purely decorative images marked with `accessibilityHidden(true)`
- [ ] **Accessibility hints** — non-obvious interactions have `accessibilityHint` (e.g. `"Double tap to expand section"`)
- [ ] **Accessibility traits** — `.button`, `.header`, `.link`, `.image`, `.selected`, `.adjustable` applied correctly to custom elements
- [ ] **Reading order** — VoiceOver navigates in a logical order; custom containers use `accessibilitySortPriority` or `accessibilityElement(children: .combine/.contain)`
- [ ] **Dynamic Type at extremes** — test at AX1–AX5 (largest accessibility sizes); no clipping, truncation that hides meaning, or broken layout
- [ ] **Reduce Transparency** — `UIAccessibility.isReduceTransparencyEnabled` / `.accessibilityReduceTransparency`; blur materials replaced with opaque fallbacks
- [ ] **Minimum accessible touch target** — even if visual size is small, hit area ≥ 44×44pt on iOS

---

## Common Violations — Check Explicitly

| Violation                           | What to look for in code                                                             |
| ----------------------------------- | ------------------------------------------------------------------------------------ |
| Hardcoded colors                    | `UIColor(red:green:blue:)`, hex literals, `Color(#colorLiteral(...))`                |
| Missing Dark Appearance in xcassets | Named color sets in `.xcassets` with only one appearance slot populated              |
| Fixed font sizes                    | `.font(.system(size: 14))` without `UIFontMetrics`                                   |
| Touch targets too small             | Tappable frame < 44×44pt with no hit area expansion                                  |
| Safe area ignored                   | Content positioned at `y == 0` without safe area offset; Home indicator overlap      |
| Hardcoded LTR layout                | `.alignment(.left)`, `NSTextAlignment.left`, `leadingPadding` as a fixed left offset |
| Swipe-back disabled                 | `interactivePopGestureRecognizer?.isEnabled = false`                                 |
| Modal used for navigation           | `present()` for hierarchical content instead of `pushViewController()`               |
| Missing haptics                     | User-confirmed actions with no `UIFeedbackGenerator`                                 |
| Missing VoiceOver label             | `UIImageView` / icon `UIButton` without `accessibilityLabel`                         |
| No Reduce Motion check              | `UIView.animate` / `.animation()` without motion preference check                    |
| macOS missing shortcuts             | Primary actions with no `⌘`-key equivalent in the menu bar                           |

---

## Output

### Violations found

For each: file and line → what's wrong → which HIG principle → fix applied.

### Already HIG-compliant

What's correct and doesn't need changing — confirms scope was reviewed fully.

### Build verification

Project compiles with no new layout warnings or errors. SwiftUI previews confirmed passing in:

- Dark Mode
- RTL (`.environment(\.layoutDirection, .rightToLeft)`)
- Large Dynamic Type (`.sizeCategory(.accessibilityExtraExtraLarge)`)

---

## Stopping condition

When running in a loop, stop scheduling further invocations when no violations remain across the applicable platform sections and the three regression-prone preview modes (Dark Mode, RTL, large Dynamic Type) render correctly.

Emit this exact phrase so a loop runner recognizes it:

> **Loop exit:** HIG audit clean — no violations across audited platforms. Stopping.
