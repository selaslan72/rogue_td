import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../data/enemy_registry.dart';
import '../data/modifier_registry.dart';
import '../data/tower_registry.dart';
import '../models/enemy_def.dart';
import '../models/run_modifier.dart';
import '../models/run_result.dart';
import '../models/run_stats.dart';
import '../models/tower_card.dart';
import 'card_pool.dart';
import 'components/castle_component.dart';
import 'components/enemy_component.dart';
import 'components/path_component.dart';
import 'components/rock_component.dart';
import 'components/tower_component.dart';
import 'components/tower_slot.dart';
import 'components/tree_component.dart';
import 'path_data.dart';

/// Ana FlameGame. Run state'ini kendi içinde tutar (Riverpod yok).
/// 15 wave / run, wave 5+10 mini-boss, wave 15 final boss.
/// Run bitince sonuç overlay'i, "NEW RUN" → yeni harita + yeni modifier.
class TdGame extends FlameGame with HasGameReference {
  // ─── Run state ─────────────────────────────────────────────────────────────
  static const int maxWaves = 15;
  static const int initialLives = 20;
  static const int initialGold = 200;

  int lives = initialLives;
  int gold = initialGold;
  int wave = 0;
  int waveEnemiesRemaining = 0;
  bool waveActive = false;
  bool runEnded = false;

  GameMap currentMap = PathData.snake;
  RunModifier? activeModifier;
  final RunStats stats = RunStats();
  final List<TowerCard> unlockedTowers = List.from(TowerRegistry.all);

  // ─── Notifier'lar (UI'ya yansır) ──────────────────────────────────────────
  final ValueNotifier<int> livesNotifier = ValueNotifier(initialLives);
  final ValueNotifier<int> goldNotifier = ValueNotifier(initialGold);
  final ValueNotifier<int> waveNotifier = ValueNotifier(0);
  final ValueNotifier<String?> messageNotifier = ValueNotifier(null);
  final ValueNotifier<List<EnemyDef>> wavePreviewNotifier = ValueNotifier([]);
  final ValueNotifier<List<TowerCard>> unlockedNotifier = ValueNotifier(
    List.from(TowerRegistry.all),
  );

  TowerCard selectedTower = TowerRegistry.archer;
  final ValueNotifier<TowerCard> selectedTowerNotifier = ValueNotifier(
    TowerRegistry.archer,
  );

  final ValueNotifier<TowerComponent?> selectedExistingTowerNotifier =
      ValueNotifier(null);

  // Wave sonu kart seçimi
  final ValueNotifier<List<TowerCard>?> cardSelectNotifier = ValueNotifier(
    null,
  );

  // Run başı modifier seçimi (3 RunModifier)
  final ValueNotifier<List<RunModifier>?> modifierSelectNotifier =
      ValueNotifier(null);

  // Run sonu sonuç overlay'i
  final ValueNotifier<RunResult?> runResultNotifier = ValueNotifier(null);

  late CardPool cardPool;

  // Hız çarpanı — 1.0 (normal) veya 1.5 (hızlı)
  double _gameSpeed = 1.0;
  final ValueNotifier<bool> speedUpNotifier = ValueNotifier(false);

  void toggleSpeed() {
    speedUpNotifier.value = !speedUpNotifier.value;
    _gameSpeed = speedUpNotifier.value ? 1.5 : 1.0;
  }

  // Wave spawning
  double _spawnTimer = 0;
  double _spawnInterval = 1.5;
  final List<EnemyDef> _waveQueue = [];

