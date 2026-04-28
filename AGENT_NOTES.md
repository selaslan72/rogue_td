# Agent Notes

This project may be edited with multiple coding assistants. Keep this file as
the handoff point when work is paused, interrupted, or continued by another
assistant.

## Workflow

- Use git before starting meaningful edits.
- Prefer one branch per task, for example `codex/fix-targeting` or
  `claude/add-new-towers`.
- Do not edit the same files in parallel unless the handoff below says why.
- Before switching assistants, record what changed, what remains, and how to
  verify it.

## Current Handoff

- Branch `claude/fix-black-screen-on-load` (Claude, 2026-04-29) — black-screen
  on cold-load fix denemesi.
  - Commit `b96e2cb`: overlay'leri `Positioned.fill` + `StackFit.expand` ile
    tam ekran yaptım (modifier overlay Container'ı küçük kalıyordu).
  - Commit `a205ad3`: `_showModifierSelection` çağrısını `Future.microtask`
    ile bir tick geciktirdim (onLoad sırasında notifier tetikleyince ilk
    frame overlay'i çizmiyordu).
  - `flutter analyze` temiz. Doğrulamak için: `flutter run` → cold-load'da
    "NEW RUN / Choose a Modifier" overlay'i hemen görünmeli, modifier
    seçilince oyun başlamalı. Hâlâ siyah kalırsa: GameWidget'ı geçici
    olarak kaldırıp modifier overlay'in tek başına çıktığını gör; sonra
    Flame component mount sırasını araştır (`super.onLoad()` await edilmiyor
    → muhtemel kök sebep adayı).
- Review notes found two likely gameplay bugs to revisit:
  - `Frost King` is described as chain freeze, but is registered as
    `TowerType.slow`.
  - `TargetingMode.first` currently compares enemy `y` position rather than
    true path progress.
