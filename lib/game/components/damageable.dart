import 'package:flame/components.dart';

/// Tower'ların ateş edebileceği herhangi bir hedef.
/// EnemyComponent, TreeComponent, RockComponent bunu implement eder.
abstract class Damageable {
  bool get isMounted;
  bool get isAlive;
  Vector2 get worldPosition;
  void takeDamage(double amount);
}
