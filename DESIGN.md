---
name: LocReminder
description: A location alarm whose interface stays out of the way until the moment it matters.
colors:
  primary-seed: "#2563EB"
  map-pin-shadow: "rgba(0, 0, 0, 0.28)"
  user-position: "#448AFF"
  banner-paper: "#F5F1EA"
typography:
  headline:
    fontFamily: "Roboto, sans-serif"
    fontWeight: 400
  title:
    fontFamily: "Roboto, sans-serif"
    fontWeight: 600
  body:
    fontFamily: "Roboto, sans-serif"
    fontWeight: 400
    lineHeight: 1.5
  label:
    fontFamily: "Roboto, sans-serif"
    fontWeight: 700
    fontSize: "12px"
    letterSpacing: "0.8px"
  button:
    fontFamily: "Roboto, sans-serif"
    fontSize: "16px"
    fontWeight: 600
rounded:
  xs: "4px"
  sm: "12px"
  md: "16px"
  fab: "18px"
  lg: "20px"
  xl: "24px"
  sheet: "28px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "24px"
components:
  button-filled:
    rounded: "{rounded.md}"
    padding: "0 24px"
    height: "52px"
    typography: "{typography.button}"
  button-outlined:
    rounded: "{rounded.md}"
    padding: "0 24px"
    height: "52px"
  fab:
    rounded: "{rounded.fab}"
  card:
    rounded: "{rounded.lg}"
    padding: "0"
  input:
    rounded: "{rounded.md}"
    padding: "16px"
  sheet:
    rounded: "{rounded.sheet}"
---

# Design System: LocReminder

## Overview

**Creative North Star: "The Quiet Instrument"**

LocReminder is a tool that sits still until the moment it matters, and is then
unmissable. Almost the entire interface is in service of getting out of the
way: the map fills the screen, chrome floats at its edges, and nothing
competes for attention while someone is dozing on a bus. All of the app's
loudness is spent in one place — the alarm itself, which takes the whole
screen, overrides silent mode, and cannot be ignored.

That produces an unusual distribution. The resting state is deliberately
undramatic: one accent colour, no gradients, no decoration, generated Material
3 tonal surfaces doing the separation work. The instrument reads as precise
rather than friendly, because the promise it makes is a precise one — it rings
at a place, not approximately.

The map is the content, not a backdrop. Every chrome decision is measured
against whether it obscures the map or the pin the user is placing. Density is
compact: controls take the space they need and no more, so that more of the
route stays visible.

**Key Characteristics:**
- A single blue accent, taken from the launcher icon, used sparingly
- Floating chrome over a full-bleed map; depth separates control from content
- Compact controls, generous touch targets — density without shrinking targets
- Material 3 tonal surfaces rather than borders or dividers
- Full expressive weight reserved for the alarm screen

## Colors

A single seeded accent over Material 3's generated tonal surfaces, so light and
dark are one system rather than two palettes.

### Primary
- **Signal Blue** (`#2563EB`): the seed for the entire scheme, chosen to match
  the launcher icon so app and icon read as one product. Appears on the active
  alarm pin, the radius circle, filled buttons, the focused input border,
  slider track and thumb, and section labels. Everything else is derived from
  it by `ColorScheme.fromSeed`.

### Neutral
Surfaces are Material 3's generated tonal roles, not hand-picked greys:
`surface` for the scaffold, `surfaceContainerLow` for cards,
`surfaceContainerHigh` for input fills, `surfaceContainerHighest` for inactive
slider track, `outlineVariant` at 50% for dividers. A paused alarm's pin uses
`outline` — the same shape as an active one, drained of signal.

### Tertiary
- **Position Blue** (`#448AFF`): the user's own location dot and its accuracy
  circle. Deliberately distinct from Signal Blue so "where I am" never reads as
  "where the alarm is".
- **Banner Paper** (`#F5F1EA`): a fixed light card behind the About screen's
  Free Palestine artwork, which is dark ink on transparency and would otherwise
  vanish in dark mode.

