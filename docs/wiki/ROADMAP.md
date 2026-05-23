# Rogue TD Roadmap

This document captures product direction and larger feature ideas that should
survive individual coding sessions.

Last refreshed from code state: 2026-05-23.

## Season Modes: Spring And Winter

### Goal

Turn the original 6-level game into a larger seasonal progression:

- **Spring Mode:** expand the current green/forest campaign from 6 levels to
  30 levels.
- **Winter Mode:** add a second 30-level campaign with a snowy environment,
  pine trees, winter rocks/foliage, and a colder visual palette.

The player-facing fantasy is simple: first master the spring campaign, then
unlock or enter a harder winter campaign that feels familiar mechanically but
visually fresh.

### Current Implementation Status

The season expansion is now partially implemented in code:

- `GameSeason` exists with `spring` and `winter` definitions. Winter is marked
  locked, but debug builds may still enter it for testing.
- `LevelDef` carries a `season` field.
- `LevelRegistry` is season-aware and exposes separate Spring and Winter
  campaigns.
- Spring now has 30 numbered levels backed by 30 map layouts.
- Winter now has 30 numbered levels backed by winter-themed map layouts.
- The level select screen has a Spring/Winter selector and a grid layout.
- Level cards still display simple numbered levels (`Bölüm 1`, `Bölüm 2`, ...).
- Debug mode unlocks levels to speed up testing and balancing.
- Winter maps render with a colder background, snow pine/snow bush variants,
  frost rocks, and winter-styled tower slots.
- `RunResult` includes the selected season in its share/result text.
- Tests now assert that Spring and Winter each expose 30 real map-backed levels
  and that campaign tower slots stay clear of enemy paths.
- Winter route QA found several generated maps that passed basic geometry but
  felt bad in play because the path approached the target castle early or
  appeared to loop around itself. Levels 4, 8, 10, 16, 20, 22, 26, and 28 now
  have corrected/custom readable routes.
- A campaign-wide Winter route regression test now requires every Winter path
  to keep the target-castle approach for the final segment.
- GitHub Actions now builds a release/user-mode APK instead of a debug APK.
  Release builds do not use `kDebugMode`, so debug-only level unlocking is not
  active for players.
- Progress is season-aware. Stars are stored by season and level, so `Spring 1`
  and `Winter 1` no longer collide. Legacy `level_stars_v1` progress migrates
  into Spring progress.

### Recommended Architecture

Use a **real map expansion plan** instead of simply rotating the current 6
maps.

- Spring Mode should continue to use real layout variety across its 30 levels.
  The current implementation already moved beyond rotating the original 6 maps.
- Winter Mode can use generated variants and proven layout concepts, but must
  continue to feel distinct through snowy visuals, pine trees, icy rocks,
  colder path colors, and season-specific decoration.
- Map generation/assembly should keep enforcing usable build slots, path
  clearance, and target-route sanity with tests.

This keeps content production focused on player-facing variety rather than only
data scaling.

### Mode Selection

Current implementation:

- The level select screen has a Spring/Winter selector.
- Winter is marked locked in the season model.
- Debug builds can select locked seasons and unlocked levels for development.
- Level naming stays simple: players advance through numbered levels, without
  unique map names shown as the primary UI label.

Future option:

- A more polished main menu may eventually show two large choices before the
  level select screen, but the current selector is enough for testing the
  campaign structure.

### Progression Rules To Decide

- Whether Winter unlocks after all 30 Spring levels, after a star threshold, or
  after beating a final Spring boss.
- Whether Winter is just a visual season or also has gameplay changes such as
  faster enemies, ice armor, frozen paths, or harsher economy.
- Whether fragments remain shared across seasons or eventually become
  season-specific.

Resolved or leaning:

- Stars should be season-aware so Spring and Winter level IDs cannot collide.
- Level unlocks can continue to be based on stars, but the exact Winter unlock
  threshold still needs a product decision.

### Implementation Phases

1. **Done:** add `GameSeason` and make `LevelDef`/`LevelRegistry`
   season-aware.
2. **Done:** create new Spring map layouts instead of rotating only the
   original 6 maps.
3. **Done:** register 30 numbered Spring levels using the expanded map set and
   difficulty scaling.
