import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game/components/tower_component.dart';
import '../game/td_game.dart';
import '../models/enemy_def.dart';
import '../models/run_modifier.dart';
import '../models/run_result.dart';
import '../models/tower_card.dart';

/// GameWidget'ı saran ekran. HUD overlay + tower seçici barı içerir.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final TdGame _game;

  @override
  void initState() {
    super.initState();
    _game = TdGame();
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
                  Positioned.fill(child: _UpgradeOverlay(game: _game)),
                  Positioned.fill(child: _CardSelectOverlay(game: _game)),
                  Positioned.fill(child: _ModifierSelectOverlay(game: _game)),
                  Positioned.fill(child: _RunResultOverlay(game: _game)),
                ],
              ),
            ),
            _TowerSelector(game: _game),
          ],
        ),
      ),
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
                  ValueListenableBuilder<int>(
                    valueListenable: game.waveNotifier,
                    builder: (_, wave, _) => Text(
                      'WAVE $wave',
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TowerComponent?>(
      valueListenable: game.selectedExistingTowerNotifier,
      builder: (_, tower, _) {
        if (tower == null) return const SizedBox.shrink();
        // Gold değişince butonun aktif/pasif durumu da güncellensin
        return ValueListenableBuilder<int>(
          valueListenable: game.goldNotifier,
          builder: (_, _, _) => Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _UpgradePanel(game: game, tower: tower),
            ),
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
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xE61A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: card.color, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Text(card.icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${card.name}  •  Lv.$lvl',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => game.selectedExistingTowerNotifier.value = null,
                child: const Icon(Icons.close, color: Colors.white54, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Stats
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
          const SizedBox(height: 10),
          // Upgrade / max
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
                      letterSpacing: 1.5,
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
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      hasGold ? 'UPGRADE  💰$cost' : 'Need 💰$cost',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1,
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        'SELL 💰$refund',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Kart Seçim Overlay'i — wave temizlenince oyun duraklar, 3 kart sunulur.
// ─────────────────────────────────────────────────────────────────────────────

class _CardSelectOverlay extends StatelessWidget {
  final TdGame game;
  const _CardSelectOverlay({required this.game});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<TowerCard>?>(
      valueListenable: game.cardSelectNotifier,
      builder: (_, cards, _) {
        if (cards == null) return const SizedBox.shrink();
        return Container(
          color: const Color(0xCC000000),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'WAVE ${game.wave} CLEARED',
                    style: const TextStyle(
                      color: Color(0xFFFBBF24),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Train a Tower',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  ...cards.map((card) => _CardOption(game: game, card: card)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CardOption extends StatelessWidget {
  final TdGame game;
  final TowerCard card;
  const _CardOption({required this.game, required this.card});

  static const _rarityLabel = {
    TowerRarity.common: 'COMMON',
    TowerRarity.rare: 'RARE',
    TowerRarity.legendary: 'LEGENDARY',
  };

  static const _rarityColor = {
    TowerRarity.common: Color(0xFFAAAAAA),
    TowerRarity.rare: Color(0xFF60A5FA),
    TowerRarity.legendary: Color(0xFFFBBF24),
  };

  @override
  Widget build(BuildContext context) {
    final trainingLevel = game.stats.towerTrainingLevel(card.id);
    return GestureDetector(
      onTap: () => game.pickCard(card),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: card.color, width: 1.5),
        ),
        child: Row(
          children: [
            Text(card.icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        card.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: _rarityColor[card.rarity]!.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _rarityLabel[card.rarity]!,
                          style: TextStyle(
                            color: _rarityColor[card.rarity],
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '+10% damage, +5% range for every ${card.name}',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Lv.${trainingLevel + 1}',
                  style: const TextStyle(
                    color: Color(0xFFFBBF24),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  '+15g',
                  style: TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
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
            fontSize: 13,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ],
    );
  }
}

class _TowerSelector extends StatelessWidget {
  final TdGame game;
  const _TowerSelector({required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      color: const Color(0xFF1A1A2E),
      child: SizedBox(
        height: 70,
        child: ValueListenableBuilder<List<TowerCard>>(
          valueListenable: game.unlockedNotifier,
          builder: (_, unlocked, _) => ValueListenableBuilder<TowerCard>(
            valueListenable: game.selectedTowerNotifier,
            builder: (_, selected, _) => ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: unlocked.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final card = unlocked[i];
                final isSelected = card.id == selected.id;
                return GestureDetector(
                  onTap: () => game.selectTower(card),
                  child: Container(
                    width: 64,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? card.color.withValues(alpha: 0.2)
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? card.color : Colors.white24,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(card.icon, style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 2),
                        Text(
                          card.name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '💰 ${card.baseCost}',
                          style: const TextStyle(
                            color: Color(0xFFFBBF24),
                            fontSize: 10,
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
                          label: 'Wave Reached',
                          value: '${result.waveReached} / 15',
                        ),
                        _ResultRow(label: 'Map', value: result.mapName),
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
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: result.shareCard),
                            );
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
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: game.startNewRun,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFBBF24),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'NEW RUN',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
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
