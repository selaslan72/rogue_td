import 'package:flutter/foundation.dart';

import 'tower_card.dart';

@immutable
class TowerContribution {
  final String towerId;
  final String name;
  final String icon;
  final double damage;
  final int kills;
  final int slows;
  final double blockSeconds;

  const TowerContribution({
    required this.towerId,
    required this.name,
    required this.icon,
    required this.damage,
    required this.kills,
    required this.slows,
    required this.blockSeconds,
  });

  factory TowerContribution.empty(TowerCard card) => TowerContribution(
    towerId: card.id,
    name: card.name,
    icon: card.icon,
    damage: 0,
    kills: 0,
    slows: 0,
    blockSeconds: 0,
  );

  TowerContribution copyWith({
    double? damage,
    int? kills,
    int? slows,
    double? blockSeconds,
  }) => TowerContribution(
    towerId: towerId,
    name: name,
    icon: icon,
    damage: damage ?? this.damage,
    kills: kills ?? this.kills,
    slows: slows ?? this.slows,
    blockSeconds: blockSeconds ?? this.blockSeconds,
  );
}