4. **Done:** add a Spring/Winter selector and season-aware level list.
5. **Done:** add winter palette and winter obstacle/decor/slot variants.
6. **Done:** register 30 Winter levels with winter visuals and scaling.
7. **Done:** make saved stars season-aware so `Spring 1` and `Winter 1` cannot
   collide.
8. **Next:** decide the real Winter unlock rule and make the UI communicate it.
9. **Next:** playtest the new Spring/Winter layouts and tune path, slot,
   obstacle, HP, speed, and star requirements.

### Open Design Questions

- Should Winter be locked from the start?
- Should Winter introduce new enemy modifiers or only visual changes in the
  first version?
- Should the game eventually support more seasons after Winter?

Resolved for MVP:

- Levels are displayed as simple numbers, not unique map names.
- Spring 30 includes new map layouts; rotating the original 6 maps is no longer
  the implementation plan.
- Winter has a first playable 30-level structure, though it still needs balance
  and polish passes.

## Near-Term Contribution Tracks

### Progress Persistence

Season-aware progress is implemented:

- Stars are stored by season and level, for example `spring:1` and `winter:1`.
- Old `level_stars_v1` progress migrates into Spring progress.
- Level select totals are season-aware.
- Unlock checks use season-specific stars.
- Tests cover Spring/Winter star separation, unlock separation, and legacy
  migration.

Remaining progression decision:

- Decide when Winter should unlock in release builds.

### Developer Testing Tools

Speed up development and balance passes with debug-only tools:

- Keep all levels selectable in local/debug runs.
- Add a debug HUD for gold, wave skip, lives, and quick enemy spawn tests.
- Add a map preview/test entry point so layouts can be inspected quickly.
- Keep these tools out of release builds.

### Spring Map Expansion

The first 30-level Spring campaign exists. The next step is quality control:

- Playtest every Spring layout for impossible routes, dead slots, and overly
  dominant tower positions.
- Tune slot placement, obstacle density, and clearing pressure per map.
- Keep adding tests for path/slot regressions when layouts change.

### Winter Campaign Pass

Winter has a first 30-level implementation and visual identity, but it needs
its own balance pass:

- Avoid generated patterns that make the path feel like it is circling itself
  or passing in front of the target castle before the final approach.
- Current custom/readability pass:
  - Winter 4: corrected `Pine Ring`.
  - Winter 8: custom `Winter Maze 8`.
  - Winter 10: custom `Winter Maze 10`.
  - Winter 16: custom `Winter Run 16`.
  - Winter 20: custom `Winter Run 20`.
  - Winter 22: custom `Winter Run 22`.
  - Winter 26: custom `Winter Run 26`.
  - Winter 28: custom `Winter Run 28`.
- Verify that generated winter variants feel distinct enough across the full
  campaign.
- Tune winter slot placement and obstacle density.
- Decide whether Winter stays visual-only for MVP or adds gameplay pressure
  such as faster enemies, ice armor, frozen paths, or harsher economy.
- Polish snow/ice path readability against towers, enemies, and projectiles.

### External Map Design Support

Map design should move out of ad-hoc Dart coordinate edits before the campaign
grows further:

- Prepare a `MapData` JSON/YAML format for waypoints, tower slots, rocks, theme,
  and designer notes.
- Give external tools/designers a strict 480x800 brief:
  - readable TD route,
  - no early target-castle pass,
  - no self-looping route feel,
  - 8-12 usable tower slots,
  - slots at least 44px from the path,
  - final approach reserved for the last path segment.
- Build or script a map preview/validator so externally generated maps can be
  reviewed quickly before being registered in the campaign.
- Continue using automated tests as the quality gate for path clearance,
  target-castle approach, and usable slot counts.

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

- 30 Spring levels.
- 30 Winter levels.
- 12 waves per level.
- Season-aware level definitions and level registry.
- A Spring/Winter selector in level select.
- Winter visual variants for background, foliage, rocks, and tower slots.
- Season-aware persistent stars and shared fragments via `SharedPreferences`.
- Level locking based on total stars.
- Debug-mode level unlocking.
- Tests covering campaign counts, slot/path clearance, and Winter target-castle
  approach rules.
- GitHub release APK workflow for player/user-mode builds.

Current known technical debt:

- Winter unlock rules are not finalized for release builds.
- Spring maps still need the same readability QA pass that Winter just received;
  Spring 22 was flagged as especially poor and should be redesigned next.
