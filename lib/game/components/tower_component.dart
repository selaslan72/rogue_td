import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../../models/run_stats.dart';
import '../../models/tower_card.dart';
import 'enemy_component.dart';
import 'particle_effect.dart';

/// Yerleştirilmiş tower. Range içindeki düşmanları tarayıp ateş eder.
/// MVP'de projectile yok — instant hit + flash + particle efekti.
class TowerComponent extends PositionComponent with TapCallbacks {
  final TowerCard card;
  final TargetingMode targeting;
  final void Function(TowerComponent) onTap;
  final RunStats stats;

  int level = 1; // 1..3

  double _cooldown = 0;
  EnemyComponent? _currentTarget;
  double _muzzleFlash = 0;

  late final Paint _bodyPaint;
  static final _rangeSelectedPaint = Paint()
    ..color = const Color(0x55FBBF24)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final _flashPaint = Paint()..color = const Color(0xFFFBBF24);
  static final _bodyOutlinePaint = Paint()
    ..color = Colors.black87
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final _corePaint = Paint()..color = const Color(0xE6FFFFFF);
  static final _levelOnPaint = Paint()..color = const Color(0xFFFBBF24);
  static final _levelOffPaint = Paint()..color = Colors.white24;

  bool showRange = false;

  // Level çarpanları
  double get _damageMul => level == 1 ? 1.0 : level == 2 ? 1.5 : 2.0;
  double get _rangeMul => 1.0 + (level - 1) * 0.10;
  double get _fireRateMul => 1.0 + (level - 1) * 0.20;

  double get currentDamage => card.damage * _damageMul * stats.damageMul;
  double get currentRange => card.range * _rangeMul * stats.rangeMul;
  double get currentFireRate => card.fireRate * _fireRateMul * stats.fireRateMul;

  bool get canUpgrade => level < 3;
  int get upgradeCost => (card.baseCost * (level == 1 ? 1.0 : 1.5)).round();

  void upgrade() {
    if (canUpgrade) level++;
  }

  TowerComponent({
    required this.card,
    required Vector2 worldPosition,
    required this.onTap,
    required this.stats,
    this.targeting = TargetingMode.first,
  }) : super(
          position: worldPosition,
          size: Vector2.all(36),
          anchor: Anchor.center,
          priority: 4,
        ) {
    _bodyPaint = Paint()..color = card.color;
  }

  @override
  bool onTapDown(TapDownEvent event) {
    onTap(this);
    return true;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_cooldown > 0) _cooldown -= dt;
    if (_muzzleFlash > 0) _muzzleFlash -= dt * 4;

    if (_currentTarget != null) {
      if (!_currentTarget!.isMounted ||
          !_currentTarget!.isAlive ||
          !_inRange(_currentTarget!)) {
        _currentTarget = null;
      }
    }

    _currentTarget ??= _acquireTarget();

