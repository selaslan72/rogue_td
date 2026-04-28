import 'dart:math' as math;

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
  late final Paint _accentPaint;
  late final Paint _strokePaint;
  static final _rangeSelectedPaint = Paint()
    ..color = const Color(0x55FBBF24)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final _flashPaint = Paint()..color = const Color(0xFFFBBF24);
  static final _basePaint = Paint()..color = const Color(0xFF374151);
  static final _baseOutlinePaint = Paint()
    ..color = Colors.black87
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final _darkPaint = Paint()..color = const Color(0xFF1F2937);
  static final _whitePaint = Paint()..color = Colors.white;
  static final _goldPaint = Paint()..color = const Color(0xFFFBBF24);
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
    _accentPaint = Paint()..color = _lighten(card.color, 0.25);
    _strokePaint = Paint()
      ..color = _darken(card.color, 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
  }

  static Color _lighten(Color c, double t) =>
      Color.lerp(c, Colors.white, t) ?? c;
  static Color _darken(Color c, double t) =>
      Color.lerp(c, Colors.black, t) ?? c;

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

  double _aimAngle() {
    if (_currentTarget != null) {
      final d = _currentTarget!.worldPosition - position;
      if (d.length2 > 0.01) return math.atan2(d.y, d.x);
    }
    return -math.pi / 2; // varsayılan: yukarı
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);

    if (showRange) {
      canvas.drawCircle(center, currentRange, _rangeSelectedPaint);
    }

    // Taban (tüm tower'lar için ortak — koyu disk)
    canvas.drawCircle(center, size.x / 2 - 2, _basePaint);
    canvas.drawCircle(center, size.x / 2 - 2, _baseOutlinePaint);

    // Karta özel silüet
    _renderModel(canvas, center);

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

  // ─── Model çizimleri ────────────────────────────────────────────────────
  // Her model card.color'ı vurgu olarak kullanır, ortak base disk üstüne
  // oturur. Yön gerektiren modeller `_aimAngle()` ile hedefe döner.

  void _renderModel(Canvas canvas, Offset center) {
    switch (card.id) {
      case 'archer':
        _renderBow(canvas, center);
      case 'slingshot':
        _renderSlingshot(canvas, center);
      case 'spike':
        _renderSword(canvas, center, gold: false);
      case 'holy-blade':
        _renderSword(canvas, center, gold: true);
      case 'sniper':
        _renderSniper(canvas, center);
      case 'cannon':
        _renderBarrel(canvas, center, length: 12, width: 8);
      case 'mortar':
        _renderMortar(canvas, center);
      case 'bombardier':
        _renderRocketPod(canvas, center);
      case 'dragon':
        _renderDragon(canvas, center);
      case 'frost':
        _renderSnowflake(canvas, center, spokes: 6, radius: 11);
      case 'blizzard':
        _renderSnowflake(canvas, center, spokes: 8, radius: 13);
      case 'frost-king':
        _renderFrostKing(canvas, center);
      case 'flame':
        _renderFlamethrower(canvas, center);
      case 'poison':
        _renderPoisonVat(canvas, center);
      case 'tesla':
        _renderTeslaCoil(canvas, center, disks: 2);
      case 'lightning':
        _renderTeslaCoil(canvas, center, disks: 3, withSpark: true);
      default:
        canvas.drawCircle(center, 8, _bodyPaint);
        canvas.drawCircle(center, 8, _strokePaint);
    }
  }

  void _withRotation(Canvas canvas, Offset center, double angle, void Function() draw) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    draw();
    canvas.restore();
  }

  // Yay: iki yan kavis + ok (yatay, ucu sağa).
  void _renderBow(Canvas canvas, Offset center) {
    _withRotation(canvas, center, _aimAngle(), () {
      final bowPaint = Paint()
        ..color = card.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      // Yay (sol tarafta)
      final rect = Rect.fromCircle(center: const Offset(-4, 0), radius: 9);
      canvas.drawArc(rect, -math.pi / 2.2, math.pi / 1.1, false, bowPaint);
      // Kiriş
      canvas.drawLine(const Offset(-4, -8), const Offset(-4, 8),
          Paint()..color = Colors.white70..strokeWidth = 1);
      // Ok (sağa doğru)
      canvas.drawLine(const Offset(-4, 0), const Offset(10, 0),
          Paint()..color = Colors.white..strokeWidth = 1.5);
      // Ok ucu
      final tip = Path()
        ..moveTo(13, 0)
        ..lineTo(9, -3)
        ..lineTo(9, 3)
        ..close();
      canvas.drawPath(tip, _whitePaint);
    });
  }

  // Sapan: Y formu, üst iki kol açılı.
  void _renderSlingshot(Canvas canvas, Offset center) {
    _withRotation(canvas, center, _aimAngle() + math.pi / 2, () {
      final p = Paint()
        ..color = card.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(0, 6), const Offset(0, -2), p);
      canvas.drawLine(const Offset(0, -2), const Offset(-7, -9), p);
      canvas.drawLine(const Offset(0, -2), const Offset(7, -9), p);
      // Lastik bandı
      canvas.drawLine(const Offset(-7, -9), const Offset(7, -9),
          Paint()..color = Colors.white70..strokeWidth = 1);
      // Mermi
      canvas.drawCircle(const Offset(0, -9), 2, _whitePaint);
    });
  }

  // Kılıç: dikey blade + crossguard + kabza.
  void _renderSword(Canvas canvas, Offset center, {required bool gold}) {
    _withRotation(canvas, center, _aimAngle() + math.pi / 2, () {
      final blade = gold ? _goldPaint : Paint()..color = const Color(0xFFE5E7EB);
      final guardColor = gold ? const Color(0xFFB45309) : card.color;
      // Blade
      canvas.drawRect(const Rect.fromLTWH(-1.5, -12, 3, 16), blade);
      canvas.drawRect(const Rect.fromLTWH(-1.5, -12, 3, 16),
          Paint()..color = Colors.black54..style = PaintingStyle.stroke..strokeWidth = 1);
      // Crossguard
      canvas.drawRect(const Rect.fromLTWH(-6, 3, 12, 2), Paint()..color = guardColor);
      // Hilt
      canvas.drawRect(const Rect.fromLTWH(-1.5, 5, 3, 5), Paint()..color = guardColor);
      // Pommel
      canvas.drawCircle(const Offset(0, 11), 2, Paint()..color = guardColor);
    });
  }

  // Sniper: uzun ince namlu + scope.
  void _renderSniper(Canvas canvas, Offset center) {
    _withRotation(canvas, center, _aimAngle(), () {
      // Namlu
      canvas.drawRect(const Rect.fromLTWH(-2, -2, 16, 4), _bodyPaint);
      canvas.drawRect(const Rect.fromLTWH(-2, -2, 16, 4), _strokePaint);
      // Dipçik
      canvas.drawRect(const Rect.fromLTWH(-8, -3, 6, 6), _darkPaint);
      // Scope
      canvas.drawCircle(const Offset(2, -5), 2.5, _darkPaint);
      canvas.drawCircle(const Offset(2, -5), 1.2, _whitePaint);
    });
  }

  // Genel namlu (cannon).
  void _renderBarrel(Canvas canvas, Offset center, {required double length, required double width}) {
    _withRotation(canvas, center, _aimAngle(), () {
      // Gövde diski
      canvas.drawCircle(Offset.zero, 7, _bodyPaint);
      canvas.drawCircle(Offset.zero, 7, _strokePaint);
      // Namlu
      canvas.drawRect(Rect.fromLTWH(2, -width / 2, length, width), _darkPaint);
      // Namlu ucu halkası
      canvas.drawCircle(Offset(2 + length, 0), width / 2 + 0.5, _strokePaint);
    });
  }

  // Mortar: tıknaz, dik açılı. Üstten bakış: kalın daire + içinde delik.
  void _renderMortar(Canvas canvas, Offset center) {
    canvas.drawCircle(center, 10, _bodyPaint);
    canvas.drawCircle(center, 10, _strokePaint);
    canvas.drawCircle(center, 6, _darkPaint);
    canvas.drawCircle(center, 3, _accentPaint);
    // 4 cıvata
    final boltPaint = Paint()..color = const Color(0xFF111827);
    for (int i = 0; i < 4; i++) {
      final a = i * math.pi / 2 + math.pi / 4;
      canvas.drawCircle(
        center + Offset(math.cos(a), math.sin(a)) * 8.5,
        1.2,
        boltPaint,
      );
    }
  }

  // Roket bataryası: iki silindir paralel.
  void _renderRocketPod(Canvas canvas, Offset center) {
    _withRotation(canvas, center, _aimAngle(), () {
      for (final dy in [-4.0, 4.0]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(-4, dy - 2, 14, 4), const Radius.circular(2)),
          _bodyPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(-4, dy - 2, 14, 4), const Radius.circular(2)),
          _strokePaint,
        );
        // Roket ucu
        canvas.drawCircle(Offset(10, dy), 1.5, _whitePaint);
      }
    });
  }

  // Ejderha: üçgen kafa + iki boynuz, yön gösterir.
  void _renderDragon(Canvas canvas, Offset center) {
    _withRotation(canvas, center, _aimAngle(), () {
      final head = Path()
        ..moveTo(12, 0)
        ..lineTo(-6, -8)
        ..lineTo(-6, 8)
        ..close();
      canvas.drawPath(head, _bodyPaint);
      canvas.drawPath(head, _strokePaint);
      // Boynuzlar
      final hornPaint = _darkPaint;
      canvas.drawLine(const Offset(-3, -6), const Offset(-9, -11), hornPaint..strokeWidth = 2);
      canvas.drawLine(const Offset(-3, 6), const Offset(-9, 11), hornPaint..strokeWidth = 2);
      // Göz
      canvas.drawCircle(const Offset(4, -2), 1.4, _goldPaint);
      // Burun deliği / alev hint
      canvas.drawCircle(const Offset(11, 0), 1.5, _accentPaint);
    });
  }

  // Kar tanesi.
  void _renderSnowflake(Canvas canvas, Offset center, {required int spokes, required double radius}) {
    final p = Paint()
      ..color = card.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < spokes; i++) {
      final a = i * 2 * math.pi / spokes;
      final tip = center + Offset(math.cos(a), math.sin(a)) * radius;
      canvas.drawLine(center, tip, p);
      // Yan çatallar
      final t1 = tip - Offset(math.cos(a) * 4, math.sin(a) * 4);
      final n = Offset(-math.sin(a), math.cos(a)) * 3;
      canvas.drawLine(t1, t1 + n, p);
      canvas.drawLine(t1, t1 - n, p);
    }
    canvas.drawCircle(center, 2.5, _whitePaint);
  }

  // Frost King: snowflake + altın taç şıkırtısı.
  void _renderFrostKing(Canvas canvas, Offset center) {
    _renderSnowflake(canvas, center, spokes: 6, radius: 12);
    // Taç sivri uçları (üst kısım)
    final crown = Path()
      ..moveTo(center.dx - 9, center.dy - 12)
      ..lineTo(center.dx - 6, center.dy - 16)
      ..lineTo(center.dx - 3, center.dy - 13)
      ..lineTo(center.dx, center.dy - 17)
      ..lineTo(center.dx + 3, center.dy - 13)
      ..lineTo(center.dx + 6, center.dy - 16)
      ..lineTo(center.dx + 9, center.dy - 12)
      ..close();
    canvas.drawPath(crown, _goldPaint);
    canvas.drawPath(crown,
        Paint()..color = Colors.black87..style = PaintingStyle.stroke..strokeWidth = 1);
  }

  // Alev makinesi: koni nozul.
  void _renderFlamethrower(Canvas canvas, Offset center) {
    _withRotation(canvas, center, _aimAngle(), () {
      // Tank
      canvas.drawCircle(const Offset(-3, 0), 6, _bodyPaint);
      canvas.drawCircle(const Offset(-3, 0), 6, _strokePaint);
      // Nozul (gövde)
      canvas.drawRect(const Rect.fromLTWH(2, -2, 6, 4), _darkPaint);
      // Koni ağız
      final cone = Path()
        ..moveTo(8, -3)
        ..lineTo(14, -6)
        ..lineTo(14, 6)
        ..lineTo(8, 3)
        ..close();
      canvas.drawPath(cone, _accentPaint);
      canvas.drawPath(cone, _strokePaint);
    });
  }

  // Zehir tankı: damla/şişe + baloncuk.
  void _renderPoisonVat(Canvas canvas, Offset center) {
    final flask = Path()
      ..moveTo(center.dx - 5, center.dy - 5)
      ..lineTo(center.dx + 5, center.dy - 5)
      ..lineTo(center.dx + 8, center.dy + 8)
      ..lineTo(center.dx - 8, center.dy + 8)
      ..close();
    canvas.drawPath(flask, _bodyPaint);
    canvas.drawPath(flask, _strokePaint);
    // Boyun
    canvas.drawRect(
        Rect.fromLTWH(center.dx - 3, center.dy - 10, 6, 5), _darkPaint);
    // Baloncuk
    canvas.drawCircle(center + const Offset(-2, 3), 1.5, _whitePaint);
    canvas.drawCircle(center + const Offset(2, 5), 1, _whitePaint);
    canvas.drawCircle(center + const Offset(0, 0), 1.2, _accentPaint);
  }

  // Tesla coil: dikey bar + N adet disk + isteğe bağlı şimşek.
  void _renderTeslaCoil(Canvas canvas, Offset center,
      {required int disks, bool withSpark = false}) {
    // Bar
    canvas.drawRect(
        Rect.fromLTWH(center.dx - 1.5, center.dy - 10, 3, 20), _darkPaint);
    // Disk'ler
    final h = 18.0 / (disks + 1);
    for (int i = 0; i < disks; i++) {
      final y = center.dy - 9 + h * (i + 1);
      canvas.drawOval(
          Rect.fromCenter(center: Offset(center.dx, y), width: 14, height: 4),
          _bodyPaint);
      canvas.drawOval(
          Rect.fromCenter(center: Offset(center.dx, y), width: 14, height: 4),
          _strokePaint);
    }
    // Tepe topu
    canvas.drawCircle(Offset(center.dx, center.dy - 11), 2.5, _accentPaint);
    if (withSpark) {
      final sparkPaint = Paint()
        ..color = _accentPaint.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      final spark = Path()
        ..moveTo(center.dx + 4, center.dy - 12)
        ..lineTo(center.dx + 7, center.dy - 9)
        ..lineTo(center.dx + 5, center.dy - 7)
        ..lineTo(center.dx + 9, center.dy - 4);
      canvas.drawPath(spark, sparkPaint);
    }
  }
}
