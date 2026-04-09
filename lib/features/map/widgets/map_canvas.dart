import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tinyworld_app/features/map/map_controller.dart';

class MapCanvas extends StatelessWidget {
  final List<SimulationEntry> simulations;
  final Animation<double> walkAnimation;
  final void Function(SimulationEntry)? onSimTap;

  const MapCanvas({
    super.key,
    required this.simulations,
    required this.walkAnimation,
    this.onSimTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: walkAnimation,
      builder: (_, __) => CustomPaint(
        painter: _WorldPainter(
          simulations: simulations,
          tick: walkAnimation.value,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: (details) {
            final box = context.findRenderObject() as RenderBox;
            final size = box.size;
            for (final sim in simulations) {
              final dx = sim.x * size.width;
              final dy = sim.y * size.height;
              final dist = (details.localPosition - Offset(dx, dy)).distance;
              if (dist < 30) {
                onSimTap?.call(sim);
                return;
              }
            }
          },
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _WorldPainter extends CustomPainter {
  final List<SimulationEntry> simulations;
  final double tick;

  static const _grassDark = Color(0xFF3E8E41);
  static const _grassLight = Color(0xFF66BB6A);
  static const _pathColor = Color(0xFFD7CCC8);
  static const _skyTop = Color(0xFF81D4FA);
  static const _skyBottom = Color(0xFFE1F5FE);

  _WorldPainter({required this.simulations, required this.tick});

  @override
  void paint(Canvas canvas, Size size) {
    _drawSky(canvas, size);
    _drawGrass(canvas, size);
    _drawPaths(canvas, size);
    _drawTrees(canvas, size);
    _drawHouses(canvas, size);
    _drawFlowers(canvas, size);

    final cx = size.width / 2;
    final cy = size.height / 2;

    for (final sim in simulations) {
      _drawDashedLine(canvas, cx, cy, sim.x * size.width, sim.y * size.height, sim);
    }

    for (final sim in simulations) {
      _drawSimCharacter(canvas, sim.x * size.width, sim.y * size.height, sim);
    }

    final bounce = 3 * sin(tick * pi * 2);
    _drawCharacter(canvas, cx, cy + bounce, const Color(0xFF6C63FF), 'Você',
        radius: 16, showCrown: true);
  }

  void _drawSky(Canvas canvas, Size size) {
    final skyH = size.height * 0.18;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_skyTop, _skyBottom],
      ).createShader(Rect.fromLTWH(0, 0, size.width, skyH));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, skyH), paint);
    _drawCloud(canvas, size.width * 0.15, skyH * 0.3, 1.0);
    _drawCloud(canvas, size.width * 0.55, skyH * 0.5, 0.7);
    _drawCloud(canvas, size.width * 0.82, skyH * 0.35, 0.85);
  }

  void _drawCloud(Canvas canvas, double x, double y, double scale) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.85);
    final s = scale * 18;
    canvas.drawCircle(Offset(x, y), s, p);
    canvas.drawCircle(Offset(x - s * 0.8, y + s * 0.2), s * 0.7, p);
    canvas.drawCircle(Offset(x + s * 0.9, y + s * 0.15), s * 0.75, p);
  }

  void _drawGrass(Canvas canvas, Size size) {
    final grassTop = size.height * 0.14;
    canvas.drawRect(
      Rect.fromLTWH(0, grassTop, size.width, size.height - grassTop),
      Paint()..color = _grassLight,
    );
    final tileW = size.width / 10;
    final tileH = (size.height - grassTop) / 14;
    for (int i = 0; i < 10; i++) {
      for (int j = 0; j < 14; j++) {
        if ((i + j) % 2 == 0) {
          canvas.drawRect(
            Rect.fromLTWH(i * tileW, grassTop + j * tileH, tileW, tileH),
            Paint()..color = _grassDark.withValues(alpha: 0.25),
          );
        }
      }
    }
  }

  void _drawPaths(Canvas canvas, Size size) {
    final grassTop = size.height * 0.14;
    final paint = Paint()
      ..color = _pathColor
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, size.height * 0.5),
        Offset(size.width, size.height * 0.5), paint);
    canvas.drawLine(Offset(size.width * 0.5, grassTop),
        Offset(size.width * 0.5, size.height), paint);
  }

  void _drawTrees(Canvas canvas, Size size) {
    final positions = [
      Offset(size.width * 0.08, size.height * 0.25),
      Offset(size.width * 0.88, size.height * 0.3),
      Offset(size.width * 0.12, size.height * 0.75),
      Offset(size.width * 0.92, size.height * 0.8),
      Offset(size.width * 0.75, size.height * 0.18),
    ];
    for (final pos in positions) {
      _drawTree(canvas, pos.dx, pos.dy);
    }
  }

  void _drawTree(Canvas canvas, double x, double y) {
    canvas.drawRect(
      Rect.fromCenter(center: Offset(x, y + 10), width: 6, height: 16),
      Paint()..color = const Color(0xFF795548),
    );
    final foliage = Paint()..color = const Color(0xFF2E7D32);
    canvas.drawCircle(Offset(x, y - 4), 14, foliage);
    canvas.drawCircle(Offset(x - 8, y + 2), 10, foliage);
    canvas.drawCircle(Offset(x + 8, y + 2), 10, foliage);
  }

  void _drawHouses(Canvas canvas, Size size) {
    _drawHouse(canvas, size.width * 0.25, size.height * 0.38, const Color(0xFFEFC9AF));
    _drawHouse(canvas, size.width * 0.72, size.height * 0.62, const Color(0xFFB3E5FC));
  }

  void _drawHouse(Canvas canvas, double x, double y, Color wallColor) {
    canvas.drawRect(
      Rect.fromCenter(center: Offset(x, y + 6), width: 24, height: 18),
      Paint()..color = wallColor,
    );
    final roofPath = Path()
      ..moveTo(x - 16, y - 2)
      ..lineTo(x, y - 16)
      ..lineTo(x + 16, y - 2)
      ..close();
    canvas.drawPath(roofPath, Paint()..color = const Color(0xFFD84315));
    canvas.drawRect(
      Rect.fromCenter(center: Offset(x, y + 8), width: 6, height: 10),
      Paint()..color = const Color(0xFF795548),
    );
  }

  void _drawFlowers(Canvas canvas, Size size) {
    final rng = Random(42);
    final colors = [
      const Color(0xFFFFEB3B),
      const Color(0xFFE91E63),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
    ];
    for (int i = 0; i < 20; i++) {
      final fx = rng.nextDouble() * size.width;
      final fy = size.height * 0.2 + rng.nextDouble() * size.height * 0.7;
      canvas.drawCircle(Offset(fx, fy), 2.5, Paint()..color = colors[i % 4]);
      canvas.drawLine(
        Offset(fx, fy + 2.5),
        Offset(fx, fy + 7),
        Paint()..color = const Color(0xFF4CAF50)..strokeWidth = 1,
      );
    }
  }

  void _drawDashedLine(Canvas canvas, double x1, double y1, double x2,
      double y2, SimulationEntry sim) {
    final paint = Paint()
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    if (sim.status == SimulationStatus.chatting) {
      paint.color = const Color(0xFF42A5F5).withValues(alpha: 0.3);
    } else {
      final compat = sim.compatibility ?? 0;
      paint.color = (compat > 0.6
              ? const Color(0xFFEF5350)
              : const Color(0xFF9E9E9E))
          .withValues(alpha: 0.25);
    }

    final dashLen = 6.0;
    final gapLen = 4.0;
    final total = dashLen + gapLen;
    final dx = x2 - x1;
    final dy = y2 - y1;
    final dist = sqrt(dx * dx + dy * dy);
    final steps = (dist / total).floor();

    for (int i = 0; i < steps; i++) {
      final startFrac = (i * total) / dist;
      final endFrac = ((i * total) + dashLen) / dist;
      if (endFrac > 1) break;
      canvas.drawLine(
        Offset(x1 + dx * startFrac, y1 + dy * startFrac),
        Offset(x1 + dx * endFrac, y1 + dy * endFrac),
        paint,
      );
    }
  }

  void _drawSimCharacter(
      Canvas canvas, double x, double y, SimulationEntry sim) {
    final isChatting = sim.status == SimulationStatus.chatting;
    final isActive = isChatting && sim.activeAgentId != null;
    final compat = sim.compatibility ?? 0;
    final color = isChatting
        ? const Color(0xFF42A5F5)
        : compat > 0.6
            ? const Color(0xFFEF5350)
            : const Color(0xFF9E9E9E);

    _drawCharacter(canvas, x, y, color, '', radius: 13);

    if (isActive) {
      final pulse = 0.3 + 0.3 * sin(tick * pi * 4);
      canvas.drawCircle(
        Offset(x, y),
        20,
        Paint()..color = const Color(0xFF42A5F5).withValues(alpha: pulse),
      );
    }

    if (isChatting) {
      _drawChatBubble(canvas, x, y - 28, tick);
    } else {
      _drawCompatBadge(canvas, x, y - 28, compat);
    }
  }

  void _drawCharacter(Canvas canvas, double x, double y, Color color,
      String label, {double radius = 14, bool showCrown = false}) {
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(x, y + radius + 6),
          width: radius * 1.6,
          height: radius),
      Paint()..color = Colors.black.withValues(alpha: 0.08),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(x, y + radius * 0.5),
            width: radius * 1.2,
            height: radius * 1.4),
        Radius.circular(radius * 0.3),
      ),
      Paint()..color = color,
    );

    canvas.drawCircle(
        Offset(x, y - radius * 0.4), radius * 0.65, Paint()..color = color);

    canvas.drawCircle(
        Offset(x - radius * 0.2, y - radius * 0.5),
        1.5,
        Paint()..color = Colors.white);
    canvas.drawCircle(
        Offset(x + radius * 0.2, y - radius * 0.5),
        1.5,
        Paint()..color = Colors.white);

    final smilePath = Path()
      ..moveTo(x - radius * 0.2, y - radius * 0.2)
      ..quadraticBezierTo(
          x, y + radius * 0.1, x + radius * 0.2, y - radius * 0.2);
    canvas.drawPath(
      smilePath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );

    if (showCrown) {
      final cy = y - radius * 1.2;
      final crownPath = Path()
        ..moveTo(x - 8, cy + 4)
        ..lineTo(x - 6, cy - 3)
        ..lineTo(x - 2, cy + 1)
        ..lineTo(x, cy - 5)
        ..lineTo(x + 2, cy + 1)
        ..lineTo(x + 6, cy - 3)
        ..lineTo(x + 8, cy + 4)
        ..close();
      canvas.drawPath(crownPath, Paint()..color = const Color(0xFFFFC107));
    }

    if (label.isNotEmpty) {
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final bgRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x, y + radius * 1.6 + 6),
          width: tp.width + 8,
          height: tp.height + 4,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(
          bgRect, Paint()..color = const Color(0xFF37474F).withValues(alpha: 0.7));
      tp.paint(canvas, Offset(x - tp.width / 2, y + radius * 1.6 + 4));
    }
  }

  void _drawChatBubble(Canvas canvas, double x, double y, double t) {
    final bubbleY = y - 3 * sin(t * pi * 2);
    final bgPaint = Paint()..color = Colors.white;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(x, bubbleY), width: 26, height: 18),
      const Radius.circular(8),
    );
    canvas.drawRRect(rrect, bgPaint);

    final tailPath = Path()
      ..moveTo(x - 3, bubbleY + 8)
      ..lineTo(x, bubbleY + 14)
      ..lineTo(x + 3, bubbleY + 8)
      ..close();
    canvas.drawPath(tailPath, bgPaint);

    final dotPaint = Paint()..color = const Color(0xFF90A4AE);
    for (int i = 0; i < 3; i++) {
      final dx = x - 6 + i * 6.0;
      final bounce = sin((t * pi * 2) + i * 0.8) * 1.5;
      canvas.drawCircle(Offset(dx, bubbleY + bounce), 1.8, dotPaint);
    }
  }

  void _drawCompatBadge(Canvas canvas, double x, double y, double compat) {
    if (compat > 0.6) {
      final path = Path()
        ..moveTo(x, y + 4)
        ..cubicTo(x - 8, y - 4, x - 14, y + 4, x, y + 12)
        ..cubicTo(x + 14, y + 4, x + 8, y - 4, x, y + 4);
      canvas.drawPath(path, Paint()..color = const Color(0xFFEF5350));
      final tp = TextPainter(
        text: TextSpan(
          text: '${(compat * 100).toInt()}%',
          style: const TextStyle(
              color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y + 10));
    } else {
      final tp = TextPainter(
        text: TextSpan(
          text: '${(compat * 100).toInt()}%',
          style: const TextStyle(
              color: Color(0xFF757575), fontSize: 8, fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - 2));
    }
  }

  @override
  bool shouldRepaint(_WorldPainter old) => true;
}
