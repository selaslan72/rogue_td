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

Use a **real map expansion plan** instead of simply rotating the current 6
maps.

- Spring Mode should give players new layouts as they progress toward 30
  levels. Reusing a small set of maps in rotation is not enough for the player
  experience.
- Create new map layouts in batches, starting with enough fresh layouts to make
  the expanded Spring campaign feel meaningfully larger than the current 6-map
  MVP.
- Winter Mode can reuse some proven layout concepts at first, but should still
  feel like a distinct campaign through snowy visuals, pine trees, icy rocks,
  colder path colors, and season-specific decoration.

This keeps content production focused on player-facing variety rather than only
data scaling.

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

Level naming should stay simple for the MVP: players advance through numbered
levels (`1`, `2`, `3`, ...), without unique map names shown in the UI.

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
2. **Progress keys:** make saved stars season-aware so `Spring 1` and
   `Winter 1` cannot collide.
3. **Map expansion:** create new Spring map layouts instead of rotating only
   the current 6 maps.
4. **Spring campaign:** register 30 numbered Spring levels using the expanded
   map set and difficulty scaling.
5. **Mode UI:** add Spring/Winter selector and season-aware level select.
6. **Winter theme:** add winter palette and winter obstacle/decor variants.
7. **Winter campaign:** register 30 Winter levels with winter visuals and
   harder scaling.

### Open Design Questions

- Should Winter be locked from the start?
- Should Winter introduce new enemy modifiers or only visual changes in the
  first version?
- Should the game eventually support more seasons after Winter?

Resolved for MVP:

- Levels are displayed as simple numbers, not unique map names.
- Spring 30 should include new map layouts; rotating the current 6 maps is not
  acceptable as the main content plan.

## Near-Term Contribution Tracks

### Developer Testing Tools

Speed up development and balance passes with debug-only tools:

- Unlock all levels in local/debug runs.
- Add a debug HUD for gold, wave skip, lives, and quick enemy spawn tests.
- Add a map preview/test entry point so layouts can be inspected quickly.
- Keep these tools out of release builds.

### Spring Map Expansion

The next major content step is adding new Spring layouts:

- Add fresh path shapes instead of reusing the current 6 maps.
- Vary slot placement, obstacle density, and clearing pressure per map.
- Expand in small batches so each batch can be tested and balanced.

### Tower Identity Pass

Each tower should have a memorable gameplay identity:

- Archer: long range, precision, or crit-style behavior.
- Cannon: splash pressure and armor-breaking role.
- Frost: area control and slow tuning.
- Flame: damage-over-time and crowd pressure.
- Tesla: chain lightning plus network/link synergy.
- Barracks: blocking, soldier positioning, and lane control.

### Roguelike Run Variety

Runs should feel less repetitive over time:

- Make wave rewards and modifiers more meaningful.
- Add risk/reward choices.
- Consider relic-like run bonuses that change tower behavior.
- Keep choices readable and fast between waves.

### Balance And Telemetry

Balancing will get harder as content grows:

- Track per-tower damage or contribution during a run.
- Show a compact run summary for tower performance.
- Use this data to tune waves, maps, tower costs, and upgrades.

### Professional Presentation And Polish

The project should gradually move from prototype feel toward a more polished
game presentation:

- Define a consistent visual direction for terrain, paths, towers, obstacles,
  HUD panels, and popups.
- Improve map presentation with better path borders, subtle ground texture,
  clearer build slots, and stronger entrance/exit/castle silhouettes.
- Polish tower readability with stronger silhouettes, clearer upgrade visuals,
  refined projectiles, hit flashes, and special effects such as Tesla links.
- Upgrade HUD and panels so gold, lives, waves, tower picker, and upgrade
  controls feel like a cohesive game UI rather than debug widgets.
- Add lightweight feedback animations: tower placement pop, slot unlock,
  upgrade flash, wave-start banner, gold gain text, and enemy hit/death cues.
- Add a simple sound pass for placing, firing, hits, gold, upgrades, wave
  start, victory, and defeat.
- Choose a font and icon direction that supports Turkish text and reduces
  reliance on emoji over time.
- Improve web polish with a loading screen, centered game frame, responsive
  sizing, and fewer black-screen/blank-start moments.
- Build a small brand identity: logo/wordmark, palette, UI border style, icon
  style, and future Spring/Winter seasonal presentation.

Suggested polish priority:

1. UI/HUD polish.
2. Map/path/slot visual polish.
3. Tower, projectile, and hit-effect polish.
4. Placement, upgrade, wave, and reward feedback animations.
5. Sound pass.
6. Logo, loading screen, and season theme presentation.

### Current Context

The game currently has:

- 6 levels.
- 12 waves per level.
- Persistent stars and fragments via `SharedPreferences`.
- Level locking based on total stars.

This roadmap expands that structure rather than replacing it.