### Named Rules

**The One Accent Rule.** Signal Blue is the only accent in the system. A second
hue enters only when it must not be confused with the first — the user's
position dot is the sole example. Introducing a third means proving the same.

**The Map Wins Rule.** No chrome is opaque across the full width of the map.
Panels stop short, attribution stays visible, and translucency is used where a
surface must sit over the map at all.

## Typography

**All roles:** Roboto (Android's system face), via Material 3's default text
theme.

**Character:** Unstyled on purpose. This is an app someone reads at a glance on
a moving bus, in bad light, at any system font scale. A display face would earn
nothing and cost legibility, so the type system is the platform's, with weight
doing the hierarchy work rather than family.

### Hierarchy
- **Headline** (400): screen titles on the About and reliability screens.
- **Title** (600): the app-bar title and card headings; weight, not size, marks
  them as structural.
- **Body** (400, 1.5 line-height): explanatory prose. The reliability screen
  carries the longest passages and sets the measure.
- **Label** (700, 12px, 0.8px tracking, uppercase): section markers such as
  DEVELOPER and CREDITS, tinted Signal Blue. The only uppercase in the system.
- **Button** (600, 16px; 15px outlined): heavier than body so actions read as
  actions.

### Named Rules

**The System Face Rule.** No bundled font ships with this app. The APK is
already ~53 MB and the type system gains nothing from a custom face that the
platform's own does not already do at every accessibility scale.

## Layout

A single full-bleed map with everything else floating over it. The home screen
is a `Stack`: map at the base, then circles and markers, then a top bar and
permission warnings pinned under the status bar, then the alarm sheet at the
bottom, with map controls in the floating-action slot at the end edge.

The alarm list is a `DraggableScrollableSheet` resting at 13% of screen height
and opening to 62%. That resting size is a deliberate sliver — enough to show
that alarms exist and to invite the drag, little enough that the map stays the
screen. Map controls track the sheet's top edge while it is near rest and fade
out past 30%, at which point the list owns the screen and the buttons would be
obstacles rather than controls.

The spacing rhythm is 4 / 8 / 12 / 16 / 24. Screen padding is 16–20; the gap
between stacked floating buttons is 12; card interiors run 16–18.

### Named Rules

**The Thumb Column Rule.** Every map control lives in one column at the end
edge, aligned to that edge rather than centred against the widest of them.
A control the thumb has to hunt for on a moving vehicle has failed.

## Elevation & Depth

Chrome floats; content lies flat. This is a hybrid, and the split is
load-bearing: anything hovering over the map casts a real shadow, and anything
inside a panel uses tonal separation instead.

Cards sit at elevation 0 on `surfaceContainerLow`, with surface tint explicitly
disabled — inside a sheet, tonal difference alone separates rows, and stacked
shadows would turn a list into corduroy. Over the map the opposite holds,
because a flat control on a detailed map has no edge to read against.

### Shadow Vocabulary
- **Floating control** (`elevation: 3`): the top search bar and menu button.
- **Action** (`elevation: 4`): all floating action buttons.
- **Panel** (`elevation: 12`): the location picker's bottom panel, the heaviest
  in the system, lifting a decision surface clear of the map behind it.
- **Pin shadow** (`blur 2.5, offset (0, 1.5), black 28%`): drawn as a blurred
  copy of the pin path, not `Canvas.drawShadow` — that call rasterises
  differently per backend and lands under Impeller as a hard offset silhouette,
  making one pin read as two.

### Named Rules

**The Real Shadow Rule.** Every shadow has both an offset and a blur. A
zero-offset halo is decoration, and this system has no decoration.

## Shapes

Rounded throughout, on a scale that grows with the element's importance and how
much of the screen it claims: 12 for text buttons, 16 for filled and outlined
buttons, inputs and list tiles, 18 for floating action buttons, 20 for cards,
24 for dialogs, 28 for the top corners of bottom sheets. Small utility
surfaces — the map attribution chip — sit at 6.

Inputs carry no border at rest at all: they are a filled `surfaceContainerHigh`
shape, and a 2px Signal Blue border appears only on focus. Dividers are
`outlineVariant` at 50% opacity, 1px, used sparingly between list rows.

The map pin is the one bespoke silhouette: a circular head with two straight
tangent edges converging on a point, drawn as a path so the tip lands exactly
on the coordinate. Material's `Icons.location_on` carries internal padding
below its tip and would float above the radius circle it marks.

### Named Rules

**The Tip-On-Target Rule.** The pin's point is the coordinate. Any marker
change must keep the tip on the anchor, or the alarm appears to be somewhere it
is not.

## Components

### Buttons
- **Shape:** generously rounded (16px); text buttons tighter (12px).
- **Filled:** Signal Blue, 52px minimum height, 24px horizontal padding,
  16px/600 label.
- **Outlined:** identical geometry, 15px/600 label, for secondary actions.
- **Text:** 12px radius, 600 weight, for tertiary and dismissive actions.

### Floating action buttons
- **Shape:** 18px radius — squarer than Material's default circle, matching the
  system's rounded-rectangle language.
- **Elevation:** 4.
- **Arrangement:** one end-aligned column, 12px apart, extended primary action
  at the bottom nearest the thumb, small utilities above it.
- **Busy state:** the locate button swaps its icon for an 18px progress
  indicator and disables while a fix is pending; a real fix can take seconds
  and a button that looks inert reads as broken.

### Cards
- **Corner:** 20px. **Background:** `surfaceContainerLow`. **Elevation:** 0,
  surface tint off. **Margin:** none — the parent owns spacing.

### Inputs
- **Style:** filled `surfaceContainerHigh`, no border, 16px radius, 16px
  padding all round.
- **Focus:** 2px Signal Blue border. No glow, no shift.

### Bottom sheets
- **Shape:** 28px top corners, drag handle always shown.
- **Behaviour:** the alarm sheet rests at 13% and opens to 62%, tracked live so
  chrome can respond to the drag rather than to its settled state.

### Map pin (signature)
A drawn teardrop, 44px on the map and 52px as the picker's centre crosshair.
Signal Blue when armed, `outline` when paused, always stroked in the surface
colour so it separates from any tile beneath it, with a hollow centre. The
picker's pin is a fixed crosshair — the map moves beneath it, so the pin is
always exactly where the alarm will be placed.

### Map tiles
Four OpenStreetMap styles. In dark mode the standard and humanitarian styles
are inverted by a luminance matrix that preserves hue, so the map reads dark
rather than as a glaring white rectangle. Topographic and cycle styles are left
alone: inverting shaded relief turns hills inside out.

## Do's and Don'ts

### Do:
- **Do** keep Signal Blue (`#2563EB`) as the only accent, and derive everything
  else from the seeded scheme.
- **Do** give anything floating over the map a shadow with both offset and
  blur.
- **Do** keep interactive targets at 48px or more even while spacing stays
  compact. Density comes from the gaps, never from the targets.
- **Do** let chrome respond to the alarm sheet's drag, not just its end state.
- **Do** keep the pin's tip on its coordinate.
- **Do** test every screen at large system font scales; the type system is the
  platform's precisely so this keeps working.

### Don't:
- **Don't** use `Canvas.drawShadow` for custom-painted shapes. It rasterises
  differently per backend. Draw a blurred copy of the path.
- **Don't** put shadows on cards inside sheets. Tonal separation does that job.
- **Don't** add a second accent hue without proving it would be confused with
  Signal Blue if it were not distinct.
- **Don't** bundle a custom font.
- **Don't** centre a column of floating controls whose widest member is an
  extended button; the small ones end up inset from the edge and read as
  misaligned.
- **Don't** cover the OpenStreetMap attribution. Its visibility is a licence
  condition, not a layout preference.
