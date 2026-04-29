import 'package:flutter/material.dart';

/// Modifier'ın oyuna nasıl uygulanacağını anlatan kategori.
enum ModifierKind {
  startingGold,        // +X gold (başlangıçta)
  extraLives,          // +X lives (başlangıçta)
  goldBonus,           // her kill'den +%X bonus gold
  damageBoost,         // tüm tower damage * (1+X)
  fireRateBoost,       // tüm tower fire rate * (1+X)
  rangeBoost,          // tüm tower range * (1+X)
  enemyHpReduction,    // düşman HP * (1-X)
  enemySpeedReduction, // düşman speed * (1-X)
  // — Düşman güçlendirme —
  enemyHpBoost,        // düşman HP * (1+X)
  enemySpeedBoost,     // düşman speed * (1+X)
  enemyArmorBoost,     // düşmanlara +X flat zırh
  enemyCountBoost,     // wave düşman sayısı * (1+X)
}

@immutable
class RunModifier {
  final String id;
  final String name;
  final String description;
  final String icon;
  final ModifierKind kind;
  final double value;

  const RunModifier({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.kind,
    required this.value,
  });
}
