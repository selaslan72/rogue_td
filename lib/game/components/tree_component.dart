import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'damageable.dart';

enum TreeVariant { tree, bush, snowPine, snowBush }

/// Dekoratif + dövülebilir engel. `tree` = güçlü tek ağaç (HP 85, slot açar);
/// `bush` = zayıf çalı (HP 22, altın verir ve slot açar).
class TreeComponent extends PositionComponent
    with TapCallbacks
    implements Damageable {
  final double sizeScale;
  final int clusterId;
  final TreeVariant variant;
  final void Function(TreeComponent tree)? onDestroyed;
  final void Function(TreeComponent tree)? onTap;

  bool get givesSlot => true;

  bool selected = false;
  double _hp;
  double get hp => _hp;
  double _hitFlash = 0;

  TreeComponent({
    required Vector2 worldPosition,
    this.sizeScale = 1.0,
    this.variant = TreeVariant.tree,
    this.clusterId = -1,
    this.onDestroyed,
    this.onTap,
    double? maxHp,
  }) : _hp =
           maxHp ??
           (variant == TreeVariant.bush || variant == TreeVariant.snowBush
               ? 22.0
               : 85.0),
       super(
         position: worldPosition + Vector2(0, _yOffset(variant, sizeScale)),
         size:
             (variant == TreeVariant.bush || variant == TreeVariant.snowBush
                 ? Vector2(38, 26)
                 : Vector2(46, 56)) *
             sizeScale,
         anchor: Anchor.bottomCenter,
         priority: -5,
       );

  /// Hücre merkezinden bottomCenter anchor için offset: ağaç gövdesi cell'in
  /// alt yarısında otursun, taç üst yarıyı kaplasın → "boşluk yok" görünümü.
  static double _yOffset(TreeVariant v, double scale) {
    if (v == TreeVariant.bush || v == TreeVariant.snowBush) return 12 * scale;
    return 22 *
        scale; // 24 (yarım hücre) ~ kadar aşağı, gövde dibi hücre alt sınırına yakın
  }

  @override
  bool onTapDown(TapDownEvent event) {
    onTap?.call(this);
    return true;
  }

  @override
  bool get isAlive => _hp > 0;

  @override
  Vector2 get worldPosition => position - Vector2(0, size.y * 0.45);

  @override
  double get bodyRadius =>
      (variant == TreeVariant.bush || variant == TreeVariant.snowBush
          ? 18.0
          : 22.0) *
      sizeScale;

  @override
  void takeDamage(double amount) {
    if (_hp <= 0) return;
    _hp -= amount;
    _hitFlash = 1.0;
    if (_hp <= 0 && isMounted) {
      onDestroyed?.call(this);
      removeFromParent();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_hitFlash > 0) _hitFlash -= dt * 4;
  }

  // ── Tree paints ─────────────────────────────────────────────────────────────
  static final _trunkPaint = Paint()..color = const Color(0xFF6B3410);
  static final _trunkShadowPaint = Paint()..color = const Color(0xFF4A2208);
  static final _leafDarkPaint = Paint()..color = const Color(0xFF1A3E1A);
  static final _leafPaint = Paint()..color = const Color(0xFF2B5E2B);
  static final _leafLightPaint = Paint()..color = const Color(0xFF429438);
  static final _leafAccentPaint = Paint()..color = const Color(0xFF52A848);

  // ── Bush paints ─────────────────────────────────────────────────────────────
  static final _bushDarkPaint = Paint()..color = const Color(0xFF1E4A12);
  static final _bushMidPaint = Paint()..color = const Color(0xFF2E6B1E);
  static final _bushLightPaint = Paint()..color = const Color(0xFF48902E);

  // ── Winter paints ──────────────────────────────────────────────────────────
  static final _pineDarkPaint = Paint()..color = const Color(0xFF12363D);
  static final _pinePaint = Paint()..color = const Color(0xFF1F5B63);
  static final _pineLightPaint = Paint()..color = const Color(0xFF2D7C86);
  static final _snowPaint = Paint()..color = const Color(0xFFF4FBFF);
  static final _snowShadePaint = Paint()..color = const Color(0xFFCFE1EC);
  static final _snowBushPaint = Paint()..color = const Color(0xFFB8CCD8);
  static final _snowBushDarkPaint = Paint()..color = const Color(0xFF708B9C);

  @override
  void render(Canvas canvas) {
    switch (variant) {
      case TreeVariant.bush:
        _renderBush(canvas);
        break;
      case TreeVariant.snowPine:
        _renderSnowPine(canvas);
        break;
      case TreeVariant.snowBush:
        _renderSnowBush(canvas);
        break;
      case TreeVariant.tree:
        _renderTree(canvas);
        break;
    }
  }

  void _renderTree(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final flash = _hitFlash.clamp(0.0, 1.0);

    // Gövde
    final trunkW = w * 0.22;
    final trunkH = h * 0.28;
    final trunkRect = Rect.fromLTWH(
      (w - trunkW) / 2,
      h - trunkH,
      trunkW,
      trunkH,
    );
    canvas.drawRect(trunkRect, _trunkPaint);
    canvas.drawRect(
      Rect.fromLTWH(trunkRect.left, trunkRect.top, trunkW * 0.3, trunkH),
      _trunkShadowPaint,
    );

    final cx = w / 2;
    final base = h - trunkH + 5;

    // Katmanlı taç — geniş/dolu görünüm için 5 daire
    canvas.drawCircle(Offset(cx, base - h * 0.14), w * 0.56, _leafDarkPaint);
    canvas.drawCircle(
      Offset(cx + w * 0.14, base - h * 0.24),
      w * 0.40,
      _leafDarkPaint,
    );
    canvas.drawCircle(
      Offset(cx - w * 0.14, base - h * 0.24),
      w * 0.42,
      _leafDarkPaint,
    );
    canvas.drawCircle(Offset(cx, base - h * 0.36), w * 0.48, _leafPaint);
    canvas.drawCircle(
      Offset(cx - w * 0.08, base - h * 0.50),
      w * 0.30,
      _leafLightPaint,
    );
    canvas.drawCircle(
      Offset(cx + w * 0.10, base - h * 0.44),
      w * 0.20,
      _leafAccentPaint,
    );

    if (flash > 0) {
      canvas.drawCircle(
        Offset(cx, base - h * 0.32),
        w * 0.58,
        Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.45 * flash),
      );
    }
    if (selected) {
      canvas.drawCircle(
        Offset(cx, base - h * 0.32),
        w * 0.64,
        Paint()
          ..color = const Color(0xFFFBBF24)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }
  }

  void _renderBush(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final flash = _hitFlash.clamp(0.0, 1.0);

    final cx = w / 2;
    final cy = h * 0.52;

    // Arka koyu blob'lar
    canvas.drawCircle(Offset(cx - w * 0.22, cy + 1), w * 0.34, _bushDarkPaint);
    canvas.drawCircle(Offset(cx + w * 0.22, cy + 1), w * 0.32, _bushDarkPaint);
    // Ön orta blob'lar
    canvas.drawCircle(Offset(cx - w * 0.20, cy - 1), w * 0.32, _bushMidPaint);
    canvas.drawCircle(Offset(cx + w * 0.20, cy - 1), w * 0.30, _bushMidPaint);
    canvas.drawCircle(Offset(cx, cy - 2), w * 0.33, _bushMidPaint);
    // Parlak vurgu
    canvas.drawCircle(
      Offset(cx - w * 0.08, cy - h * 0.38),
      w * 0.14,
      _bushLightPaint,
    );
    canvas.drawCircle(
      Offset(cx + w * 0.10, cy - h * 0.28),
      w * 0.10,
      _bushLightPaint,
    );

    if (flash > 0) {
      canvas.drawCircle(
        Offset(cx, cy),
        w * 0.42,
        Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.45 * flash),
      );
    }
    if (selected) {
      canvas.drawCircle(
        Offset(cx, cy),
        w * 0.48,
        Paint()
          ..color = const Color(0xFFFBBF24)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
    }
  }

  void _renderSnowPine(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final flash = _hitFlash.clamp(0.0, 1.0);
    final cx = w / 2;

    final trunkW = w * 0.18;
    canvas.drawRect(
      Rect.fromLTWH((w - trunkW) / 2, h * 0.72, trunkW, h * 0.25),
      _trunkShadowPaint,
    );

    void branch(double top, double width, Paint paint) {
      final path = Path()
        ..moveTo(cx, top)
        ..lineTo(cx - width / 2, top + h * 0.25)
        ..lineTo(cx + width / 2, top + h * 0.25)
        ..close();
      canvas.drawPath(path, paint);
      canvas.drawLine(
        Offset(cx - width * 0.32, top + h * 0.18),
        Offset(cx + width * 0.26, top + h * 0.12),
        _snowPaint..strokeWidth = 3,
      );
    }

    branch(h * 0.05, w * 0.58, _pineLightPaint);
    branch(h * 0.22, w * 0.82, _pinePaint);
    branch(h * 0.42, w * 1.02, _pineDarkPaint);

    if (flash > 0) {
      canvas.drawCircle(
        Offset(cx, h * 0.46),
        w * 0.56,
        Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.45 * flash),
      );
    }
    if (selected) {
      canvas.drawCircle(
        Offset(cx, h * 0.48),
        w * 0.62,
        Paint()
          ..color = const Color(0xFFFBBF24)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }
  }

  void _renderSnowBush(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final flash = _hitFlash.clamp(0.0, 1.0);
    final cx = w / 2;
    final cy = h * 0.55;

    canvas.drawCircle(Offset(cx - w * 0.24, cy), w * 0.32, _snowBushDarkPaint);
    canvas.drawCircle(Offset(cx + w * 0.23, cy), w * 0.30, _snowBushDarkPaint);
    canvas.drawCircle(Offset(cx, cy - h * 0.08), w * 0.35, _snowBushPaint);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy - h * 0.28),
        width: w * 0.72,
        height: h * 0.34,
      ),
      _snowPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + w * 0.10, cy - h * 0.18),
        width: w * 0.36,
        height: h * 0.18,
      ),
      _snowShadePaint,
    );

    if (flash > 0) {
      canvas.drawCircle(
        Offset(cx, cy),
        w * 0.42,
        Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.45 * flash),
      );
    }
    if (selected) {
      canvas.drawCircle(
        Offset(cx, cy),
        w * 0.48,
        Paint()
          ..color = const Color(0xFFFBBF24)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
    }
  }
}
