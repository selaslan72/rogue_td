import 'dart:math' as math;

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
import 'components/castle_component.dart';
import 'components/damageable.dart';
import 'components/enemy_component.dart';
import 'components/particle_effect.dart';
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
  static const int initialLives = 10;
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
  final ValueNotifier<TowerSlot?> pendingTowerSlotNotifier = ValueNotifier(
    null,
  );

  // Wave sonu ücretsiz upgrade seçimi
  final ValueNotifier<List<TowerComponent>?> upgradePickNotifier =
      ValueNotifier(null);

  // Run başı modifier seçimi (3 RunModifier)
  final ValueNotifier<List<RunModifier>?> modifierSelectNotifier =
      ValueNotifier(null);

  // Run sonu sonuç overlay'i
  final ValueNotifier<RunResult?> runResultNotifier = ValueNotifier(null);

  // Yerleştirme fazı — modifier seçildikten sonra, wave başlamadan önce
  final ValueNotifier<bool> placementPhaseNotifier = ValueNotifier(false);


  // Obstacle cluster state
  final Map<int, _ObstacleCluster> _clusters = {};
  int _nextClusterId = 0;

  // Kullanıcı tarafından tıklanan ve tower'ların hedeflediği tek engel.
  // Null ise tower'lar sadece düşmanlara saldırır.
  Damageable? _selectedObstacle;
  Damageable? get selectedObstacle => _selectedObstacle;

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
    _buildMap(PathData.random());
    _updateWavePreview();
    // İlk run modifier seçimi — overlay açılır, oyuncu bir modifier seçer
    _showModifierSelection();
  }

  // ─── Harita kurulumu ──────────────────────────────────────────────────────

  static final _forestRng = math.Random();

  void _buildMap(GameMap map) {
    currentMap = map;
    _clusters.clear();
    _nextClusterId = 0;

    add(PathComponent(waypoints: map.waypoints, pathWidth: PathData.pathWidth));
    add(CastleComponent(worldPosition: map.waypoints.first, isEntry: true));
    add(CastleComponent(worldPosition: map.waypoints.last, isEntry: false));

    for (final (cx, cy, _) in map.treePositions) {
      final id = _nextClusterId++;
      final center = Vector2(cx, cy);
      // %30 çalı, %70 güçlü ağaç
      final variant = _forestRng.nextDouble() < 0.30
          ? TreeVariant.bush
          : TreeVariant.tree;
      final tree = TreeComponent(
        worldPosition: center.clone(),
        sizeScale: 1.0,
        variant: variant,
        clusterId: id,
        onDestroyed: (t) => _onObstacleDestroyed(t, t.clusterId),
        onTap: _handleTreeTap,
      );
      _clusters[id] = _ObstacleCluster(center: center, remaining: {tree});
      add(tree);
    }

    int rockSeed = 0;
    for (final (rx, ry, _) in map.rockPositions) {
      final id = _nextClusterId++;
      final center = Vector2(rx, ry);
      final rock = RockComponent(
        worldPosition: center.clone(),
        sizeScale: 1.0,
        seed: rockSeed++,
        clusterId: id,
        onDestroyed: (r) => _onObstacleDestroyed(r, r.clusterId),
        onTap: _handleRockTap,
      );
      _clusters[id] = _ObstacleCluster(center: center, remaining: {rock});
      add(rock);
    }

    for (final slotPos in map.towerSlots) {
      add(TowerSlot(worldPosition: slotPos, onTap: _handleSlotTap));
    }
  }

  void _handleTreeTap(TreeComponent tree) => _toggleObstacleSelection(tree);
  void _handleRockTap(RockComponent rock) => _toggleObstacleSelection(rock);

  void _toggleObstacleSelection(Damageable target) {
    if (runEnded) return;
    _clearPendingTowerSlot();
    if (identical(_selectedObstacle, target)) {
      _setObstacleSelected(target, false);
      _selectedObstacle = null;
      return;
    }
    if (_selectedObstacle != null) {
      _setObstacleSelected(_selectedObstacle!, false);
    }
    _selectedObstacle = target;
    _setObstacleSelected(target, true);
  }

  void _setObstacleSelected(Damageable d, bool value) {
    if (d is TreeComponent) d.selected = value;
    if (d is RockComponent) d.selected = value;
  }

  void _onObstacleDestroyed(PositionComponent obstacle, int clusterId) {
    if (identical(_selectedObstacle, obstacle)) {
      _selectedObstacle = null;
    }
    final cluster = _clusters[clusterId];
    if (cluster == null) return;
    cluster.remaining.remove(obstacle);
    if (cluster.remaining.isEmpty) {
      _clusters.remove(clusterId);
      final isBush =
          obstacle is TreeComponent && obstacle.variant == TreeVariant.bush;
      final particleColor = obstacle is RockComponent
          ? const Color(0xFFB7BFCB)
          : isBush
              ? const Color(0xFF48902E)
              : const Color(0xFF4A8A3A);
      add(
        ParticleEffect(
          worldPosition: cluster.center.clone(),
          color: particleColor,
          duration: 0.4,
          maxRadius: isBush ? 12 : 18,
        ),
      );
      if (isBush) {
        // Çalı → slot yok, küçük altın ödülü
        gold += 8;
        goldNotifier.value = gold;
      } else {
        add(TowerSlot(
            worldPosition: cluster.center.clone(), onTap: _handleSlotTap));
      }
    }
  }

  /// Tüm gameplay component'larını siler — yeni map için temizlik.
  void _clearMap() {
    _clusters.clear();
    _nextClusterId = 0;
    _selectedObstacle = null;
    _clearPendingTowerSlot();
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
    if (pendingTowerSlotNotifier.value == slot) {
      _clearPendingTowerSlot();
      return;
    }
    _clearSelectedExisting();
    _clearPendingTowerSlot();
    slot.isHighlighted = true;
    pendingTowerSlotNotifier.value = slot;
  }

  void placeTowerFromPicker(TowerCard card) {
    final slot = pendingTowerSlotNotifier.value;
    if (slot == null || runEnded || slot.isOccupied) return;
    if (gold < card.baseCost) {
      _flashMessage('Not enough gold (${card.baseCost})');
      return;
    }
    selectedTower = card;
    selectedTowerNotifier.value = card;
    gold -= card.baseCost;
    goldNotifier.value = gold;

    slot.isOccupied = true;
    slot.isHighlighted = false;
    pendingTowerSlotNotifier.value = null;
    _clearSelectedExisting();
    add(
      TowerComponent(
        card: card,
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
    _clearPendingTowerSlot();
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

  void _clearPendingTowerSlot() {
    pendingTowerSlotNotifier.value?.isHighlighted = false;
    pendingTowerSlotNotifier.value = null;
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
    final base = ((8 + w * 2) * stats.enemyCountMul).round();
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
          _showWaveReward();
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
        armorBonus: stats.enemyArmorBonus,
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

  // ─── Wave sonu ücretsiz upgrade seçimi ────────────────────────────────────

  void _showWaveReward() {
    final upgradeable = children
        .whereType<TowerComponent>()
        .where((t) => t.canUpgrade)
        .toList();
    if (upgradeable.isEmpty) {
      if (!runEnded && lives > 0) startNextWave();
      return;
    }
    upgradePickNotifier.value = upgradeable;
    pauseEngine();
  }

  void pickTowerUpgrade(TowerComponent? tower) {
    if (tower != null && tower.isMounted && tower.canUpgrade) {
      tower.upgrade();
      _flashMessage('${tower.card.name} → Lv.${tower.level}');
    }
    upgradePickNotifier.value = null;
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

    modifierSelectNotifier.value = null;
    resumeEngine();
    placementPhaseNotifier.value = true;
  }

  /// Oyuncu tower kurumunu bitirip START'a bastığında çağrılır.
  void startFirstWave() {
    placementPhaseNotifier.value = false;
    startNextWave();
  }

  // ─── Run sonlandırma + yeni run ───────────────────────────────────────────

  void _endRun({required bool victory}) {
    if (runEnded) return;
    runEnded = true;
    waveActive = false;
    _clearPendingTowerSlot();
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

  /// Yeni run: harita + state tamamen sıfırlanır, yeni modifier seçimi açılır.
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
    upgradePickNotifier.value = null;
    placementPhaseNotifier.value = false;

    activeModifier = null;
    stats.reset();
    unlockedTowers
      ..clear()
      ..addAll(TowerRegistry.all);
    unlockedNotifier.value = List.from(unlockedTowers);
    selectedTower = TowerRegistry.archer;
    selectedTowerNotifier.value = TowerRegistry.archer;
    selectedExistingTowerNotifier.value = null;

    _clearMap();
    _buildMap(PathData.random());
    _updateWavePreview();
    resumeEngine();
    _showModifierSelection();
  }
}

class _ObstacleCluster {
  final Vector2 center;
  final Set<PositionComponent> remaining;
  _ObstacleCluster({required this.center, required this.remaining});
}
