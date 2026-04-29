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

### 2026-04-29 — Codex review follow-up

- `TargetingMode.first` düzeltildi: artık düşmanları ekran `y`
  koordinatına göre değil, waypoint segmentlerindeki gerçek yol
  ilerlemesine göre seçiyor.
- `EnemyComponent.pathProgress` eklendi. Snake, Zigzag ve U-Loop gibi yön
  değiştiren yollarda "first" hedefi artık çıkışa daha yakın düşman.
- Kullanıcı kararı notu: 5 tower'ın baştan açık olması bu aşama için makul.
  Wave sonu kart seçimi şimdilik duplicate reward/ekonomi seçimine dönüşüyor;
  ileride kartlar upgrade perk, geçici buff veya run modifier seçimine
  evrilebilir.

- [x] **Projectile sistemi** — Archer ok, Cannon top projectile kullanıyor.
- [x] **Tower satış / yer değiştirme** — Upgrade panel'e SELL eklendi.
- [x] **Wave preview** — HUD sıradaki wave kompozisyonunu gösteriyor.
- [x] **Targeting mode UI** — Upgrade panel'den first/strongest/weakest/
      closest seçilebiliyor.
- [ ] **Ses** — flame_audio paketi pubspec'te yok, eklenip atış/ölüm/
      wave-clear için kısa SFX bağlanabilir.
- [ ] **Bilinen bug'lar** (eski review notları, hâlâ geçerli):
  - ~~`TargetingMode.first` `y` koordinatı kullanıyor; gerçek waypoint
    ilerlemesine geçmeli.~~ 2026-04-29 Codex tarafından düzeltildi.
  - (Frost King artık yok — 5-tower geçişiyle kalktı, bu maddeyi atla.)
- [ ] **Meta progression** (Sprint 3 planı) — sqflite ile rune sistemi,
      run'lar arası kalıcı ilerleme.

### Workflow notu

- Push memory: kullanıcı `claude/fix-black-screen-on-load`'u "çözülmüş
  push'a gerek yok" deyip sonra fikrini değiştirip "şimdi pushla" dedi
  → tüm branch'ler push edildi. Default davranış: commit ediyoruz, push
  için onay bekliyoruz (kullanıcı isteği).

### 2026-04-29 — Store araştırması / feature backlog

Kaynaklar:
- Bloons TD 6, Google Play: towers + heroes, boss events, odysseys,
  contested territory, quests, trophy/cosmetic store, community challenges.
- Kingdom Rush, Google Play/App Store: kahramanlar, tower specialization,
  farklı enemy ability'leri, spell/reinforcement komutları, achievement ve
  offline encyclopedia.
- Isle of Arrows, App Store: roguelike TD + tile placement, random rewards,
  events, game modes, modifiers, daily mode, bonus cards.
- Random Dice, App Store/Google Play: 5'li deck, merge/level-up, solo/PvP/co-op
  boss raid, season ranking.
- Arknights, Google Play/App Store: sınıf bazlı operatörler, auto-deploy,
  base construction, güçlü ses/karakter sunumu.

Projeye uygun öneriler:
- **Kısa vadeli:** wave preview, enemy encyclopedia, targeting mode UI,
  projectile görselleri, sell/undo, run sonunda ayrıntılı istatistik.
- **Roguelike kart hissi:** wave sonu kartlarını sadece duplicate gold yerine
  geçici buff, tower perk veya run modifier seçimine dönüştür.
- **Meta progression:** run sonunda rune/fragment kazan; kalıcı ama küçük
  bonuslar aç. Pay-to-win değil, "build çeşitliliği" hissi versin.
- **Content loop:** daily seed, challenge mode, boss wave modifier'ları,
  achievement görevleri.
- **Mobil kalite:** offline-first, hızlı yeniden başlatma, düşük batarya modu,
  net dokunmatik hedefler, landscape/portrait seçeneği.

### 2026-04-29 — Codex feature pass

- HUD'a **NEXT wave preview** eklendi. Sıradaki wave düşman türlerini küçük
  ikon + adet olarak gösteriyor.
- Upgrade paneline **SELL** eklendi. Tower toplam yatırımının %60'ını iade
  ediyor ve slot'u yeniden boşaltıyor.
- Wave sonu kart seçimi **tower training** sistemine çevrildi. Tüm tower'lar
  baştan açık kalıyor; seçilen kart run boyunca o tower tipine +10% damage ve
  +5% range veriyor, yanında küçük +15 gold ekonomi desteği bırakıyor.

### 2026-04-29 — Codex UI cleanup

- Bottom tower selector artık Column'da ayrı bir opaque bar değil; oyun üstünde
  sağa yaslı, yarı şeffaf kartlardan oluşan overlay.
- Selector kart yüksekliği artırıldı; Chrome'daki bottom overflow kaldırıldı.
- Tower slot görselleri daireden kare outline'a çevrildi.

### 2026-04-29 — Claude + Codex main merge

Branch `claude/five-towers-with-rocks`, `main` branch'e fast-forward merge
edildi ve GitHub'a pushlandı. `main` son commit:

- `33dc63c feat: extend U-Loop path down + denser foliage`

Bu merge ile `main` içine giren ana işler:

- Tower seti 5 archetype'a indirildi: Archer, Cannon, Frost, Flame, Tesla.
- Tüm tower'lar run başında açık; wave sonu seçimleri tower training/perk
  kararına dönüştü.
- Her tower için level bazlı özel silüet/model çizimi eklendi.
- Dekoratif `RockComponent` eklendi; haritalara taş ve daha yoğun foliage
  yerleşimleri yapıldı.
- Tower slot görselleri kare outline'a çevrildi.
- `TargetingMode.first`, ekran `y` koordinatı yerine gerçek waypoint
  ilerlemesini kullanıyor.
- Archer ve Cannon için `ProjectileComponent` eklendi; instant-hit hissi
  azaltıldı.
- Upgrade paneline targeting mode toggle eklendi: FIRST, STRONG, WEAK, CLOSE.
- Upgrade paneline SELL eklendi; yatırımın %60'ı geri veriliyor ve slot
  tekrar kullanılabilir oluyor.
- HUD'a NEXT wave preview eklendi.
- 1.5x speed toggle eklendi.
- Difficulty scaling eklendi: wave ilerledikçe enemy HP/speed ve spawn
  temposu artıyor.
- Modifier seçimi ve wave sonu seçimlerinden sonra 2 saniyelik bekleme
  kaldırıldı; akış daha hızlı başlıyor.
- U-Loop path aşağı uzatıldı, ağaç/kaya dağılımı yoğunlaştırıldı.
- Bottom selector tekrar oyun Stack'i dışındaki bottom bar'a taşındı; düşman
  overlap sorunu azaltıldı.

Doğrulama:

- `flutter analyze` temiz.
- `flutter build web` başarılı. Sadece Flutter font/icon uyarısı verdi:
  MaterialIcons bulundu, CupertinoIcons bulunamadı. Build'i engellemedi.

Kalan öneriler:

- Flame audio ile atış/ölüm/wave-clear SFX.
- Projectile sistemini Frost, Flame ve Tesla için de görsel efektlerle
  genişletmek.
- Run sonu ayrıntılı istatistik: killed, leaked, placed, sold, training picks.
- Enemy encyclopedia / wave detail panel.
- Daily seed / challenge mode.
- Meta progression: rune/fragment sistemi.
- 1.5x speed toggle şu an child component update'lerini hızlandırıyor; spawn
  timer normal `dt` ile azalıyor. Tam simülasyon hızı istenirse spawn timer da
  speed multiplier ile çalışacak şekilde revize edilebilir.
