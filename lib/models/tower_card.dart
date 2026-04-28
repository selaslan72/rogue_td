import 'package:flutter/material.dart';

/// Kart havuzu nadirlik kademeleri.
enum TowerRarity {
  common,
  rare,
  legendary,
}

/// Tower işlevsel tipleri — hedefleme stratejisi ve hasar tipini belirler.
enum TowerType {
  singleTarget, // Okçu, Büyücü
  splash,       // Top, Meteor
  slow,         // Dondurucu
  damageOverTime, // Alev, Zehir
  chain,        // Elektrik
  support,      // Radar, Kale
}

/// Hedefleme stratejisi — TowerComponent.update() içinde kullanılır.
enum TargetingMode {
  first,     // yola en ilerlemiş düşman (default)
  strongest, // max HP
  weakest,   // min HP (chain için ideal)
  closest,   // mesafe
}

/// Bir tower kartının değişmez veri tanımı.
/// Run sırasında oyuncu bunu seçer, [TowerComponent] bu tanımı kullanır.
@immutable
class TowerCard {
  final String id;
  final String name;
  final String description;
  final TowerRarity rarity;
  final TowerType type;
  final int baseCost;
  final double damage;
  final double range;
  final double fireRate; // saniyede kaç atış
  final Color color;
  final String icon; // emoji veya asset id (Sprint 2'de sprite'a geçecek)
  final List<String> synergyIds; // sinerji için tower id'leri

  const TowerCard({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    required this.type,
    required this.baseCost,
    required this.damage,
    required this.range,
    required this.fireRate,
    required this.color,
    required this.icon,
    this.synergyIds = const [],
  });
}
