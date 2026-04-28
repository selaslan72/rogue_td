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
      id: 'fortified',
      name: 'Fortified',
      description: '+10 starting lives',
      icon: '🛡️',
      kind: ModifierKind.extraLives,
      value: 10,
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
  ];

  static final _rng = Random();

  /// Run başında 3 modifier sun.
  static List<RunModifier> drawThree() {
    final pool = List.of(all)..shuffle(_rng);
    return pool.take(3).toList();
  }
}
