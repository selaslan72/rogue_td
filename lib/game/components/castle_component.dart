import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Harita girişine (düşman spawn) ve çıkışına (oyuncu üssü) yerleştirilen kale.
/// Top-down stil: kapı bileşenin DİKEY ORTASINDA yola bakan tarafa açılır,
/// böylece path tam olarak kapıdan girer/çıkar (anchor=center, yola hizalı).
class CastleComponent extends PositionComponent {
  final bool isEntry;

  // Entry palette (koyu kahve / kırmızı aksan)
  static const _entryWall   = Color(0xFF3B2214);
  static const _entryTower  = Color(0xFF241609);
  static const _entryBattle = Color(0xFF1A0F06);
  static const _entryGate   = Color(0xFF0A0604);
  static const _entryWindow = Color(0xFFFF3B1A);

  // Exit palette (açık taş / mavi bayrak)
  static const _exitWall    = Color(0xFF6B7280);
  static const _exitTower   = Color(0xFF4B5563);
  static const _exitBattle  = Color(0xFF374151);
  static const _exitGate    = Color(0xFF111827);
  static const _exitWindow  = Color(0xFF93C5FD);
  static const _exitFlag    = Color(0xFF3B82F6);
  static const _exitPole    = Color(0xFFD1D5DB);

  static final _outlineP = Paint()
    ..color = Colors.black54
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;
  static final _portcullisP = Paint()
    ..color = Colors.black54
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;

  // Kale paletine göre cache'lenmiş paint'ler (per-frame allocation yok)
  late final Paint _wallP;
  late final Paint _towerP;
  late final Paint _battleP;
  late final Paint _gateP;
  late final Paint _windowP;
  late final Paint? _flagP;
  late final Paint? _poleP;

  CastleComponent({
    required Vector2 worldPosition,
    required this.isEntry,
  }) : super(
          position: worldPosition,
          size: Vector2(80, 90),
          anchor: Anchor.center,
          priority: 1,
        ) {
    if (isEntry) {
      _wallP   = Paint()..color = _entryWall;
      _towerP  = Paint()..color = _entryTower;
      _battleP = Paint()..color = _entryBattle;
      _gateP   = Paint()..color = _entryGate;
      _windowP = Paint()..color = _entryWindow;
      _flagP   = null;
      _poleP   = null;
    } else {
      _wallP   = Paint()..color = _exitWall;
      _towerP  = Paint()..color = _exitTower;
      _battleP = Paint()..color = _exitBattle;
      _gateP   = Paint()..color = _exitGate;
      _windowP = Paint()..color = _exitWindow;
      _flagP   = Paint()..color = _exitFlag;
      _poleP   = Paint()
        ..color = _exitPole
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
    }
  }

  @override
  void render(Canvas canvas) {
    isEntry ? _drawEnemyCastle(canvas) : _drawPlayerCastle(canvas);
  }

  // ────────────────────────── ENEMY CASTLE (gate sağda) ──────────────────────────