    if (_currentTarget != null && _cooldown <= 0) {
      _fire(_currentTarget!);
      _cooldown = 1.0 / currentFireRate;
      _muzzleFlash = 1.0;
    }
  }

  bool _inRange(EnemyComponent enemy) {
    return enemy.worldPosition.distanceTo(position) <= currentRange;
  }

  EnemyComponent? _acquireTarget() {
    final enemies = parent?.children.whereType<EnemyComponent>().where(_inRange);
    if (enemies == null || enemies.isEmpty) return null;

    switch (targeting) {
      case TargetingMode.first:
        return enemies.reduce(
          (a, b) => a.worldPosition.y > b.worldPosition.y ? a : b,
        );
      case TargetingMode.strongest:
        return enemies.reduce(
          (a, b) => a.def.maxHp > b.def.maxHp ? a : b,
        );
      case TargetingMode.weakest:
        return enemies.reduce(
          (a, b) => a.hpRatio < b.hpRatio ? a : b,
        );
      case TargetingMode.closest:
        return enemies.reduce(
          (a, b) => a.worldPosition.distanceTo(position) <
                  b.worldPosition.distanceTo(position)
              ? a
              : b,
        );
    }
  }

  void _spawnHit(Vector2 worldPos) {
    parent?.add(ParticleEffect(
      worldPosition: worldPos,
      color: card.color,
      duration: 0.3,
      maxRadius: 10,
    ));
  }

  void _fire(EnemyComponent target) {
    switch (card.type) {
      case TowerType.singleTarget:
        target.takeDamage(currentDamage);
        _spawnHit(target.worldPosition.clone());
      case TowerType.splash:
        target.takeDamage(currentDamage);
        _spawnHit(target.worldPosition.clone());
        const splashRadius = 60.0;
        final others = parent?.children.whereType<EnemyComponent>() ?? [];
        for (final e in others) {
          if (e != target &&
              e.worldPosition.distanceTo(target.worldPosition) <= splashRadius) {
            e.takeDamage(currentDamage * 0.6);
          }
        }
      case TowerType.slow:
        target.takeDamage(currentDamage);
        target.applySlow(0.5, 1.5);
        _spawnHit(target.worldPosition.clone());
      case TowerType.damageOverTime:
        target.takeDamage(currentDamage);
        _spawnHit(target.worldPosition.clone());
      case TowerType.chain:
        // Tesla = 2 zincir, Lightning = 3, Frost King = 3, default 2
        final chainCount = card.id == 'lightning' || card.id == 'frost-king' ? 3 : 2;
        target.takeDamage(currentDamage);
        _spawnHit(target.worldPosition.clone());
        var lastHit = target;
        var dmg = currentDamage * 0.7;
        final hit = <EnemyComponent>{target};
        for (int i = 1; i < chainCount; i++) {
          final next = _findChainNext(lastHit, hit);
          if (next == null) break;
          next.takeDamage(dmg);
          if (card.id == 'frost-king') next.applySlow(0.4, 1.2);
          _spawnHit(next.worldPosition.clone());
          hit.add(next);
          lastHit = next;
          dmg *= 0.7;
        }
      case TowerType.support:
        break;
    }
  }

  EnemyComponent? _findChainNext(EnemyComponent from, Set<EnemyComponent> hit) {
    const chainRadius = 80.0;
    EnemyComponent? best;
    double bestDist = chainRadius;
    final all = parent?.children.whereType<EnemyComponent>() ?? [];
    for (final e in all) {
      if (hit.contains(e) || !e.isAlive) continue;
      final d = e.worldPosition.distanceTo(from.worldPosition);
      if (d < bestDist) {
        bestDist = d;
        best = e;
      }
    }
    return best;
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);

    if (showRange) {
      canvas.drawCircle(center, currentRange, _rangeSelectedPaint);
    }

    // Tower body
    canvas.drawCircle(center, size.x / 2 - 2, _bodyPaint);
    canvas.drawCircle(center, size.x / 2 - 2, _bodyOutlinePaint);

    // İç çekirdek
    canvas.drawCircle(center, 6, _corePaint);

    // Muzzle flash
    if (_muzzleFlash > 0 && _currentTarget != null) {
      final dir = (_currentTarget!.worldPosition - position).normalized();
      final tip = center + Offset(dir.x, dir.y) * (size.x / 2);
      canvas.drawCircle(tip, 4 * _muzzleFlash, _flashPaint);
    }

    // Level göstergesi — tabanda 3 dot
    if (level > 1) {
      const dotR = 3.0;
      const gap = 8.0;
      final startX = center.dx - gap;
      final dotY = center.dy + size.y / 2 - 4;
      for (int i = 0; i < 3; i++) {
        canvas.drawCircle(
          Offset(startX + i * gap, dotY),
          dotR,
          i < level ? _levelOnPaint : _levelOffPaint,
        );
      }
    }
  }
}
