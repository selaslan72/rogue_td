import 'package:flutter/material.dart';
import '../data/level_registry.dart';
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
  @override
  void initState() {
    super.initState();
    // Geri dönünce yıldızlar güncel olsun
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _open(LevelDef level) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(level: level),
      ),
    );
    if (mounted) setState(() {}); // dönüşte yıldız sayısı yenilensin
  }

  @override
  Widget build(BuildContext context) {
    final progress = ProgressService.instance;
    final total = progress.totalStars;
    final maxStars = LevelRegistry.all.length * 3;

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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded,
                      color: Color(0xFFFBBF24), size: 22),
                  const SizedBox(width: 4),
                  Text(
                    '$total / $maxStars',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: LevelRegistry.all.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final level = LevelRegistry.all[i];
                    final stars = progress.starsFor(level.id);
                    final unlocked = progress.isUnlocked(level.starsRequired);
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
    final accent = unlocked
        ? const Color(0xFFFBBF24)
        : Colors.white24;
    return Material(
      color: const Color(0xFF1A1A2E),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: accent.withValues(alpha: 0.6), width: 1.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: unlocked ? 0.18 : 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${level.id}',
                  style: TextStyle(
                    color: unlocked ? accent : Colors.white38,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.name,
                      style: TextStyle(
                        color: unlocked ? Colors.white : Colors.white38,
                        fontSize: 15,
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
                            size: 18,
                          );
                        }),
                      )
                    else
                      Row(
                        children: [
                          const Icon(Icons.lock_outline,
                              color: Colors.white38, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${level.starsRequired} ★ gerekli ($totalStars var)',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
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
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
