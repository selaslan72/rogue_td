import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/level_registry.dart';
import '../game/components/tower_slot.dart';
import '../game/components/tower_component.dart';
import '../game/td_game.dart';
import '../models/enemy_def.dart';
import '../models/level_def.dart';
import '../models/run_modifier.dart';
import '../models/run_result.dart';
import '../models/tower_card.dart';
import '../services/progress_service.dart';

/// GameWidget'ı saran ekran. HUD overlay + tower seçici barı içerir.
class GameScreen extends StatefulWidget {
  final LevelDef level;
  const GameScreen({super.key, required this.level});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final TdGame _game;

  @override
  void initState() {
    super.initState();
    _game = TdGame(
      level: widget.level,
      onExitToLevels: () => Navigator.of(context).pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      body: SafeArea(
        child: Column(
          children: [
            _TopHud(game: _game),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  GameWidget(game: _game),
                  Positioned.fill(child: _SlotTowerPickerOverlay(game: _game)),
                  Positioned.fill(child: _UpgradeOverlay(game: _game)),
                  Positioned.fill(child: _WaveRewardOverlay(game: _game)),
                  Positioned.fill(child: _ModifierSelectOverlay(game: _game)),
                  Positioned.fill(child: _RunResultOverlay(game: _game)),
                  Positioned.fill(child: _PlacementOverlay(game: _game)),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _SpeedButton(game: _game),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _SlotTowerPickerOverlay extends StatelessWidget {
  final TdGame game;
  const _SlotTowerPickerOverlay({required this.game});

  static const double _worldW = 480;
  static const double _worldH = 800;
  static const double _pickerW = 470;
  static const double _pickerH = 96;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TowerSlot?>(
      valueListenable: game.pendingTowerSlotNotifier,
      builder: (_, slot, _) {
        if (slot == null) return const SizedBox.shrink();
        return LayoutBuilder(
          builder: (_, constraints) {
            final pickerW = constraints.maxWidth < _pickerW + 16
                ? constraints.maxWidth - 16
                : _pickerW;
            final scaleX = constraints.maxWidth / _worldW;
            final scaleY = constraints.maxHeight / _worldH;
            final slotX = slot.position.x * scaleX;
            final slotY = slot.position.y * scaleY;
            final left = (slotX - pickerW / 2).clamp(
              8.0,
              constraints.maxWidth - pickerW - 8.0,
            );
            final top = (slotY - _pickerH - 18).clamp(
              8.0,
              constraints.maxHeight - _pickerH - 8.0,
            );

            return Stack(
              children: [
                Positioned(
                  left: left,
                  top: top,
                  width: pickerW,
                  height: _pickerH,
                  child: _TowerSelector(game: game),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _TopHud extends StatelessWidget {
  final TdGame game;
  const _TopHud({required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF1A1A2E),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ValueListenableBuilder<int>(
                valueListenable: game.livesNotifier,
                builder: (_, lives, _) => _HudChip(
                  icon: '❤️',
                  label: '$lives',
                  color: const Color(0xFFEF4444),
                ),
              ),
              Column(
                children: [
                  ValueListenableBuilder<LevelDef>(
                    valueListenable: game.levelNotifier,
                    builder: (_, lv, _) => Text(
                      'BÖLÜM ${lv.id}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  ValueListenableBuilder<int>(
                    valueListenable: game.waveNotifier,
                    builder: (_, wave, _) => Text(
                      'WAVE $wave / ${TdGame.maxWaves}',
                      style: const TextStyle(
                        color: Color(0xFFFBBF24),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  ValueListenableBuilder<String?>(
                    valueListenable: game.messageNotifier,
                    builder: (_, msg, _) => SizedBox(
                      height: 16,
                      child: msg == null
                          ? null
                          : Text(
                              msg,
                              style: const TextStyle(
                                color: Color(0xFFFBBF24),
                                fontSize: 11,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              ValueListenableBuilder<int>(
                valueListenable: game.goldNotifier,
                builder: (_, gold, _) => _HudChip(
                  icon: '💰',
                  label: '$gold',
                  color: const Color(0xFFFBBF24),
                ),
              ),
            ],
          ),
          ValueListenableBuilder<List<EnemyDef>>(
            valueListenable: game.wavePreviewNotifier,
            builder: (_, preview, _) => _WavePreview(enemies: preview),
          ),
        ],
      ),
    );
  }
}

class _WavePreview extends StatelessWidget {
  final List<EnemyDef> enemies;
  const _WavePreview({required this.enemies});

  static const _enemyIcons = {
    EnemyKind.fast: '⚡',
    EnemyKind.basic: '●',
    EnemyKind.tank: '■',
    EnemyKind.flying: '◆',
    EnemyKind.boss: '★',
  };

  @override
  Widget build(BuildContext context) {
    if (enemies.isEmpty) return const SizedBox.shrink();
    final counts = <EnemyKind, int>{};
    for (final enemy in enemies) {
      counts[enemy.kind] = (counts[enemy.kind] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'NEXT',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(width: 8),
          ...counts.entries.map(
            (entry) => Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                '${_enemyIcons[entry.key]} ${entry.value}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HudChip extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  const _HudChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _UpgradeOverlay extends StatelessWidget {
  final TdGame game;
  const _UpgradeOverlay({required this.game});

  static const double _worldW = 480;
  static const double _worldH = 800;
  static const double _panelW = 252;
  static const double _panelH = 174;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TowerComponent?>(
      valueListenable: game.selectedExistingTowerNotifier,
      builder: (_, tower, _) {
        if (tower == null) return const SizedBox.shrink();
        // Gold değişince butonun aktif/pasif durumu da güncellensin
        return ValueListenableBuilder<int>(
          valueListenable: game.goldNotifier,
          builder: (_, _, _) => LayoutBuilder(
            builder: (_, constraints) {
              final scaleX = constraints.maxWidth / _worldW;
              final scaleY = constraints.maxHeight / _worldH;
              final towerX = tower.position.x * scaleX;
              final towerY = tower.position.y * scaleY;
              final left = (towerX - _panelW / 2).clamp(
                8.0,
                constraints.maxWidth - _panelW - 8.0,
              );
              final top = (towerY - _panelH - 28).clamp(
                8.0,
                constraints.maxHeight - _panelH - 8.0,
              );
              return Stack(
                children: [
                  Positioned(
                    left: left,
                    top: top,
                    width: _panelW,
                    child: _UpgradePanel(game: game, tower: tower),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _UpgradePanel extends StatelessWidget {
  final TdGame game;
  final TowerComponent tower;
  const _UpgradePanel({required this.game, required this.tower});

  @override
  Widget build(BuildContext context) {
    final card = tower.card;
    final lvl = tower.level;
    final canUp = tower.canUpgrade;
    final cost = tower.upgradeCost;
    final hasGold = game.gold >= cost;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xE61A1A2E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: card.color, width: 1.25),
        boxShadow: const [
          BoxShadow(
            color: Color(0x88000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(card.icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${card.name} Lv.$lvl',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => game.selectedExistingTowerNotifier.value = null,
                child: const Icon(Icons.close, color: Colors.white54, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatChip(
                label: 'DMG',
                value: tower.currentDamage.toStringAsFixed(1),
              ),
              _StatChip(
                label: 'RNG',
                value: tower.currentRange.toStringAsFixed(0),
              ),
              _StatChip(
                label: 'SPD',
                value: tower.currentFireRate.toStringAsFixed(2),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _TargetingRow(game: game, tower: tower),
          const SizedBox(height: 8),
          if (!canUp)
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'MAX LEVEL',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFFBBF24),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                _SellButton(game: game, tower: tower),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: hasGold
                        ? () => game.tryUpgradeTower(tower)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasGold ? card.color : Colors.white12,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      hasGold ? 'UP 💰$cost' : 'Need 💰$cost',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _SellButton(game: game, tower: tower),
              ],
            ),
        ],
      ),
    );
  }
}

class _TargetingRow extends StatelessWidget {
  final TdGame game;
  final TowerComponent tower;
  const _TargetingRow({required this.game, required this.tower});

  static const _labels = {
    TargetingMode.first: 'FIRST',
    TargetingMode.strongest: 'STRONG',
    TargetingMode.weakest: 'WEAK',
    TargetingMode.closest: 'CLOSE',
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: TargetingMode.values.map((mode) {
        final selected = tower.targeting == mode;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              tower.targeting = mode;
              // Force rebuild — aynı referans değiştiği için null→tower
              game.selectedExistingTowerNotifier.value = null;
              game.selectedExistingTowerNotifier.value = tower;
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? tower.card.color.withValues(alpha: 0.35)
                    : Colors.white10,
                border: Border.all(
                  color: selected ? tower.card.color : Colors.white24,
                  width: selected ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _labels[mode]!,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white60,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SellButton extends StatelessWidget {
  final TdGame game;
  final TowerComponent tower;
  const _SellButton({required this.game, required this.tower});

  @override
  Widget build(BuildContext context) {
    final refund = (tower.investedGold * 0.6).round();
    return OutlinedButton(
      onPressed: () => game.sellTower(tower),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white70,
        side: const BorderSide(color: Colors.white24),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Text(
        'SELL $refund',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 10,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wave Reward Overlay — wave temizlenince ücretsiz upgrade seç.
// ─────────────────────────────────────────────────────────────────────────────

class _WaveRewardOverlay extends StatelessWidget {
  final TdGame game;
  const _WaveRewardOverlay({required this.game});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<TowerComponent>?>(
      valueListenable: game.upgradePickNotifier,
      builder: (_, towers, _) {
        if (towers == null) return const SizedBox.shrink();
        return Container(
          color: const Color(0xCC000000),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ValueListenableBuilder<int>(
                    valueListenable: game.waveNotifier,
                    builder: (_, wave, _) => Text(
                      'WAVE $wave CLEARED',
                      style: const TextStyle(
                        color: Color(0xFFFBBF24),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Bir kuleyi ücretsiz upgrade et',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  ...towers.map(
                    (t) => _TowerUpgradeOption(game: game, tower: t),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => game.pickTowerUpgrade(null),
                    child: const Text(
                      'ATLA',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TowerUpgradeOption extends StatelessWidget {
  final TdGame game;
  final TowerComponent tower;
  const _TowerUpgradeOption({required this.game, required this.tower});

  @override
  Widget build(BuildContext context) {
    final card = tower.card;
    return GestureDetector(
      onTap: () => game.pickTowerUpgrade(tower),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: card.color, width: 1.5),
        ),
        child: Row(
          children: [
            Text(card.icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Lv.${tower.level} → Lv.${tower.level + 1}',
                    style: TextStyle(
                      color: card.color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: card.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: card.color),
              ),
              child: const Text(
                'SEÇ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 8)),
      ],
    );
  }
}

class _TowerSelector extends StatelessWidget {
  final TdGame game;
  const _TowerSelector({required this.game});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ValueListenableBuilder<List<TowerCard>>(
        valueListenable: game.unlockedNotifier,
        builder: (_, unlocked, _) => ValueListenableBuilder<TowerCard>(
          valueListenable: game.selectedTowerNotifier,
          builder: (_, selected, _) => ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            itemCount: unlocked.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final card = unlocked[i];
              final isSelected = card.id == selected.id;
              return GestureDetector(
                onTap: () => game.placeTowerFromPicker(card),
                child: Container(
                  width: 68,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? card.color.withValues(alpha: 0.35)
                        : const Color(0x661A1A2E),
                    border: Border.all(
                      color: isSelected ? card.color : Colors.white30,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(card.icon, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 3),
                      Text(
                        card.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '💰 ${card.baseCost}',
                        style: const TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Modifier Seçim Overlay'i — run başında 3 modifier sun.
// ─────────────────────────────────────────────────────────────────────────────

class _ModifierSelectOverlay extends StatelessWidget {
  final TdGame game;
  const _ModifierSelectOverlay({required this.game});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<RunModifier>?>(
      valueListenable: game.modifierSelectNotifier,
      builder: (_, mods, _) {
        if (mods == null) return const SizedBox.shrink();
        return Container(
          color: const Color(0xE6000000),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'NEW RUN',
                    style: TextStyle(
                      color: Color(0xFFFBBF24),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Map: ${game.currentMap.name}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Choose a Modifier',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  ...mods.map((m) => _ModifierOption(game: game, mod: m)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ModifierOption extends StatelessWidget {
  final TdGame game;
  final RunModifier mod;
  const _ModifierOption({required this.game, required this.mod});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => game.pickModifier(mod),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFBBF24), width: 1.5),
        ),
        child: Row(
          children: [
            Text(mod.icon, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mod.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mod.description,
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Run Result Overlay'i — run bitince sonuç + paylaş + yeni run.
// ─────────────────────────────────────────────────────────────────────────────

class _RunResultOverlay extends StatelessWidget {
  final TdGame game;
  const _RunResultOverlay({required this.game});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RunResult?>(
      valueListenable: game.runResultNotifier,
      builder: (_, result, _) {
        if (result == null) return const SizedBox.shrink();
        final headerColor = result.victory
            ? const Color(0xFFFBBF24)
            : const Color(0xFFEF4444);
        return Container(
          color: const Color(0xF0000000),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    result.victory ? '🏆 VICTORY' : '💀 DEFEAT',
                    style: TextStyle(
                      color: headerColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Yıldız satırı (3 ikon, kazanılan kadar dolu)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final filled = i < result.stars;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          filled ? Icons.star_rounded : Icons.star_border_rounded,
                          color: filled
                              ? const Color(0xFFFBBF24)
                              : Colors.white24,
                          size: 44,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: headerColor, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        _ResultRow(
                          label: 'Bölüm',
                          value: '${result.levelId} — ${result.mapName}',
                        ),
                        _ResultRow(
                          label: 'Wave Reached',
                          value: '${result.waveReached} / ${result.totalWaves}',
                        ),
                        _ResultRow(
                          label: 'Lives Left',
                          value: '${result.livesLeft} / ${result.initialLives}',
                        ),
                        _ResultRow(
                          label: 'Final Gold',
                          value: '💰 ${result.finalGold}',
                        ),
                        if (result.modifier != null)
                          _ResultRow(
                            label: 'Modifier',
                            value:
                                '${result.modifier!.icon} ${result.modifier!.name}',
                          ),
                        _ResultRow(
                          label: 'Fragments',
                          value: '+${result.fragmentsEarned} 💎',
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Towers Used',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: result.towersUsed
                              .map(
                                (t) => Text(
                                  t.icon,
                                  style: const TextStyle(fontSize: 22),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ResultActions(game: game, result: result),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ResultActions extends StatelessWidget {
  final TdGame game;
  final RunResult result;
  const _ResultActions({required this.game, required this.result});

  @override
  Widget build(BuildContext context) {
    final nextLevel = LevelRegistry.all
        .where((l) => l.id == result.levelId + 1)
        .firstOrNull;
    final canAdvance = result.victory &&
        nextLevel != null &&
        ProgressService.instance.isUnlocked(nextLevel.starsRequired);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: result.shareCard));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.share, size: 16),
                label: const Text('SHARE'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: game.exitToLevels,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('BÖLÜMLER'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canAdvance ? () => game.startLevel(nextLevel) : game.restartLevel,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFBBF24),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              canAdvance ? 'SONRAKİ BÖLÜM' : 'TEKRAR DENE',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlacementOverlay extends StatelessWidget {
  final TdGame game;
  const _PlacementOverlay({required this.game});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: game.placementPhaseNotifier,
      builder: (_, isPlacing, _) {
        if (!isPlacing) return const SizedBox.shrink();
        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 64),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Kulelerini kur, hazır olunca başlat',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: game.startFirstWave,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBBF24),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xAAFBBF24),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Text(
                      '▶  BAŞLAT',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SpeedButton extends StatelessWidget {
  final TdGame game;
  const _SpeedButton({required this.game});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: game.speedUpNotifier,
      builder: (_, isFast, _) => GestureDetector(
        onTap: game.toggleSpeed,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isFast
                ? const Color(0xCCFBBF24)
                : const Color(0xAA1A1A2E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isFast ? const Color(0xFFFBBF24) : Colors.white30,
              width: 1.2,
            ),
          ),
          child: Text(
            isFast ? '⏩' : '▶',
            style: TextStyle(
              fontSize: 18,
              color: isFast ? Colors.white : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  const _ResultRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
