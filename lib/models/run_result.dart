import 'package:flutter/foundation.dart';
import 'tower_card.dart';

@immutable
class RunResult {
  final bool victory;
  final int waveReached;
  final int totalWaves;
  final int finalGold;
  final int livesLeft;
  final int initialLives;
  final int stars; // 0..3
  final int levelId;
  final String mapName;
  final List<TowerCard> towersUsed;
  final int fragmentsEarned;

  const RunResult({
    required this.victory,
    required this.waveReached,
    required this.totalWaves,
    required this.finalGold,
    required this.livesLeft,
    required this.initialLives,
    required this.stars,
    required this.levelId,
    required this.mapName,
    required this.towersUsed,
    required this.fragmentsEarned,
  });

  /// Kalan can yüzdesine göre yıldız.
  /// 80%+ → 3, 40%+ → 2, 1+ → 1, ölü → 0.
  static int starsFromLives(int livesLeft, int initialLives) {
    if (livesLeft <= 0) return 0;
    final ratio = livesLeft / initialLives;
    if (ratio >= 0.8) return 3;
    if (ratio >= 0.4) return 2;
    return 1;
  }

  /// Sosyal paylaşım için kompakt emoji kart.
  String get shareCard {
    final flag = victory ? '🏆 VICTORY' : '💀 DEFEAT';
    final towers = towersUsed.map((t) => t.icon).join('');
    final starStr = '★' * stars + '☆' * (3 - stars);
    return '$flag\nBölüm $levelId — $mapName\nWave $waveReached / $totalWaves\n$starStr\nTowers: $towers\n+$fragmentsEarned 💎\n#RogueTD';
  }
}
