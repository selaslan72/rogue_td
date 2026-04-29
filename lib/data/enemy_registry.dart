import 'package:flutter/material.dart';
import '../models/enemy_def.dart';

class EnemyRegistry {
  EnemyRegistry._();

  static const fast = EnemyDef(
    id: 'fast',
    name: 'Runner',
    kind: EnemyKind.fast,
    maxHp: 30,
    speed: 80,
    armor: 0,
    goldReward: 3,
    damageOnLeak: 1,
    color: Color(0xFFFBBF24),
  );

  static const basic = EnemyDef(
    id: 'basic',
    name: 'Grunt',
    kind: EnemyKind.basic,
    maxHp: 60,
    speed: 50,
    armor: 0,
    goldReward: 5,
    damageOnLeak: 1,
    color: Color(0xFFEF4444),
  );

  static const tank = EnemyDef(
    id: 'tank',
    name: 'Brute',
    kind: EnemyKind.tank,
    maxHp: 200,
    speed: 25,
    armor: 5,
    goldReward: 12,
    damageOnLeak: 1,
    color: Color(0xFF7C3AED),
  );

  static const flying = EnemyDef(
    id: 'flying',
    name: 'Wing',
    kind: EnemyKind.flying,
    maxHp: 45,
    speed: 100,
    armor: 0,
    goldReward: 6,
    damageOnLeak: 1,
    color: Color(0xFFF472B6),
  );

  static const miniBoss = EnemyDef(
    id: 'mini-boss',
    name: 'Warlord',
    kind: EnemyKind.boss,
    maxHp: 800,
    speed: 22,
    armor: 8,
    goldReward: 80,
    damageOnLeak: 1,
    color: Color(0xFF9333EA),
    sizeScale: 1.6,
  );

  static const finalBoss = EnemyDef(
    id: 'final-boss',
    name: 'Overlord',
    kind: EnemyKind.boss,
    maxHp: 2400,
    speed: 18,
    armor: 12,
    goldReward: 250,
    damageOnLeak: 1,
    color: Color(0xFF7F1D1D),
    sizeScale: 2.0,
  );

  static const List<EnemyDef> all = [fast, basic, tank, flying, miniBoss, finalBoss];

  static EnemyDef byId(String id) =>
      all.firstWhere((e) => e.id == id, orElse: () => basic);
}
