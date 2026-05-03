import '../game/path_data.dart';
import '../models/level_def.dart';

/// 6 bölüm — her biri farklı harita + artan zorluk + kilit yıldız şartı.
class LevelRegistry {
  LevelRegistry._();

  static final l1 = LevelDef(
    id: 1,
    name: 'Bölüm 1 — Yılan Yolu',
    map: PathData.snake,
    hpMul: 1.0,
    speedMul: 1.0,
    starsRequired: 0,
  );

  static final l2 = LevelDef(
    id: 2,
    name: 'Bölüm 2 — Zikzak',
    map: PathData.zigzag,
    hpMul: 1.25,
    speedMul: 1.05,
    starsRequired: 1,
  );

  static final l3 = LevelDef(
    id: 3,
    name: 'Bölüm 3 — U Halkası',
    map: PathData.uLoop,
    hpMul: 1.5,
    speedMul: 1.10,
    starsRequired: 3,
  );

  static final l4 = LevelDef(
    id: 4,
    name: 'Bölüm 4 — Çapraz',
    map: PathData.cross,
    hpMul: 1.75,
    speedMul: 1.15,
    starsRequired: 6,
  );

  static final l5 = LevelDef(
    id: 5,
    name: 'Bölüm 5 — Çift Halka',
    map: PathData.doubleLoop,
    hpMul: 2.0,
    speedMul: 1.20,
    starsRequired: 10,
  );

  static final l6 = LevelDef(
    id: 6,
    name: 'Bölüm 6 — Labirent',
    map: PathData.maze,
    hpMul: 2.5,
    speedMul: 1.30,
    starsRequired: 15,
  );

  static final List<LevelDef> all = [l1, l2, l3, l4, l5, l6];

  static LevelDef byId(int id) =>
      all.firstWhere((l) => l.id == id, orElse: () => l1);
}
