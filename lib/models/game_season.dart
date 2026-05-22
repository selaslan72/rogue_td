import 'package:flutter/foundation.dart';

@immutable
class GameSeason {
  final String id;
  final String label;
  final bool locked;

  const GameSeason._({
    required this.id,
    required this.label,
    required this.locked,
  });

  static const spring = GameSeason._(
    id: 'spring',
    label: 'Spring',
    locked: false,
  );

  static const winter = GameSeason._(
    id: 'winter',
    label: 'Winter',
    locked: true,
  );

  static const values = [spring, winter];

  static GameSeason byId(String id) =>
      values.firstWhere((season) => season.id == id, orElse: () => spring);
}
