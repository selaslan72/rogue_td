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

### 2026-05-07 — Web progress fix + BAŞLAT bug (branch `claude/web-progress-fix`)

İki commit, branch push'lanmış. **GitHub Issue #4 açık.**

1. **`ee7fead fix: ProgressService web uyumlu (sqflite → SharedPreferences)`** ✅
   - Önceki commit `26ab06b` (codex) ProgressService'i sqflite'a taşımıştı.
     Sqflite web'de native çalışmaz, `getDatabasesPath()` exception fırlatıp
     uygulama açılışta crash oluyordu (beyaz ekran).
   - SharedPreferences'a geri çevrildi: yıldızlar JSON map (`level_stars_v1`),
     fragments ayrı int key (`total_fragments_v1`).
   - API aynı (`setStars`, `addFragments`, `totalFragments`, `reset`).
   - `pubspec.yaml`'dan `sqflite`, `path`, `path_provider` silindi.
   - Web açılış sorunu çözüldü, oyun yükleniyor.

2. **`e5396a6 wip: BAŞLAT butonu görünmeme bugı`** ❌ ÇÖZÜLEMEDI
   - Web'de placement fazında BAŞLAT butonu hiçbir layout düzenlemesinde
     görünmüyor. 4 deneme yapıldı, hiçbiri çalışmadı:
     1. `Align(bottomCenter)` padding 64→24
     2. Stack `Positioned(bottom:24)` doğrudan
     3. Stack `Positioned(top:8)` doğrudan
     4. `_TopHud` Container içine wave preview altında
        `ValueListenableBuilder<bool>(placementPhaseNotifier)` ile
   - Şu an mevcut hâl: `_TopHud` içinde, hâlâ görünmüyor.
   - **Issue #4** açıldı, debug ipuçları orada.

### Bir sonraki oturum için (öncelik sırası)

1. **Issue #4 — BAŞLAT bugı debug**
   - `print()` ekle: `_enterPlacementPhase` öncesi/sonrası
     `placementPhaseNotifier.value` değeri ne?
   - `onLoad()` başında `await super.onLoad()` yap (şu an senkron çağrılıyor,
     `td_game.dart:117`)
   - Test için **koşulsuz** (her zaman görünen) buton ekle:
     - Görünüyorsa → sorun `placementPhaseNotifier`'ın true'ya hiç geçmemesi
     - Görünmüyorsa → sorun layout/clipping/container
   - `td_game.dart:118` `camera.viewfinder.visibleGameSize` web'de fail
     ediyor olabilir mi?
   - Browser DevTools Console'da kırmızı satır var mı kontrol

2. **Ses altyapısı** (önce Issue #4 çözülmeli, oyun oynanmadan ses test
   edilemez)

3. **Fragment harcama yolu** — kalıcı upgrade ekranı (rune/perk shop)

### Bilinmesi gereken
- Branch `claude/web-progress-fix` `main` ile merge edilmedi. Issue #4
  çözülünce ya tek PR olarak açılır ya da fix commit olarak kalır.
- Kullanıcı web'de oynamaya çalışıyor (Chrome). Android'de test edilmedi —
  mobilde çalışıyor olabilir; layout ya da sqflite sebebiyle değil de Flame
  web-spesifik bir bug olabilir.

---

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

### 2026-04-29 — Claude oturumu 2: spawn-timer fix + dense forest + clearables

İki ardışık iş `main`'e fast-forward merge edildi ve push edildi.

1. **`5ec7d5a fix: scale spawn timer with game speed multiplier`**
   - Codex'in raporladığı tutarsızlık kapatıldı. `td_game.dart` `update()`:
     `_spawnTimer -= dt;` → `_spawnTimer -= dt * _gameSpeed;`
   - Artık 1.5x modunda hem düşman hareketi hem spawn aralığı tutarlı.

