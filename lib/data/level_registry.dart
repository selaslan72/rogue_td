import '../game/path_data.dart';
import '../models/game_season.dart';
import '../models/level_def.dart';

/// Sezonlara ayrılmış level tanımları.
class LevelRegistry {
  LevelRegistry._();

  static const springTargetLevelCount = 30;
  static const winterTargetLevelCount = 30;

  static final List<GameMap> _springMaps = [
    PathData.snake,
    PathData.zigzag,
    PathData.uLoop,
    PathData.cross,
    PathData.doubleLoop,
    PathData.maze,
    PathData.switchback,
    PathData.spiral,
    PathData.stairs,
    PathData.ring,
    PathData.gate,
    PathData.river,
    PathData.canyon,
    PathData.clover,
    PathData.braid,
    PathData.hourglass,
    PathData.terrace,
    PathData.fork,
    PathData.hook,
    PathData.island,
    PathData.ladder,
    PathData.loopback,
    PathData.pinch,
    PathData.rampart,
    PathData.saw,
    PathData.shelf,
    PathData.summit,
    PathData.turnstile,
    PathData.valley,
    PathData.weave,
  ];

  static final List<GameMap> _winterMaps = PathData.winterAll;

  static final List<LevelDef> spring = _buildCampaign(
    season: GameSeason.spring,
    maps: _springMaps,
  );

  static final List<LevelDef> winter = _buildCampaign(
    season: GameSeason.winter,
    maps: _winterMaps,
  );
  static final List<LevelDef> all = [...spring, ...winter];

  static int get missingSpringLevelCount =>
      springTargetLevelCount - spring.length;

  static int get missingWinterLevelCount =>
      winterTargetLevelCount - winter.length;

  static int targetCountFor(GameSeason season) {
    switch (season.id) {
      case 'winter':
        return winterTargetLevelCount;
      case 'spring':
      default:
        return springTargetLevelCount;
    }
  }

  static List<LevelDef> allFor(GameSeason season) {
    switch (season.id) {
      case 'winter':
        return winter;
      case 'spring':
      default:
        return spring;
    }
  }

  static LevelDef byId(int id, {GameSeason season = GameSeason.spring}) =>
      allFor(season).firstWhere((l) => l.id == id, orElse: () => spring.first);

  static List<LevelDef> _buildCampaign({
    required GameSeason season,
    required List<GameMap> maps,
  }) {
    return List.generate(maps.length, (index) {
      final id = index + 1;
      return LevelDef(
        season: season,
        id: id,
        name: 'Bölüm $id',
        map: maps[index],
        hpMul: _hpMulFor(id),
        speedMul: _speedMulFor(id),
        starsRequired: _starsRequiredFor(id),
      );
    });
  }

  static double _hpMulFor(int id) {
    const early = [1.0, 1.25, 1.5, 1.75, 2.0, 2.5];
    if (id <= early.length) return early[id - 1];
    return 2.5 + (id - early.length) * 0.18;
  }

  static double _speedMulFor(int id) {
    const early = [1.0, 1.05, 1.10, 1.15, 1.20, 1.30];
    if (id <= early.length) return early[id - 1];
    return 1.30 + (id - early.length) * 0.02;
  }

  static int _starsRequiredFor(int id) {
    const early = [0, 1, 3, 6, 10, 15];
    if (id <= early.length) return early[id - 1];
    return 15 + (id - early.length) * 3;
  }
}
