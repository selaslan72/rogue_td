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

  void reset() {
    damageMul = 1.0;
    fireRateMul = 1.0;
    rangeMul = 1.0;
    goldMul = 1.0;
    enemyHpMul = 1.0;
    enemySpeedMul = 1.0;
  }

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
      case ModifierKind.startingGold:
      case ModifierKind.extraLives:
        // Tek seferlik — TdGame.startNewRun içinde uygulanır
        break;
    }
  }
}
