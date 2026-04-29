import 'dart:math';
import '../models/run_modifier.dart';

class ModifierRegistry {
  ModifierRegistry._();

  static const all = <RunModifier>[
    RunModifier(
      id: 'rich-start',
      name: 'Rich Start',
      description: '+150 starting gold',
      icon: '💰',
      kind: ModifierKind.startingGold,
      value: 150,
    ),
    RunModifier(
      id: 'gold-rush',
      name: 'Gold Rush',
      description: '+30% gold from kills',
      icon: '🪙',
      kind: ModifierKind.goldBonus,
      value: 0.30,
    ),
    RunModifier(
      id: 'overdrive',
      name: 'Overdrive',
      description: '+25% tower damage',
      icon: '⚔️',
      kind: ModifierKind.damageBoost,
      value: 0.25,
    ),
    RunModifier(
      id: 'rapid-fire',
      name: 'Rapid Fire',
      description: '+25% tower fire rate',
      icon: '⚡',
      kind: ModifierKind.fireRateBoost,
      value: 0.25,
    ),
    RunModifier(
      id: 'eagle-eye',
      name: 'Eagle Eye',
      description: '+20% tower range',
      icon: '🦅',
      kind: ModifierKind.rangeBoost,
      value: 0.20,
    ),
    RunModifier(
      id: 'weakened-foes',
      name: 'Weakened Foes',
      description: '-20% enemy HP',
      icon: '🩸',
      kind: ModifierKind.enemyHpReduction,
      value: 0.20,
    ),
    RunModifier(
      id: 'molasses',
      name: 'Molasses',
      description: '-25% enemy speed',
      icon: '🐌',
      kind: ModifierKind.enemySpeedReduction,
      value: 0.25,
    ),
    RunModifier(
      id: 'titan',
      name: 'Titan',
      description: '+50% enemy HP',
      icon: '💪',
      kind: ModifierKind.enemyHpBoost,
      value: 0.50,
    ),
    RunModifier(
      id: 'berserk',
      name: 'Berserk',
      description: '+35% enemy speed',
      icon: '💨',
      kind: ModifierKind.enemySpeedBoost,
      value: 0.35,
    ),
    RunModifier(
      id: 'ironclad',
      name: 'Ironclad',
      description: 'All enemies gain +6 armor',
      icon: '🔩',
      kind: ModifierKind.enemyArmorBoost,
      value: 6,
    ),
    RunModifier(
      id: 'horde',
      name: 'Horde',
      description: '+40% enemies per wave',
      icon: '👹',
      kind: ModifierKind.enemyCountBoost,
      value: 0.40,
    ),
  ];

  static final _rng = Random();

  /// Run başında 3 modifier sun.
  static List<RunModifier> drawThree() {
    final pool = List.of(all)..shuffle(_rng);
    return pool.take(3).toList();
  }
}