2. **`349cf2b feat: dense forest + tappable trees/rocks open new slots`**
   - `path_data.dart` artık programatik forest generator kullanıyor:
     grid + jitter, path/slot çakışmasını filtreliyor. Step 26→20,
     pathClearance 30, slotClearance 50. Her haritada ~700-800 ağaç
     (önceki ~250'den).
   - `TreeComponent` ve `RockComponent` artık `TapCallbacks` taşıyor,
     `onTap` callback constructor'da set ediliyor (TdGame import'u
     yapmamak için — döngüsel import'tan kaçındık).
   - `TdGame._handleTreeTap` (15 gold) ve `_handleRockTap` (35 gold):
     gold düş → `ParticleEffect` → `removeFromParent()` → aynı pozisyonda
     yeni `TowerSlot` add. Tree bottomCenter anchor olduğu için slot
     pozisyonu `y - size.y/2` ile center'a kaydırılıyor.
   - `_clearMap` zaten `TreeComponent`/`RockComponent`/`TowerSlot`
     temizliyor, yeni eklenen runtime slotlar da map değişiminde gider.

**Doğrulama:** `flutter analyze` temiz (her iki commit için). Lokal
`flutter run` testi kullanıcı tarafında.

### Codex'e öneriler / dikkat edilecekler

- **Tree tap z-order:** TowerSlot, TreeComponent ve TowerComponent default
  priority 0; Tree priority -5 olduğu için slot/tower üstte kalır → tap
  onlara önce gider. Yeni komponent eklerken priority kuralına dikkat et
  (path -10, tree/rock -5, default 0, projectile 5, enemy 5).
- **Forest density performans:** her haritada ~750 `TreeComponent`. Şu an
  smooth ama daha fazla efekt eklenirse FPS izlenmeli. Olası optimizasyon:
  ağaçları statik bir `Picture`/`Sprite`'a bake'lemek (priority -5 katmanını
  tek render'a indirmek). Şimdilik gerek yok, not olarak duruyor.
- **Slot çakışma riski:** generator slotClearance 50, ama iki yakın ağaç
  birden temizlenirse iki yeni slot 20-30px arayla doğabilir → 48px slot
  kareleri görsel olarak çakışır. Gameplay etkisi minimal (her ikisine de
  tower konabilir), ama kullanıcı şikâyet ederse `_handleTreeTap` içinde
  yeni slot'tan önce mevcut slotlara mesafe kontrolü ekleyebilirsin.
- **Tap ekonomisi:** ağaç 15g / kaya 35g — tower base cost'lar ile
  uyumlu (en ucuz tower archer 50g civarı sanırım). Yeni slot açma
  ekonomisi balance test gerekiyor; çok ucuzsa map dolar, çok pahalıysa
  feature kullanılmaz.
- **Açık öneri:** ağaç temizleme şu an "tek tap → anında temizlik". Yanlış
  tap'ları engellemek için confirm step (long-press veya iki tap) eklenmesi
  düşünülebilir. Şu an deneyim için kullanıcı bilinçli tercih etti.

### 2026-04-29 — Codex aligned forest grid

- Forest generator jitter'ı kaldırıldı. Ağaçlar artık slot ölçüsüyle aynı
  ritimde, hizalı grid üstünde yerleşiyor.
- Grid step `TowerSlot.side` ile eş oranda tutuldu: 48px.
- Ağaç scale'i sabitlendi (`1.0`), böylece temizlenebilir alan ve görsel
  ölçü slotlarla daha tutarlı duruyor.
- Path clearance 36px, slot clearance 48px olarak güncellendi.

### 2026-04-29 — Claude oturumu 4: damageable obstacles tamamlandı

Branch `claude/damageable-obstacles` — 1 commit: `fd58844`

- `_fire(EnemyComponent)` → `_fire(Damageable)` düzeltildi. Obstacle path: singleTarget/splash için `ProjectileComponent`, diğer tipler için instant `takeDamage + _spawnHit`.
- `td_game.dart` tap sistemi (`_handleTreeTap`, `_handleRockTap`) kaldırıldı; cluster sistemi eklendi:
  - `_ObstacleCluster` (center + remaining Set)
  - `_buildMap`: her grid center'da 4-ağaç cluster (offsets ±10/±6px), kayalar tek elemanlı cluster. `onDestroyed` → `_onObstacleDestroyed`.
  - `_onObstacleDestroyed`: cluster'dan çıkar; empty olunca `TowerSlot` + particle ekle.
  - `_clearMap`: `_clusters.clear()` + `_nextClusterId = 0`.
- `enemy_component`: `@override` eksiklikleri giderildi.
- `withOpacity` → `withValues(alpha:)` (deprecation).
- `flutter analyze` temiz (no issues).

**Doğrulama (lokal flutter run gerekli):**
- Tower koy, wave öncesi menzilinde ağaç olsun → ~5 mermide (24 HP ÷ damage) ağaç düşmeli.
- Cluster içi 4 ağaç da düşünce center'a TowerSlot açılmalı.
- Düşman gelince tower ağacı bırakıp düşmanı hedeflemeli.
- Rock: tek başına yıkılınca da slot açılmalı.

### 2026-04-29 — Codex tower picker popup

- Bottom bar artık tower listesini göstermiyor; sadece 1x/1.5x speed button
  sol altta kalıyor.
- Boş `TowerSlot` tıklanınca slot highlight olur ve slotun üstünde küçük
  yatay tower picker popup'ı açılır.
- Popup'taki 5 tower kartından biri seçilince tower o slot'a yerleşir.
- Aynı slot'a tekrar tıklamak popup'ı kapatır.
- Tower'a veya obstacle'a tıklamak açık tower picker'ı kapatır.
- Popup konumu 480x800 world koordinatından Stack boyutuna map ediliyor ve
  ekran dışına taşmaması için clamp ediliyor.
- Doğrulama: `flutter analyze` temiz, `flutter build web` başarılı.

### Sıradaki öneriler
- Ses (flame_audio — atış/ölüm/wave-clear SFX)
- ~~Frost/Flame/Tesla için görsel projectile efektleri~~ 2026-04-29 Claude tamamladı
- ~~Hız butonu sağ üste küçük ikon~~ 2026-04-30 Claude tamamladı
- ~~4'lü ağaç cluster → tek güçlü ağaç + çalı~~ 2026-04-30 Claude tamamladı
- ~~Yerleştirme fazı — modifier sonrası START butonuyla wave başlatma~~ 2026-04-30 Claude tamamladı
- ~~Wave sonu kart seçimi → ücretsiz tower upgrade + altın sistemi~~ 2026-04-30 Claude tamamladı
- ~~Düşman taraflı modifier genişletmesi~~ 2026-04-30 Claude tamamladı
- Run sonu detaylı istatistik
- Meta progression (rune/fragment sistemi)

### 2026-04-30 — Claude oturumu 6: çok sayıda iyileştirme

#### Görsel / UX

- **Frost/Flame/Tesla projectile efektleri** (`projectile_component.dart`, `tower_component.dart`, `lightning_arc.dart`):
  - `ProjectileVisual.iceShard` — kama kristal, hedefte slow uygular
  - `ProjectileVisual.fireball` — arka alev izli top, büyük impactRadius
  - `LightningArc` yeni bileşen — Tesla chain arası 0.15s'lik zikzak yıldırım (3 katman: glow/core/beyaz)
- **Hız butonu** (`game_screen.dart`): `_BottomBar` kaldırıldı, `Positioned(top:8,right:8)` 40×40 ikon
- **Upgrade popup konumu** (`game_screen.dart`): `towerX+24` → `towerX - panelW/2` (kule merkezinin hemen üstü)

#### Orman sistemi (`tree_component.dart`, `td_game.dart`, `path_data.dart`)

- `TreeVariant` enum eklendi: `tree` (HP 85, slot açar) / `bush` (HP 22, 8g altın)
- Her grid hücresi tek engel (4'lü cluster kaldırıldı)
- `pathClearance` 36 → 64 (slot yola taşma sorunu çözüldü)

#### Oyun akışı (`td_game.dart`, `game_screen.dart`)

- **Yerleştirme fazı**: modifier seçimi sonrası wave başlamaz; `placementPhaseNotifier` ile `_PlacementOverlay` + "BAŞLAT" butonu
- **Kuleler placement'ta ateş etmez**: `tower_component.dart` update'te `placementPhaseNotifier` kontrolü
- **Wave sonu ücretsiz upgrade**: `CardPool`/training sistemi kaldırıldı; yerleştirilen kulelerden biri ücretsiz +1 level; hiç kule yoksa/hepsi max ise atlama
- **Can sistemi**: `initialLives` 20 → 10; tüm `damageOnLeak` 1; Fortified modifier kaldırıldı; `extraLives` kodu temizlendi

#### Modifier sistemi (`run_modifier.dart`, `run_stats.dart`, `modifier_registry.dart`, `enemy_component.dart`)

4 yeni düşman güçlendirme modifier'ı eklendi (toplam 11 modifier, her run 3 rastgele):
- 💪 **Titan** — +%50 düşman HP (`enemyHpBoost`)
- 💨 **Berserk** — +%35 düşman hızı (`enemySpeedBoost`)
- 🔩 **Ironclad** — tüm düşmanlara +6 flat zırh (`enemyArmorBoost`, `EnemyComponent.armorBonus` parametresi)
- 👹 **Horde** — wave başına +%40 düşman sayısı (`enemyCountBoost`, `_buildWaveList` base count çarpanı)

**Doğrulama:** `flutter analyze` temiz (tüm değişiklikler için).

### 2026-04-29 — Claude oturumu 5: Frost/Flame/Tesla görsel efektler

- `ProjectileVisual` enum'a `iceShard` ve `fireball` eklendi.
- `ProjectileComponent` → `slowAmount`, `slowDuration`, `impactRadius` parametreleri eklendi.
  İmpact'te `EnemyComponent` ise `applySlow` çağrılıyor.
- Yeni `lightning_arc.dart`: tower'dan hedefe + zincir atlamaları arasında
  kısa ömürlü (0.15s) zikzak yıldırım yayı. 3 katmanlı çizim: glow / core / beyaz merkez.
- `tower_component.dart`:
  - Frost (`TowerType.slow`) artık `ProjectileVisual.iceShard` mermi fırlatıyor
    (hız 270, impactRadius 14); hasar + slow impactta uygulanıyor.
  - Flame (`TowerType.damageOverTime`) artık `ProjectileVisual.fireball` fırlatıyor
    (hız 210, impactRadius 16; arka alev izi + parıltılı top).
  - Tesla (`TowerType.chain`) instant damage korundu + her segment için
    `LightningArc` spawn ediliyor (tower→primary, primary→chain1, chain1→chain2).
- `flutter analyze` temiz (no issues).

**Doğrulama (lokal flutter run):**
- Frost: kıyan mavi kama hedefe doğru uçmalı; çarpınca düşman yavaşlamalı.
- Flame: turuncu top + arka izi görünmeli; impactta büyük parçacık efekti.
- Tesla: atışta tower'dan düşmana şimşek yayı; chain varsa ek yay(lar) görünmeli.

### 2026-04-29 — Claude oturumu 3: damageable obstacles (TAMAMLANDI — bkz. oturum 4)

**Hedef tasarım** (kullanıcı isteği):
1. Codex'in hizalı grid'i korunsun ama her grid hücresinde **4'lü ağaç
   cluster'ı** olsun → forest yoğunluğu geri gelsin.
2. Ağaç ve kayalar tap ile değil, **menzilindeki en yakın tower'ın
   saldırısıyla** yıkılsın.
3. Birden fazla mermi gerektirsin (HP sistemi).
4. Cluster içindeki tüm ağaçlar yıkılınca o hücrede **yeni TowerSlot**
   açılsın. Kayalar tek başına bir cluster, yıkılınca da slot açılsın.

**Yapılan refactor (uncommitted, working tree dirty)**:

1. **YENİ** `lib/game/components/damageable.dart` — abstract class:
   ```dart
   abstract class Damageable {
     bool get isMounted; bool get isAlive;
     Vector2 get worldPosition; void takeDamage(double amount);
   }
   ```

2. `tree_component.dart` — TapCallbacks **kaldırıldı**. `implements
   Damageable`. `double maxHp = 24` (default), `_hp`, `takeDamage`,
   `_hitFlash` görsel beyaz parıltı. Yeni alan `int clusterId`,
   `void Function(TreeComponent)? onDestroyed` callback. HP 0'da
   `onDestroyed` çağrılır + `removeFromParent()`.

3. `rock_component.dart` — aynı pattern, `maxHp = 70`, `clusterId`,
   `onDestroyed`. TapCallbacks kaldırıldı.

4. `enemy_component.dart` — sadece `implements Damageable` eklendi.
   Mevcut isAlive/worldPosition/takeDamage zaten uyumlu.

5. `projectile_component.dart` — `target` tipi `EnemyComponent` →
   `Damageable`. Splash döngüsü `whereType<EnemyComponent>()` →
   `whereType<Damageable>()`. `identical()` ile self-skip.

6. `tower_component.dart` — `_currentTarget` tipi `Damageable?`.
   `_acquireTarget`: önce düşmanları targeting mode ile seçer; düşman
   yoksa menzildeki en yakın non-enemy Damageable'ı döndürür. Import
   eklendi.

**KALAN İŞLER (yeni oturumda devam):**

A. `tower_component.dart` `_fire(EnemyComponent target)` hâlâ
   EnemyComponent parametresi alıyor — **derleme hatası verir**, henüz
   yapılmadı. Yapılacak:
   - İmza `_fire(Damageable target)`.
   - İçinde `if (target is EnemyComponent) { ... mevcut switch ... } else
     { /* obstacle path */ }`.
   - Obstacle path: singleTarget/splash için `ProjectileComponent` ile
     uçur (target Damageable kabul ediyor); diğer tipler (slow/dot/chain)
     için instant `target.takeDamage(currentDamage)` + `_spawnHit`.
   - `_aimAngle()` içinde `_currentTarget!.worldPosition` Damageable'da
     mevcut, sorun olmaz. Sadece `EnemyComponent`'a özel referans varsa
     güncelle (muzzle dir, render).
   - `render`'daki `_currentTarget!.worldPosition - position` zaten
     Damageable üstünden çalışır — ama `_muzzleFlash` blockunda
     `_currentTarget!.worldPosition` çağrısı kontrol edilmeli.

B. `td_game.dart` cluster sistemi:
   - State: `final Map<int, _ObstacleCluster> _clusters = {};` ve
     `int _nextClusterId = 0;` (private class _ObstacleCluster: center
     Vector2, remaining: Set<PositionComponent>).
   - `_buildMap` içinde:
     - Tree positions artık her merkez için **4 ağaç** üretsin (offsets
       ör. `(-10,-6), (10,-6), (-6,8), (8,8)` `Vector2`'lar). Hepsine
       aynı `clusterId`, callback `_onObstacleDestroyed`. Cluster center
       grid noktasının kendisi.
     - Rock için her kaya tek elemanlı cluster, callback `_onObstacleDestroyed`.
   - `_onObstacleDestroyed(PositionComponent obstacle)`:
     - `clusterId` üzerinden cluster'ı bul, remaining setinden çıkar.
     - Empty olduysa `add(TowerSlot(worldPosition: cluster.center,
       onTap: _handleSlotTap))` + `ParticleEffect`.
     - Cluster'ı map'ten sil.
   - `_handleTreeTap` ve `_handleRockTap` **silinecek** (artık tap yok).
     Tree/Rock constructor'larından `onTap` parametresi kalktı zaten.

C. `path_data.dart` değişmesin — forest generator hizalı grid center
   listesi döndürmeye devam ediyor. Cluster spawn'ı td_game tarafında.

D. Doğrulama: `flutter analyze` temiz olmalı, lokal `flutter run` ile
   test:
   - 1. wave öncesi tower koy, menzilinde ağaç olsun → ateş etmeli, ~5
     mermide (24/5 ≈ 5 hit) ağaç düşmeli.
   - Bir cluster'daki 4 ağaç da düşünce yerine slot açılmalı.
   - Düşman gelince tower ağacı bırakıp düşmanı vurmalı.

**Branch öneri**: Çalışmayı `claude/damageable-obstacles` branch'inde
toparla. Şu an `main` üzerindeyiz, working tree dirty.

**Açık tasarım kararları (yeni oturumda netleşecek)**:
- Tree maxHp 24, Rock maxHp 70 — ilk tahmin, balance test gerekiyor.
- Cluster içi ağaç pozisyonları sabit offsets mı yoksa seed bazlı jitter
  mı? Şu an plan: sabit offsetler (deterministik).
- Tower obstacle vururken slow/dot/chain skip — obstacle'a sadece direct
  damage. Frost ağaçı yavaşlatmaz, mantıklı.
- Cluster yıkıldıktan sonra particle rengi: yeşil (ağaç) / gri (kaya).

### 2026-04-29 — Codex compact upgrade popup

- Upgrade panel eski alt modal görünümünden çıkarıldı; seçili kulenin sağ
  üstüne yakın konumlanan kompakt popup olarak tasarlandı.
- Popup 252px genişlikte tutuldu ve 480x800 world koordinatından ekrana
  çevrilerek kenarlardan taşmayacak şekilde clamp ediliyor.
- Header, stat değerleri, targeting butonları, upgrade ve sell aksiyonları
  küçültüldü; panel oyun alanını daha az kaplıyor.
- Doğrulama: `flutter analyze` temiz, `flutter build web` başarılı.

### 2026-04-30 — Codex denser forest and rocks

- Orman grid adımı 48px'ten 40px'e indirildi; path/slot/kaya clearance
  değerleri hafif azaltılarak ağaçlar daha sık, ama yol ve kule slotları
  okunur kalacak şekilde yerleşiyor.
- Snake kaya sayısı 6'dan 10'a, Zigzag 6'dan 10'a, U-Loop 6'dan 9'a
  çıkarıldı.
- Doğrulama: `flutter analyze` temiz, `flutter build web` başarılı.