  @override
  Color backgroundColor() => const Color(0xFF0D1A0D);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    camera.viewfinder.visibleGameSize = Vector2(480, 800);
    cardPool = CardPool(TowerRegistry.all);
    _buildMap(PathData.random());
    _updateWavePreview();
    // İlk run modifier seçimi — overlay açılır, oyuncu bir modifier seçer
    _showModifierSelection();
  }

  // ─── Harita kurulumu ──────────────────────────────────────────────────────

  void _buildMap(GameMap map) {
    currentMap = map;

    add(PathComponent(waypoints: map.waypoints, pathWidth: PathData.pathWidth));

    add(CastleComponent(worldPosition: map.waypoints.first, isEntry: true));
    add(CastleComponent(worldPosition: map.waypoints.last, isEntry: false));

    for (final (x, y, treeScale) in map.treePositions) {
      add(TreeComponent(worldPosition: Vector2(x, y), sizeScale: treeScale));
    }

    int rockSeed = 0;
    for (final (x, y, rockScale) in map.rockPositions) {
      add(
        RockComponent(
          worldPosition: Vector2(x, y),
          sizeScale: rockScale,
          seed: rockSeed++,
        ),
      );
    }

    for (final slotPos in map.towerSlots) {
      add(TowerSlot(worldPosition: slotPos, onTap: _handleSlotTap));
    }
  }

  /// Tüm gameplay component'larını siler — yeni map için temizlik.
  void _clearMap() {
    final removable = children
        .where(
          (c) =>
              c is PathComponent ||
              c is CastleComponent ||
              c is TreeComponent ||
              c is RockComponent ||
              c is TowerSlot ||
              c is TowerComponent ||
              c is EnemyComponent,
        )
        .toList();
    for (final c in removable) {
      c.removeFromParent();
    }
  }

  // ─── Slot / Tower etkileşimleri ───────────────────────────────────────────

  void _handleSlotTap(TowerSlot slot) {
    if (runEnded) return;
    if (slot.isOccupied) return;
    if (gold < selectedTower.baseCost) {
      _flashMessage('Not enough gold (${selectedTower.baseCost})');
      return;
    }
    gold -= selectedTower.baseCost;
    goldNotifier.value = gold;

    slot.isOccupied = true;
    _clearSelectedExisting();
    add(
      TowerComponent(
        card: selectedTower,
        worldPosition: slot.position,
        onTap: _handleTowerTap,
        stats: stats,
        slot: slot,
      ),
    );
  }

  void selectTower(TowerCard card) {
    selectedTower = card;
    selectedTowerNotifier.value = card;
    _clearSelectedExisting();
  }

  void _handleTowerTap(TowerComponent tower) {
    final prev = selectedExistingTowerNotifier.value;
    if (prev != null) prev.showRange = false;
    if (prev == tower) {
      tower.showRange = false;
      selectedExistingTowerNotifier.value = null;
    } else {
      tower.showRange = true;
      selectedExistingTowerNotifier.value = tower;
    }
  }

  void _clearSelectedExisting() {
    selectedExistingTowerNotifier.value?.showRange = false;
    selectedExistingTowerNotifier.value = null;
  }

  void tryUpgradeTower(TowerComponent tower) {
    if (!tower.canUpgrade) return;
    final cost = tower.upgradeCost;
    if (gold < cost) {
      _flashMessage('Not enough gold ($cost)');
      return;
    }
    gold -= cost;
    goldNotifier.value = gold;
    tower.upgrade();
    tower.investedGold += cost;
    // Range circle gitsin ama panel açık kalsın (üst üste upgrade için)
    tower.showRange = false;
    selectedExistingTowerNotifier.value = null;
    selectedExistingTowerNotifier.value = tower;
  }

  void sellTower(TowerComponent tower) {
    if (runEnded) return;
    final refund = (tower.investedGold * 0.6).round();
    gold += refund;
    goldNotifier.value = gold;
    tower.slot.isOccupied = false;
    tower.showRange = false;
    selectedExistingTowerNotifier.value = null;
    tower.removeFromParent();
    _flashMessage('Sold ${tower.card.name} (+$refund gold)');
  }

  // ─── Wave akışı ───────────────────────────────────────────────────────────

  void startNextWave() {
    if (runEnded) return;
    if (wave >= maxWaves) {
      _endRun(victory: true);
      return;
    }
    wave++;
    waveNotifier.value = wave;
    _buildWaveQueue(wave);
    _updateWavePreview();
    waveEnemiesRemaining = _waveQueue.length;
    waveActive = true;
    _spawnTimer = 0;
    // Boss wave'lerde daha geniş aralık; normal wave'lerde wave'le birlikte kısalsın
    _spawnInterval = wave == maxWaves
        ? 2.0
        : (wave == 5 || wave == 10
              ? 1.8
              : (1.5 - (wave - 1) * 0.06).clamp(0.55, 1.5));
    _flashMessage(
      wave == maxWaves
          ? 'FINAL BOSS'
          : (wave == 5 || wave == 10 ? 'BOSS WAVE $wave' : 'WAVE $wave'),
    );
  }

  /// Wave'in spawn kuyruğunu önceden hazırlar.
  void _buildWaveQueue(int w) {
    _waveQueue.clear();
    _waveQueue.addAll(_buildWaveList(w));
  }

  List<EnemyDef> _buildWaveList(int w) {
    final result = <EnemyDef>[];
    if (w == maxWaves) {
      // Final boss + adds
      result.add(EnemyRegistry.finalBoss);
      result.addAll(List.filled(8, EnemyRegistry.tank));
      result.addAll(List.filled(6, EnemyRegistry.basic));
      return result;
    }
    if (w == 5 || w == 10) {
      result.add(EnemyRegistry.miniBoss);
      result.addAll(List.filled(w == 10 ? 8 : 5, EnemyRegistry.basic));
      result.addAll(List.filled(w == 10 ? 4 : 2, EnemyRegistry.tank));
      return result;
    }
    final base = 8 + w * 2;
    for (int i = 0; i < base; i++) {
      EnemyDef pick;
      if (w >= 7 && i % 4 == 0) {
        pick = EnemyRegistry.flying;
      } else if (w >= 6 && i % 5 == 0) {
        pick = EnemyRegistry.tank;
      } else if (w >= 3 && i % 3 == 0) {
        pick = EnemyRegistry.fast;
      } else {
        pick = EnemyRegistry.basic;
      }
      result.add(pick);
    }
    return result;
  }

  void _updateWavePreview() {
    final nextWave = wave + 1;
    wavePreviewNotifier.value = nextWave <= maxWaves && !runEnded
        ? _buildWaveList(nextWave)
        : [];
  }

  void _flashMessage(String msg) {
    messageNotifier.value = msg;
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (messageNotifier.value == msg) messageNotifier.value = null;
    });
  }

  @override
  void update(double dt) {
    super.update(dt * _gameSpeed);
    if (runEnded) return;

    if (waveActive && _waveQueue.isNotEmpty) {
      _spawnTimer -= dt * _gameSpeed;
      if (_spawnTimer <= 0) {
        _spawnNextEnemy();
        _spawnTimer = _spawnInterval;
      }
    } else if (waveActive && _waveQueue.isEmpty && waveEnemiesRemaining == 0) {
      final enemiesAlive = children.whereType<EnemyComponent>().isNotEmpty;
      if (!enemiesAlive) {
        waveActive = false;
        gold += wave == maxWaves ? 0 : (wave == 5 || wave == 10 ? 100 : 50);
        goldNotifier.value = gold;
        if (wave >= maxWaves) {
          _endRun(victory: true);
        } else {
          _showCardSelection();
        }
      }
    }
  }

  void _spawnNextEnemy() {
    if (_waveQueue.isEmpty) return;
    final def = _waveQueue.removeAt(0);
    // Wave bazlı zorluk: HP %8/wave, hız %2/wave artar
    final waveHpScale = 1.0 + (wave - 1) * 0.08;
    final waveSpeedScale = 1.0 + (wave - 1) * 0.02;
    add(
      EnemyComponent(
        def: def,
        waypoints: currentMap.waypoints,
        onKilled: _onEnemyKilled,
        onLeaked: _onEnemyLeaked,
        hpMultiplier: stats.enemyHpMul * waveHpScale,
        speedMultiplier: stats.enemySpeedMul * waveSpeedScale,
      ),
    );
    waveEnemiesRemaining = _waveQueue.length;
  }

  void _onEnemyKilled(EnemyComponent enemy) {
    final reward = (enemy.def.goldReward * stats.goldMul).round();
    gold += reward;
    goldNotifier.value = gold;
  }

  void _onEnemyLeaked(EnemyComponent enemy) {
    lives -= enemy.def.damageOnLeak;
    if (lives < 0) lives = 0;
    livesNotifier.value = lives;
    if (lives == 0) {
      _endRun(victory: false);
    }
  }

  // ─── Kart seçim akışı (wave sonu) ─────────────────────────────────────────

  void _showCardSelection() {
    final offered = cardPool.drawThree();
    for (final c in offered) {
      cardPool.onOffered(c);
    }
    cardSelectNotifier.value = offered;
    pauseEngine();
  }

  void pickCard(TowerCard card) {
    stats.trainTower(card.id);
    gold += 15;
    goldNotifier.value = gold;
    _flashMessage(
      '${card.name} training Lv.${stats.towerTrainingLevel(card.id)}',
    );
    cardPool.onPicked(card);
    cardPool.recoverWeights();
    cardSelectNotifier.value = null;
    resumeEngine();
    if (!runEnded && lives > 0) startNextWave();
  }

  // ─── Modifier seçim akışı (run başı) ──────────────────────────────────────

  void _showModifierSelection() {
    // Bir tick geciktir: cold-load'da onLoad henüz bitmeden notifier'ı
    // tetiklersek widget tree ilk frame'de overlay'i tam çizemiyor.
    Future.microtask(() {
      modifierSelectNotifier.value = ModifierRegistry.drawThree();
    });
  }

  void pickModifier(RunModifier mod) {
    activeModifier = mod;
    stats.reset();
    stats.apply(mod);

    // Tek seferlik etkiler
    if (mod.kind == ModifierKind.startingGold) {
      gold = initialGold + mod.value.round();
      goldNotifier.value = gold;
    }
    if (mod.kind == ModifierKind.extraLives) {
      lives = initialLives + mod.value.round();
      livesNotifier.value = lives;
    }

    modifierSelectNotifier.value = null;
    resumeEngine();
    startNextWave();
  }

  // ─── Run sonlandırma + yeni run ───────────────────────────────────────────

  void _endRun({required bool victory}) {
    if (runEnded) return;
    runEnded = true;
    waveActive = false;
    final towers = children
        .whereType<TowerComponent>()
        .map((t) => t.card)
        .toSet()
        .toList();
    runResultNotifier.value = RunResult(
      victory: victory,
      waveReached: wave,
      finalGold: gold,
      mapName: currentMap.name,
      modifier: activeModifier,
      towersUsed: towers,
    );
    pauseEngine();
  }

  /// Yeni run başlat — yeni harita, sıfırlanmış state, yeni modifier seçimi.
  void startNewRun() {
    // State sıfırla
    runEnded = false;
    lives = initialLives;
    gold = initialGold;
    wave = 0;
    waveEnemiesRemaining = 0;
    waveActive = false;
    _waveQueue.clear();
    _spawnTimer = 0;

    livesNotifier.value = lives;
    goldNotifier.value = gold;
    waveNotifier.value = 0;
    messageNotifier.value = null;
    wavePreviewNotifier.value = [];
    runResultNotifier.value = null;

    activeModifier = null;
    stats.reset();
    unlockedTowers
      ..clear()
      ..addAll(TowerRegistry.all);
    unlockedNotifier.value = List.from(unlockedTowers);
    selectedTower = TowerRegistry.archer;
    selectedTowerNotifier.value = TowerRegistry.archer;
    selectedExistingTowerNotifier.value = null;

    cardPool = CardPool(TowerRegistry.all);

    _clearMap();
    _buildMap(PathData.random());
    _updateWavePreview();
    resumeEngine();
    _showModifierSelection();
  }
}
