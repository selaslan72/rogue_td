import 'run_modifier.dart';

/// Run sırasında geçerli olan global çarpanlar — modifier sonucu güncellenir.
/// Tower'lar ve düşman spawn'ı bu sınıfı okur.
class RunStats {
  double damageMul = 1.0;
  double fireRateMul = 1.0;
  double rangeMul = 1.0;
  double goldMul = 1.0;
  double enemyHpMul = 1.0;
  double enemySpeedMul = 1.0;
  double enemyArmorBonus = 0.0;
  double enemyCountMul = 1.0;
  final Map<String, int> towerTrainingLevels = {};

  void reset() {
    damageMul = 1.0;
    fireRateMul = 1.0;
    rangeMul = 1.0;
    goldMul = 1.0;
    enemyHpMul = 1.0;
    enemySpeedMul = 1.0;
    enemyArmorBonus = 0.0;
    enemyCountMul = 1.0;
    towerTrainingLevels.clear();
  }

  int towerTrainingLevel(String towerId) => towerTrainingLevels[towerId] ?? 0;

  void trainTower(String towerId) {
    towerTrainingLevels[towerId] = towerTrainingLevel(towerId) + 1;
  }

  double towerDamageMul(String towerId) =>
      1.0 + towerTrainingLevel(towerId) * 0.10;

  double towerRangeMul(String towerId) =>
      1.0 + towerTrainingLevel(towerId) * 0.05;

  void apply(RunModifier mod) {
    switch (mod.kind) {
      case ModifierKind.damageBoost:
        damageMul = 1 + mod.value;
      case ModifierKind.fireRateBoost:
        fireRateMul = 1 + mod.value;
      case ModifierKind.rangeBoost:
        rangeMul = 1 + mod.value;
      case ModifierKind.goldBonus:
        goldMul = 1 + mod.value;
      case ModifierKind.enemyHpReduction:
        enemyHpMul = 1 - mod.value;
      case ModifierKind.enemySpeedReduction:
        enemySpeedMul = 1 - mod.value;
      case ModifierKind.enemyHpBoost:
        enemyHpMul = 1 + mod.value;
      case ModifierKind.enemySpeedBoost:
        enemySpeedMul = 1 + mod.value;
      case ModifierKind.enemyArmorBoost:
        enemyArmorBonus = mod.value;
      case ModifierKind.enemyCountBoost:
        enemyCountMul = 1 + mod.value;
      case ModifierKind.startingGold:
      case ModifierKind.extraLives:
        break;
    }
  }
}