  void _drawEnemyCastle(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    const gateW = 22.0;
    const gateH = 26.0;
    final gateCY = h / 2; // = anchor center y → world y = path y ✓
    final gateY = gateCY - gateH / 2;
    final keepW = w - gateW + 4;

    // Main keep (sol-orta) — gate için sağda boşluk
    final keepRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 6, keepW, h - 12),
      const Radius.circular(3),
    );
    canvas.drawRRect(keepRect, _wallP);
    canvas.drawRRect(keepRect, _outlineP);

    // Battlements üst + alt
    _drawMerlons(canvas, 2, 0, keepW - 4, 6, 5, _battleP);
    _drawMerlons(canvas, 2, h - 6, keepW - 4, 6, 5, _battleP);

    // Gate barbican — keep'ten dışarı çıkıntı (üst+alt yuvarlak köşe)
    final barbican = RRect.fromRectAndCorners(
      Rect.fromLTWH(keepW - 4, gateY - 4, w - keepW + 4, gateH + 8),
      topRight: const Radius.circular(10),
      bottomRight: const Radius.circular(10),
    );
    canvas.drawRRect(barbican, _towerP);
    canvas.drawRRect(barbican, _outlineP);

    // Kapı oyuğu — kemer üst (RRect ile gerçekten yuvarlak köşe)
    final gateRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(keepW - 2, gateY, w - keepW + 2, gateH),
      topRight: const Radius.circular(10),
      bottomRight: const Radius.circular(10),
    );
    canvas.drawRRect(gateRect, _gateP);

    // Parlayan kırmızı "gözler" kapı kenarında (düşman teması)
    final eyeX = keepW + 3;
    canvas.drawCircle(Offset(eyeX, gateCY - 4), 1.8, _windowP);
    canvas.drawCircle(Offset(eyeX, gateCY + 4), 1.8, _windowP);

    // Ok yarıkları (arrow slits)
    _drawArrowSlot(canvas, 12, 18, _windowP);
    _drawArrowSlot(canvas, 30, 18, _windowP);
    _drawArrowSlot(canvas, 12, 60, _windowP);
    _drawArrowSlot(canvas, 30, 60, _windowP);

    // Sivri dikenler keep tepesinde
    _drawSpike(canvas, 10, 0, _towerP);
    _drawSpike(canvas, 22, 0, _towerP);
    _drawSpike(canvas, 34, 0, _towerP);
    _drawSpike(canvas, 46, 0, _towerP);
  }

  // ────────────────────────── PLAYER CASTLE (gate solda) ──────────────────────────

  void _drawPlayerCastle(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    const gateW = 22.0;
    const gateH = 26.0;
    final gateCY = h / 2;
    final gateY = gateCY - gateH / 2;
    final keepStart = gateW - 4; // gate solda → keep sağda

    // Main keep (sağ-orta)
    final keepRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(keepStart, 6, w - keepStart, h - 12),
      const Radius.circular(3),
    );
    canvas.drawRRect(keepRect, _wallP);
    canvas.drawRRect(keepRect, _outlineP);

    // Battlements üst + alt
    _drawMerlons(canvas, keepStart + 2, 0, w - keepStart - 4, 6, 5, _battleP);
    _drawMerlons(canvas, keepStart + 2, h - 6, w - keepStart - 4, 6, 5, _battleP);

    // Gate barbican — solda
    final barbican = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, gateY - 4, keepStart + 4, gateH + 8),
      topLeft: const Radius.circular(10),
      bottomLeft: const Radius.circular(10),
    );
    canvas.drawRRect(barbican, _towerP);
    canvas.drawRRect(barbican, _outlineP);

    // Kapı oyuğu — kemer üst (sol köşe)
    final gateRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, gateY, gateW, gateH),
      topLeft: const Radius.circular(10),
      bottomLeft: const Radius.circular(10),
    );
    canvas.drawRRect(gateRect, _gateP);

    // Portcullis bars (kapı ızgarası)
    for (int i = 0; i < 3; i++) {
      final bx = 4 + i * 6.0;
      canvas.drawLine(
        Offset(bx, gateY + 3),
        Offset(bx, gateY + gateH - 3),
        _portcullisP,
      );
    }
    canvas.drawLine(
      Offset(2, gateCY),
      Offset(gateW - 2, gateCY),
      _portcullisP,
    );

    // Pencereler (mavi ışık)
    _drawWindow(canvas, keepStart + 8, 18, _windowP, _outlineP);
    _drawWindow(canvas, keepStart + 26, 18, _windowP, _outlineP);
    _drawWindow(canvas, keepStart + 8, 58, _windowP, _outlineP);
    _drawWindow(canvas, keepStart + 26, 58, _windowP, _outlineP);

    // Bayrak — keep tepesinde
    final poleX = keepStart + (w - keepStart) / 2;
    canvas.drawLine(
      Offset(poleX, -2),
      Offset(poleX, 12),
      _poleP!,
    );
    final flagPath = Path()
      ..moveTo(poleX, -2)
      ..lineTo(poleX + 11, 2)
      ..lineTo(poleX, 6)
      ..close();
    canvas.drawPath(flagPath, _flagP!);
  }

  // ────────────────────────── HELPERS ──────────────────────────

  void _drawMerlons(Canvas canvas, double startX, double y, double totalW,
      double h, int count, Paint paint) {
    final slotW = totalW / (count * 2 - 1);
    for (int i = 0; i < count; i++) {
      canvas.drawRect(
        Rect.fromLTWH(startX + i * slotW * 2, y, slotW, h),
        paint,
      );
    }
  }

  void _drawArrowSlot(Canvas canvas, double x, double y, Paint paint) {
    canvas.drawRect(Rect.fromLTWH(x, y, 3, 8), paint);
    canvas.drawRect(Rect.fromLTWH(x - 1.5, y + 3, 6, 3), paint);
  }

  void _drawWindow(Canvas canvas, double x, double y, Paint fill, Paint outline) {
    final rr = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, 8, 10),
      const Radius.circular(3),
    );
    canvas.drawRRect(rr, fill);
    canvas.drawRRect(rr, outline);
  }

  void _drawSpike(Canvas canvas, double cx, double baseY, Paint paint) {
    final path = Path()
      ..moveTo(cx, baseY - 8)
      ..lineTo(cx - 2.5, baseY)
      ..lineTo(cx + 2.5, baseY)
      ..close();
    canvas.drawPath(path, paint);
  }
}
