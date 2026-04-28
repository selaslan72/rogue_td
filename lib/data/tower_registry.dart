import 'package:flutter/material.dart';
import '../models/tower_card.dart';

/// 5 temel tower archetype'ı. Her biri 3 level boyunca yükseltilebilir
/// (görsel + stat değişimi `TowerComponent` tarafında).
class TowerRegistry {
  TowerRegistry._();

  static const archer = TowerCard(
    id: 'archer',
    name: 'Archer',
    description: 'Single target, fast attack speed.',
    rarity: TowerRarity.common,
    type: TowerType.singleTarget,
    baseCost: 50,
    damage: 12,
    range: 110,
    fireRate: 1.5,
    color: Color(0xFF60A5FA),
    icon: '🏹',
  );

  static const cannon = TowerCard(
    id: 'cannon',
    name: 'Cannon',
    description: 'Splash damage, slow attack.',
    rarity: TowerRarity.common,
    type: TowerType.splash,
    baseCost: 80,
    damage: 30,
    range: 90,
    fireRate: 0.7,
    color: Color(0xFFEF4444),
    icon: '💣',
  );

  static const frost = TowerCard(
    id: 'frost',
    name: 'Frost',
    description: 'Slows enemies, low damage.',
    rarity: TowerRarity.common,
    type: TowerType.slow,
    baseCost: 70,
    damage: 8,
    range: 95,
    fireRate: 1.1,
    color: Color(0xFF38BDF8),
    icon: '🧊',
  );

  static const flame = TowerCard(
    id: 'flame',
    name: 'Flame',
    description: 'Damage over time, short range.',
    rarity: TowerRarity.common,
    type: TowerType.damageOverTime,
    baseCost: 75,
    damage: 5,
    range: 75,
    fireRate: 4.0,
    color: Color(0xFFF97316),
    icon: '🔥',
  );

  static const tesla = TowerCard(
    id: 'tesla',
    name: 'Tesla',
    description: 'Chain lightning, hits 2.',
    rarity: TowerRarity.common,
    type: TowerType.chain,
    baseCost: 90,
    damage: 16,
    range: 100,
    fireRate: 1.2,
    color: Color(0xFFC084FC),
    icon: '⚡',
  );

  static const List<TowerCard> all = [archer, cannon, frost, flame, tesla];

  static TowerCard byId(String id) =>
      all.firstWhere((c) => c.id == id, orElse: () => archer);
}
