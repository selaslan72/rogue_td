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

### 2026-04-29 — Claude oturumu (push'lanmış branch'ler)

Branch'ler `origin`'e push edildi, PR açma kararı kullanıcıya bırakıldı.

1. **`claude/fix-black-screen-on-load`** (3 commit) — kullanıcı "düzeldi" dedi.
   - `b96e2cb`: overlay'ler `Positioned.fill` + `StackFit.expand` ile tam
     ekran (modifier overlay Container küçük kalıyordu).
   - `a205ad3`: `_showModifierSelection` `Future.microtask` ile bir tick
     geciktirildi (onLoad sırasında notifier set edince ilk frame overlay
     tam render edilmiyordu).
   - `6ce9ca6`: bu handoff dosyası güncellendi.

2. **`claude/tower-models`** (1 commit) — eski 16-tower görsel set.
   - `9a64da5`: her id için ayrı silüet (yay, kılıç, namlu, snowflake,
     coil, dragon...). Sonra 5-tower geçişiyle bu büyük ölçüde aşıldı —
     ama branch hâlâ duruyor, referans için.

3. **`claude/all-towers-unlocked`** (1 commit)
   - `a5c7716`: `unlockedTowers` başlangıç değeri `TowerRegistry.all`,
     selector bar `ListView` ile yatay scroll.

4. **`claude/five-towers-with-rocks`** (1 commit, EN GÜNCEL durum)
   - `887e97b`:
     - Tower kayıtları **5'e indirildi**: archer, cannon, frost, flame,
       tesla. Tümü common; rare/legendary kaldırıldı. Card pool ve
       modifier sistemi olduğu gibi çalışıyor (her wave sonu kart pick
       artık duplicate sayılır → +30 gold).
     - `TowerComponent._renderModel` artık **(id, level)** ile dispatch
       ediyor. Her tower L1→L2→L3 boyunca görsel olarak değişir:
       * archer: küçük yay → büyük yay+sadak → çift kollu crossbow + 2 ok
       * cannon: kısa namlu → uzun+cıvatalı → çift namlu
       * frost:  6-spoke flake → 8-spoke + merkez taş → +dış kristaller
       * flame:  küçük tank+dar koni → büyük → çift nozul
       * tesla:  2 disk → 3 disk+spark → +yan mini-coil'ler
     - `RockComponent` eklendi (`lib/game/components/rock_component.dart`)
       — gri yuvarlağımsı taş + alt gölge + üst highlight, seed bazlı
       küçük varyasyon. `priority: -5` (path üstü, enemy altı; ağaçlarla
       aynı katman).
     - `GameMap`'e `rockPositions` field'ı eklendi (default boş list).
       3 haritaya da kaya eklendi: Snake 6, Zigzag 6, U-Loop 7.
     - `td_game._buildMap` + `_clearMap` `RockComponent`'i ekleyip siliyor.

   - **Doğrulama:** `flutter analyze` temiz. `flutter run` → cold-load'da
     modifier overlay → 5 tower seçicide görünmeli, slot'a koyup tap'le
     UPGRADE → her level'da silüet değişmeli; haritada ağaçların yanında
     gri kayalar olmalı.

### Sıradaki işler (öneri sırası)

- [ ] **Projectile sistemi** — şu an instant hit. Archer ok atarken
      görünür mermi, cannon top, tesla zincir bolt animasyonu eklenebilir.
- [ ] **Tower satış / yer değiştirme** — slot'a yanlış tower koyunca
      geri dönüş yok. Upgrade panel'e SELL butonu (cost'un %60'ı geri).
- [ ] **Wave preview** — sıradaki wave'in compozisyonu HUD'da küçük ikon
      olarak gösterilsin; oyuncu hazırlık yapsın.
- [ ] **Targeting mode UI** — TargetingMode enum'u var (first/strongest/
      weakest/closest) ama UI'dan değiştirilemiyor. Upgrade panel'e
      targeting toggle eklenebilir.
- [ ] **Ses** — flame_audio paketi pubspec'te yok, eklenip atış/ölüm/
      wave-clear için kısa SFX bağlanabilir.
- [ ] **Bilinen bug'lar** (eski review notları, hâlâ geçerli):
  - `TargetingMode.first` `y` koordinatı kullanıyor; gerçek waypoint
    ilerlemesine geçmeli.
  - (Frost King artık yok — 5-tower geçişiyle kalktı, bu maddeyi atla.)
- [ ] **Meta progression** (Sprint 3 planı) — sqflite ile rune sistemi,
      run'lar arası kalıcı ilerleme.

### Workflow notu

- Push memory: kullanıcı `claude/fix-black-screen-on-load`'u "çözülmüş
  push'a gerek yok" deyip sonra fikrini değiştirip "şimdi pushla" dedi
  → tüm branch'ler push edildi. Default davranış: commit ediyoruz, push
  için onay bekliyoruz (kullanıcı isteği).
