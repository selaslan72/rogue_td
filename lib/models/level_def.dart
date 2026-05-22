import 'package:flutter/foundation.dart';
import '../game/path_data.dart';
import 'game_season.dart';

/// Bir bölümün değişmez tanımı.
@immutable
class LevelDef {
  final GameSeason season;
  final int id; // 1..N
  final String name; // "Bölüm 1 — Snake"
  final GameMap map;
  final double hpMul; // düşman HP çarpanı (bu bölümde)
  final double speedMul; // düşman hız çarpanı
  final int starsRequired; // bu bölümün açılması için gereken toplam yıldız

  const LevelDef({
    required this.season,
    required this.id,
    required this.name,
    required this.map,
    required this.hpMul,
    required this.speedMul,
    required this.starsRequired,
  });
}
