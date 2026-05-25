import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../data/level_registry.dart';
import '../models/game_season.dart';
import '../models/level_def.dart';
import '../services/progress_service.dart';
import 'game_screen.dart';

/// Bölüm seçim ekranı. Toplam yıldız sayısına göre bölümler kilitlenir.
class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  GameSeason _season = GameSeason.spring;

  @override
  void initState() {
    super.initState();
    // Geri dönünce yıldızlar güncel olsun
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _open(LevelDef level) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => GameScreen(level: level)));
    if (mounted) setState(() {}); // dönüşte yıldız sayısı yenilensin
  }

  @override
  Widget build(BuildContext context) {
    final progress = ProgressService.instance;
    final levels = LevelRegistry.allFor(_season);
    final total = progress.totalStarsFor(_season);
    final maxStars = levels.length * 3;
    final targetLevels = LevelRegistry.targetCountFor(_season);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'ROGUE TD',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFFBBF24),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 8),
              _SeasonPicker(
                selected: _season,
                progress: progress,
                onSelected: (season) => setState(() => _season = season),
              ),
              if (!progress.isSeasonUnlocked(GameSeason.winter) &&
                  !kDebugMode) ...[
                const SizedBox(height: 8),
                Text(
                  'Winter için ${ProgressService.winterUnlockSpringStars} Spring yıldızı gerekli',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFFBBF24),
                    size: 22,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_season.label}  $total / $maxStars',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${levels.length} / $targetLevels bölüm hazır',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  itemCount: levels.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.55,
                  ),
                  itemBuilder: (_, i) {
                    final level = levels[i];
                    final stars = progress.starsFor(
                      level.id,
                      season: level.season,
                    );
                    final unlocked =
                        kDebugMode ||
                        progress.isUnlocked(
                          level.starsRequired,
                          season: level.season,
                        );
                    return _LevelTile(
                      level: level,
                      stars: stars,
                      unlocked: unlocked,
                      totalStars: total,
                      onTap: unlocked ? () => _open(level) : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeasonPicker extends StatelessWidget {
  final GameSeason selected;
  final ProgressService progress;
  final ValueChanged<GameSeason> onSelected;

  const _SeasonPicker({
    required this.selected,
    required this.progress,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: GameSeason.values.map((season) {
        final isSelected = season == selected;
        final isLocked = season.locked && !progress.isSeasonUnlocked(season);
        final canSelect = !isLocked || kDebugMode;
        final accent = isSelected ? const Color(0xFFFBBF24) : Colors.white30;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: OutlinedButton.icon(
              onPressed: canSelect ? () => onSelected(season) : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                disabledForegroundColor: Colors.white30,
                side: BorderSide(color: accent.withValues(alpha: 0.65)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: Icon(
                isLocked ? Icons.lock_outline : Icons.park_rounded,
                size: 16,
              ),
              label: Text(
                season.label.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _LevelTile extends StatelessWidget {
  final LevelDef level;
  final int stars;
  final bool unlocked;
  final int totalStars;
  final VoidCallback? onTap;

  const _LevelTile({
    required this.level,
    required this.stars,
    required this.unlocked,
    required this.totalStars,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = unlocked ? const Color(0xFFFBBF24) : Colors.white24;
    return Material(
      color: const Color(0xFF1A1A2E),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: accent.withValues(alpha: 0.6),
              width: 1.4,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: unlocked ? 0.18 : 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${level.id}',
                  style: TextStyle(
                    color: unlocked ? accent : Colors.white38,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.name,
                      style: TextStyle(
                        color: unlocked ? Colors.white : Colors.white38,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (unlocked)
                      Row(
                        children: List.generate(3, (i) {
                          final filled = i < stars;
                          return Icon(
                            filled
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: filled
                                ? const Color(0xFFFBBF24)
                                : Colors.white24,
                            size: 16,
                          );
                        }),
                      )
                    else
                      Row(
                        children: [
                          const Icon(
                            Icons.lock_outline,
                            color: Colors.white38,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${level.starsRequired} ★ gerekli',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Icon(
                unlocked ? Icons.play_arrow_rounded : Icons.lock,
                color: accent,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
