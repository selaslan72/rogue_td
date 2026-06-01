import 'package:flutter/foundation.dart';

import '../services/progress_service.dart';

/// Fragment ile satın alınan kalıcı meta upgrade tanımı (rün/perk).
/// Her perk seviyeli; seviye arttıkça maliyet [baseCost] + [costStep]×mevcutSeviye.
@immutable
class MetaPerk {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int maxLevel;
  final int baseCost;
  final int costStep;

  /// Seviye başına etki büyüklüğü (ör. +30 altın, +1 can, +0.04 = %4).
  final double perLevelValue;

  const MetaPerk({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.maxLevel,
    required this.baseCost,
    required this.costStep,
    required this.perLevelValue,
  });

  /// [currentLevel]'den bir üst seviyeye çıkmanın fragment maliyeti.
  int costForNext(int currentLevel) => baseCost + costStep * currentLevel;
}

/// Tüm meta perk'lerin kayıt defteri + mevcut perk seviyelerinden
/// run başında uygulanacak toplam bonusların hesaplanması.
class MetaPerks {
  MetaPerks._();

  static const treasury = MetaPerk(
    id: 'treasury',
    name: 'Hazine',
    description: 'Her run +30 başlangıç altını',
    icon: '💰',
    maxLevel: 5,
    baseCost: 8,
    costStep: 6,
    perLevelValue: 30,
  );

  static const ramparts = MetaPerk(
    id: 'ramparts',
    name: 'Surlar',
    description: 'Her run +1 başlangıç canı',
    icon: '🛡️',
    maxLevel: 5,
    baseCost: 10,
    costStep: 8,
    perLevelValue: 1,
  );

  static const sharpness = MetaPerk(
    id: 'sharpness',
    name: 'Keskinlik',
    description: 'Tüm kulelere +%4 hasar',
    icon: '⚔️',
    maxLevel: 5,
    baseCost: 12,
    costStep: 10,
    perLevelValue: 0.04,
  );

  static const eagleEye = MetaPerk(
    id: 'eagleEye',
    name: 'Kartal Gözü',
    description: 'Tüm kulelere +%5 menzil',
    icon: '🎯',
    maxLevel: 5,
    baseCost: 10,
    costStep: 8,
    perLevelValue: 0.05,
  );

  static const List<MetaPerk> all = [treasury, ramparts, sharpness, eagleEye];
}

/// Mevcut perk seviyelerinden türetilen, run başında uygulanan bonus seti.
@immutable
class MetaBonuses {
  final int bonusGold;
  final int bonusLives;
  final double damageMul;
  final double rangeMul;

  const MetaBonuses({
    this.bonusGold = 0,
    this.bonusLives = 0,
    this.damageMul = 1.0,
    this.rangeMul = 1.0,
  });

  factory MetaBonuses.fromProgress(ProgressService progress) {
    return MetaBonuses(
      bonusGold:
          (MetaPerks.treasury.perLevelValue *
                  progress.perkLevel(MetaPerks.treasury.id))
              .round(),
      bonusLives:
          (MetaPerks.ramparts.perLevelValue *
                  progress.perkLevel(MetaPerks.ramparts.id))
              .round(),
      damageMul:
          1.0 +
          MetaPerks.sharpness.perLevelValue *
              progress.perkLevel(MetaPerks.sharpness.id),
      rangeMul:
          1.0 +
          MetaPerks.eagleEye.perLevelValue *
              progress.perkLevel(MetaPerks.eagleEye.id),
    );
  }
}
