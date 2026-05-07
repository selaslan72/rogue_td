# Rogue TD Roadmap

This document captures product direction and larger feature ideas that should
survive individual coding sessions.

## Season Modes: Spring And Winter

### Goal

Turn the current 6-level game into a larger seasonal progression:

- **Spring Mode:** expand the current green/forest campaign from 6 levels to
  30 levels.
- **Winter Mode:** add a second 30-level campaign with a snowy environment,
  pine trees, winter rocks/foliage, and a colder visual palette.

The player-facing fantasy is simple: first master the spring campaign, then
unlock or enter a harder winter campaign that feels familiar mechanically but
visually fresh.

### Recommended Architecture

Use a **map layout pool + rotation** instead of hand-drawing 30 completely
unique maps immediately.

- Create roughly **10-12 reusable map layouts**.
- Spring Mode uses these layouts across 30 levels with increasing difficulty,
  enemy composition changes, and level multipliers.
- Winter Mode can reuse the same layout pool at first, but render it through a
  winter theme: snow ground, pine trees, icy rocks, colder path colors, and
  season-specific decoration.

This keeps content production realistic while still giving players 30 levels
per season.

### Mode Selection

Initial design options:

- Main menu with two large choices:
  - `Spring Mode`
  - `Winter Mode` (locked until a chosen Spring milestone)
- Or a level-select screen with top tabs:
  - `Spring`
  - `Winter`

The simpler first implementation is a main mode selector before the level
select screen.

### Progression Rules To Decide

- Whether Winter unlocks after all 30 Spring levels, after a star threshold, or
  after beating a final Spring boss.
- Whether Spring and Winter share stars/fragments or have separate completion
  counters.
- Whether Winter is just a visual season or also has gameplay changes such as
  faster enemies, ice armor, frozen paths, or harsher economy.

### Implementation Phases

1. **Data model:** add a `Season` or `GameMode` field and make level registry
   season-aware.
2. **Map pool:** expand from 6 layouts toward 10-12 reusable layouts.
3. **Spring campaign:** generate/register 30 Spring levels using the layout
   pool and scaling.
4. **Mode UI:** add Spring/Winter selector and season-aware level select.
5. **Winter theme:** add winter palette and winter obstacle/decor variants.
6. **Winter campaign:** register 30 Winter levels, initially reusing layouts
   with winter visuals and harder scaling.

### Open Design Questions

- Should each level have a unique name, or should names follow season + number
  at first?
- Should Winter be locked from the start?
- Should Winter introduce new enemy modifiers or only visual changes in the
  first version?
- Should the game eventually support more seasons after Winter?

### Current Context

The game currently has:

- 6 levels.
- 12 waves per level.
- Persistent stars and fragments via `SharedPreferences`.
- Level locking based on total stars.

This roadmap expands that structure rather than replacing it.
