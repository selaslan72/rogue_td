import 'package:flutter/material.dart';
import '../models/tower_card.dart';

/// Sprint 2 — 8 common + 5 rare + 3 legendary.
/// Mekanik TowerType ile belirlenir; sayısal farklar stat profilinde.
class TowerRegistry {
  TowerRegistry._();

  // ─── COMMONS (8) ─────────────────────────────────────────────────────────
  static const archer = TowerCard(
    id: 'archer',
    name: 'Archer',
    description: 'Single target, fast attack speed.',
    rarity: TowerRarity.common,
    type: TowerType.singleTarget,
    baseCost: 50,
    damage: 12,
    range: 100,
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
    range: 80,
    fireRate: 0.6,
    color: Color(0xFFEF4444),
    icon: '💣',
  );

  static const frost = TowerCard(
    id: 'frost',
    name: 'Frost',
    description: 'Slows enemies, low damage.',
    rarity: TowerRarity.common,
    type: TowerType.slow,
    baseCost: 60,
    damage: 5,
    range: 90,
    fireRate: 1.0,
    color: Color(0xFF38BDF8),
    icon: '🧊',
  );

  static const flame = TowerCard(
    id: 'flame',
    name: 'Flame',
    description: 'Damage over time, short range.',
    rarity: TowerRarity.common,
    type: TowerType.damageOverTime,
    baseCost: 70,
    damage: 4,
    range: 70,
    fireRate: 4.0,
    color: Color(0xFFF97316),
    icon: '🔥',
  );

  static const slingshot = TowerCard(
    id: 'slingshot',
    name: 'Slingshot',
    description: 'Cheap rapid single target.',
    rarity: TowerRarity.common,
    type: TowerType.singleTarget,
    baseCost: 35,
    damage: 7,
    range: 85,
    fireRate: 2.0,
    color: Color(0xFFA3E635),
    icon: '🎯',
  );

  static const mortar = TowerCard(
    id: 'mortar',
    name: 'Mortar',
    description: 'Heavy splash, very slow.',
    rarity: TowerRarity.common,
    type: TowerType.splash,
    baseCost: 95,
    damage: 45,
    range: 110,
    fireRate: 0.4,
    color: Color(0xFFB45309),
    icon: '💥',
  );

  static const tesla = TowerCard(
    id: 'tesla',
    name: 'Tesla',
    description: 'Chain lightning, hits 2.',
    rarity: TowerRarity.common,
    type: TowerType.chain,
    baseCost: 75,
    damage: 14,
    range: 95,
    fireRate: 1.2,
    color: Color(0xFFC084FC),
    icon: '⚡',
  );

  static const spike = TowerCard(
    id: 'spike',
    name: 'Spike',
    description: 'Balanced single target.',
    rarity: TowerRarity.common,
    type: TowerType.singleTarget,
    baseCost: 65,
    damage: 18,
    range: 95,
    fireRate: 1.2,
    color: Color(0xFF94A3B8),
    icon: '🗡️',
  );

  // ─── RARES (5) ───────────────────────────────────────────────────────────
  static const sniper = TowerCard(
    id: 'sniper',
    name: 'Sniper',
    description: 'Massive range + damage, very slow.',
    rarity: TowerRarity.rare,
    type: TowerType.singleTarget,
    baseCost: 130,
    damage: 80,
    range: 200,
    fireRate: 0.5,
    color: Color(0xFF0EA5E9),
    icon: '🎯',
  );

  static const bombardier = TowerCard(
    id: 'bombardier',
    name: 'Bombardier',
    description: 'Bigger splash, faster mortar.',
    rarity: TowerRarity.rare,
    type: TowerType.splash,
    baseCost: 140,
    damage: 55,
    range: 100,
    fireRate: 0.9,
    color: Color(0xFFDC2626),
    icon: '🚀',
  );

  static const blizzard = TowerCard(
    id: 'blizzard',
    name: 'Blizzard',
    description: 'Splash slow + frost damage.',
    rarity: TowerRarity.rare,
    type: TowerType.slow,
    baseCost: 120,
    damage: 14,
    range: 100,
    fireRate: 1.3,
    color: Color(0xFF67E8F9),
    icon: '❄️',
  );

  static const lightning = TowerCard(
    id: 'lightning',
    name: 'Lightning',
    description: 'Strong chain, hits 3.',
    rarity: TowerRarity.rare,
    type: TowerType.chain,
    baseCost: 135,
    damage: 28,
    range: 110,
    fireRate: 1.4,
    color: Color(0xFFA855F7),
    icon: '🌩️',
  );

  static const poison = TowerCard(
    id: 'poison',
    name: 'Poison',
    description: 'Heavy DoT, medium range.',
    rarity: TowerRarity.rare,
    type: TowerType.damageOverTime,
    baseCost: 125,
    damage: 9,
    range: 85,
    fireRate: 5.0,
    color: Color(0xFF22C55E),
    icon: '☠️',
  );

  // ─── LEGENDARIES (3) ─────────────────────────────────────────────────────
  static const dragon = TowerCard(
    id: 'dragon',
    name: 'Dragon',
    description: 'Massive splash + fire breath.',
    rarity: TowerRarity.legendary,
    type: TowerType.splash,
    baseCost: 220,
    damage: 90,
    range: 130,
    fireRate: 1.4,
    color: Color(0xFFE11D48),
    icon: '🐉',
  );

  static const frostKing = TowerCard(
    id: 'frost-king',
    name: 'Frost King',
    description: 'Chain freeze across enemies.',
    rarity: TowerRarity.legendary,
    type: TowerType.slow,
    baseCost: 200,
    damage: 30,
    range: 130,
    fireRate: 1.5,
    color: Color(0xFFBAE6FD),
    icon: '👑',
  );

  static const holyBlade = TowerCard(
    id: 'holy-blade',
    name: 'Holy Blade',
    description: 'Devastating single target precision.',
    rarity: TowerRarity.legendary,
    type: TowerType.singleTarget,
    baseCost: 230,
    damage: 180,
    range: 140,
    fireRate: 1.0,
    color: Color(0xFFFEF3C7),
    icon: '⚔️',
  );

  static const List<TowerCard> common = [
    archer, cannon, frost, flame, slingshot, mortar, tesla, spike,
  ];

  static const List<TowerCard> rare = [
    sniper, bombardier, blizzard, lightning, poison,
  ];

  static const List<TowerCard> legendary = [dragon, frostKing, holyBlade];

  static const List<TowerCard> all = [
    archer, cannon, frost, flame, slingshot, mortar, tesla, spike,
    sniper, bombardier, blizzard, lightning, poison,
    dragon, frostKing, holyBlade,
  ];

  static TowerCard byId(String id) =>
      all.firstWhere((c) => c.id == id, orElse: () => archer);
}
