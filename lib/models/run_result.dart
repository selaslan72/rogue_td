import 'package:flutter/foundation.dart';
import 'run_modifier.dart';
import 'tower_card.dart';

@immutable
class RunResult {
  final bool victory;
  final int waveReached;
  final int finalGold;
  final String mapName;
  final RunModifier? modifier;
  final List<TowerCard> towersUsed;

  const RunResult({
    required this.victory,
    required this.waveReached,
    required this.finalGold,
    required this.mapName,
    required this.modifier,
    required this.towersUsed,
  });

  /// Sosyal paylaşım için kompakt emoji kart.
  String get shareCard {
    final flag = victory ? '🏆 VICTORY' : '💀 DEFEAT';
    final towers = towersUsed.map((t) => t.icon).join('');
    final mod = modifier == null ? '' : '\n${modifier!.icon} ${modifier!.name}';
    return '$flag\nWave $waveReached / 15\nMap: $mapName\nTowers: $towers$mod\n#RogueTD';
  }
}
