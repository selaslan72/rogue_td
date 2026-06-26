import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rogue_td/data/level_registry.dart';
import 'package:rogue_td/game/path_data.dart';
import 'package:rogue_td/models/game_season.dart';

void main() {
  test('spring campaign exposes 30 real map-backed levels', () {
    final spring = LevelRegistry.allFor(GameSeason.spring);
    final mapIdentities = spring.map((level) => identityHashCode(level.map));

    expect(LevelRegistry.targetCountFor(GameSeason.spring), 30);
    expect(spring, hasLength(30));
    expect(mapIdentities.toSet(), hasLength(spring.length));
    expect(spring.last.id, 30);
    expect(spring.last.name, 'Bölüm 30');
    expect(LevelRegistry.missingSpringLevelCount, 0);
  });

  test('winter campaign starts with real map-backed levels', () {
    final winter = LevelRegistry.allFor(GameSeason.winter);
    final mapIdentities = winter.map((level) => identityHashCode(level.map));

    expect(LevelRegistry.targetCountFor(GameSeason.winter), 30);
    expect(winter, hasLength(30));
    expect(mapIdentities.toSet(), hasLength(winter.length));
    expect(winter.last.id, 30);
    expect(winter.last.name, 'Bölüm 30');
    expect(LevelRegistry.missingWinterLevelCount, 0);
  });

  test('winter level 2 keeps slots off-road and target route clean', () {
    final map = LevelRegistry.allFor(GameSeason.winter)[1].map;
    const minSlotClearance = 44.0;

    for (final slot in map.towerSlots) {
      final distance = _minDistanceToPath(slot, map.waypoints);
      expect(
        distance,
        greaterThanOrEqualTo(minSlotClearance),
        reason: 'Slot at $slot is too close to the Winter 2 enemy path.',
      );
    }

    final target = map.waypoints.last;
    for (var i = 0; i < map.waypoints.length - 2; i++) {
      final distance = _distanceToSegment(
        target,
        map.waypoints[i],
        map.waypoints[i + 1],
      );
      expect(
        distance,
        greaterThanOrEqualTo(70),
        reason: 'Winter 2 path passes too close to the target before the end.',
      );
    }
  });

  test('winter level 4 only approaches the target castle at the end', () {
    final map = LevelRegistry.allFor(GameSeason.winter)[3].map;
    final target = map.waypoints.last;

    for (var i = 0; i < map.waypoints.length - 2; i++) {
      final distance = _distanceToSegment(
        target,
        map.waypoints[i],
        map.waypoints[i + 1],
      );
      expect(
        distance,
        greaterThanOrEqualTo(90),
        reason:
            'Winter 4 path should not pass in front of the target castle before the final segment.',
      );
    }
  });

  test('winter level 8 only approaches the target castle at the end', () {
    final map = LevelRegistry.allFor(GameSeason.winter)[7].map;
    final target = map.waypoints.last;

    expect(map.name, 'Winter Maze 8');

    for (var i = 0; i < map.waypoints.length - 2; i++) {
      final distance = _distanceToSegment(
        target,
        map.waypoints[i],
        map.waypoints[i + 1],
      );
      expect(
        distance,
        greaterThanOrEqualTo(90),
        reason:
            'Winter 8 path should not pass in front of the target castle before the final segment.',
      );
    }
  });

  test('winter level 10 only approaches the target castle at the end', () {
    final map = LevelRegistry.allFor(GameSeason.winter)[9].map;
    final target = map.waypoints.last;

    expect(map.name, 'Winter Maze 10');

    for (var i = 0; i < map.waypoints.length - 2; i++) {
      final distance = _distanceToSegment(
        target,
        map.waypoints[i],
        map.waypoints[i + 1],
      );
      expect(
        distance,
        greaterThanOrEqualTo(90),
        reason:
            'Winter 10 path should not pass in front of the target castle before the final segment.',
      );
    }
  });

  test(
    'winter levels with custom readable routes stay out of generated loops',
    () {
      final winter = LevelRegistry.allFor(GameSeason.winter);

      expect(winter[15].map.name, 'Winter Run 16');
      expect(winter[19].map.name, 'Winter Run 20');
      expect(winter[21].map.name, 'Winter Run 22');
      expect(winter[25].map.name, 'Winter Run 26');
      expect(winter[27].map.name, 'Winter Run 28');
    },
  );

  test(
    'all winter paths keep the target castle approach for the final segment',
    () {
      for (final level in LevelRegistry.allFor(GameSeason.winter)) {
        final map = level.map;
        final target = map.waypoints.last;

        for (var i = 0; i < map.waypoints.length - 2; i++) {
          final distance = _distanceToSegment(
            target,
            map.waypoints[i],
            map.waypoints[i + 1],
          );
          expect(
            distance,
            greaterThanOrEqualTo(90),
            reason:
                'Winter ${level.id} (${map.name}) should not pass in front of the target castle before the final segment.',
          );
        }
      }
    },
  );

  test('spring level 22 uses a readable final target approach', () {
    final map = LevelRegistry.allFor(GameSeason.spring)[21].map;
    final target = map.waypoints.last;

    expect(map.name, 'Garden Run');

    for (var i = 0; i < map.waypoints.length - 2; i++) {
      final distance = _distanceToSegment(
        target,
        map.waypoints[i],
        map.waypoints[i + 1],
      );
      expect(
        distance,
        greaterThanOrEqualTo(90),
        reason:
            'Spring 22 should not pass in front of the target castle before the final segment.',
      );
    }
  });

  test('all target castles stay inside the visible play area', () {
    const castleHalfW = 40.0;
    const castleTopClearance = 47.0;
    const castleBottomClearance = 45.0;

    for (final season in GameSeason.values) {
      for (final level in LevelRegistry.allFor(season)) {
        final target = level.map.waypoints.last;

        expect(
          target.x,
          inInclusiveRange(castleHalfW, PathData.mapW - castleHalfW),
          reason:
              '${season.label} ${level.id} (${level.map.name}) target castle overflows horizontally.',
        );
        expect(
          target.y,
          inInclusiveRange(
            castleTopClearance,
            PathData.mapH - castleBottomClearance,
          ),
          reason:
              '${season.label} ${level.id} (${level.map.name}) target castle overflows vertically.',
        );
      }
    }
  });

  test('all entrance castles stay inside the visible play area', () {
    const castleHalfW = 40.0;
    const castleTopClearance = 47.0;
    const castleBottomClearance = 45.0;

    for (final season in GameSeason.values) {
      for (final level in LevelRegistry.allFor(season)) {
        final entry = level.map.waypoints.first;

        expect(
          entry.x,
          inInclusiveRange(castleHalfW, PathData.mapW - castleHalfW),
          reason:
              '${season.label} ${level.id} (${level.map.name}) entry castle overflows horizontally.',
        );
        expect(
          entry.y,
          inInclusiveRange(
            castleTopClearance,
            PathData.mapH - castleBottomClearance,
          ),
          reason:
              '${season.label} ${level.id} (${level.map.name}) entry castle overflows vertically.',
        );
      }
    }
  });

  test('all campaign slots stay clear of enemy paths', () {
    for (final season in GameSeason.values) {
      for (final level in LevelRegistry.allFor(season)) {
        expect(
          level.map.towerSlots,
          hasLength(greaterThanOrEqualTo(5)),
          reason:
              '${season.label} ${level.id} should keep enough usable slots.',
        );

        for (final slot in level.map.towerSlots) {
          final distance = _minDistanceToPath(slot, level.map.waypoints);
          expect(
            distance,
            greaterThanOrEqualTo(44),
            reason:
                '${season.label} ${level.id} has a slot too close to path at $slot.',
          );
        }
      }
    }
  });
}

double _minDistanceToPath(Vector2 point, List<Vector2> waypoints) {
  var minDistance = double.infinity;
  for (var i = 0; i < waypoints.length - 1; i++) {
    minDistance = math.min(
      minDistance,
      _distanceToSegment(point, waypoints[i], waypoints[i + 1]),
    );
  }
  return minDistance;
}

double _distanceToSegment(Vector2 point, Vector2 a, Vector2 b) {
  final ab = b - a;
  final ap = point - a;
  final len2 = ab.length2;
  if (len2 == 0) return ap.length;
  final t = (ap.dot(ab) / len2).clamp(0.0, 1.0);
  return (point - (a + ab * t)).length;
}
