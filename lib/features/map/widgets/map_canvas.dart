import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // World + player + dashed lines
            ListenableBuilder(
              listenable: walkAnimation,
              builder: (_, __) => CustomPaint(
                painter: _PokemonWorldPainter(
                  simulations: simulations,
                  tick: walkAnimation.value,
                ),
                size: Size(w, h),
              ),
            ),
            // NPC avatars as Flutter widgets
            ...simulations.map((sim) => Positioned(
                  left: sim.x * w - 22,
                  top: sim.y * h - 22,
                  child: _NpcAvatarWidget(
                    sim: sim,
                    tick: walkAnimation,
                    onTap: () => onSimTap?.call(sim),
                  ),
                )),
          ],
        );
      },
    );
  }
}

// ── NPC Avatar Widget ────────────────────────────────────────────────────────

class _NpcAvatarWidget extends StatelessWidget {
  final SimulationEntry sim;
  final Animation<double> tick;
  final VoidCallback? onTap;

  const _NpcAvatarWidget({
    required this.sim,
    required this.tick,
    this.onTap,
  });

  static String _avatarUrl(String userId) {
    const bg = 'b6e3f4,c0aede,d1d4f9,ffd5dc,ffdfbf';
    final seed = Uri.encodeComponent(userId);
    return 'https://api.dicebear.com/7.x/avataaars/svg?seed=$seed&backgroundColor=$bg';
  }

  @override
  Widget build(BuildContext context) {
    final isChatting = sim.status == SimulationStatus.chatting;
    final isActive = isChatting && sim.activeAgentId != null;
    final compat = sim.compatibility ?? 0;

    return GestureDetector(
      onTap: sim.status == SimulationStatus.completed ? onTap : null,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Avatar circle with pulse border
          AnimatedBuilder(
            animation: tick,
            builder: (_, child) {
              final pulse = isActive
                  ? (0.3 + 0.7 * sin(tick.value * pi * 4)).clamp(0.0, 1.0)
                  : 0.0;
              return Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF42A5F5).withValues(alpha: pulse * 0.9),
                    width: 3,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: const Color(0xFF42A5F5).withValues(alpha: pulse * 0.35),
                            blurRadius: 14,
                            spreadRadius: 3,
                          ),
                        ]
                      : null,
                ),
                child: child,
              );
            },
            child: ClipOval(
              child: SvgPicture.network(
                _avatarUrl(sim.otherUserId),
                width: 44,
                height: 44,
                placeholderBuilder: (_) => Container(
                  color: const Color(0xFF90CAF9),
                  child: const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Speech bubble above avatar
          if (isChatting)
            Positioned(
              bottom: 48,
              child: _BubbleWidget(sim: sim, tick: tick),
            ),
          // Compatibility badge below avatar
          if (!isChatting)
            Positioned(
              top: 46,
              child: _CompatBadge(compat: compat),
            ),
        ],
      ),
    );
  }
}

// ── Speech Bubble ────────────────────────────────────────────────────────────

class _BubbleWidget extends StatelessWidget {
  final SimulationEntry sim;
  final Animation<double> tick;

  const _BubbleWidget({required this.sim, required this.tick});

  @override
  Widget build(BuildContext context) {
    if (sim.lastTurnText != null) {
      return Container(
        constraints: const BoxConstraints(maxWidth: 110),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(1, 2))
          ],
        ),
        child: Text(
          sim.lastTurnText!,
          style: const TextStyle(
              fontSize: 9, color: Color(0xFF1A1A2E), height: 1.3),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    if (sim.activeAgentId != null) {
      return AnimatedBuilder(
        animation: tick,
        builder: (_, __) {
          final t = tick.value;
          return Container(
            width: 38,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(1, 2))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final bounce = sin((t * pi * 2) + i * 0.8) * 2.5;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: Transform.translate(
                    offset: Offset(0, -bounce),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF9CA3AF),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }
}

// ── Compatibility Badge ───────────────────────────────────────────────────────

class _CompatBadge extends StatelessWidget {
  final double compat;

  const _CompatBadge({required this.compat});

  @override
  Widget build(BuildContext context) {
    final pct = '${(compat * 100).toInt()}%';
    if (compat > 0.6) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFEF5350),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '❤ $pct',
          style: const TextStyle(
              color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        pct,
        style: const TextStyle(
            color: Color(0xFF9E9E9E),
            fontSize: 9,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── World Painter ─────────────────────────────────────────────────────────────

class _PokemonWorldPainter extends CustomPainter {
  final List<SimulationEntry> simulations;
  final double tick;

  _PokemonWorldPainter({required this.simulations, required this.tick});

  @override
  void paint(Canvas canvas, Size size) {
    final groundY = size.height * 0.22;

    _drawSky(canvas, size, groundY);
    _drawMountains(canvas, size, groundY);
    _drawGround(canvas, size, groundY);
    _drawWater(canvas, size, groundY);
    _drawPaths(canvas, size, groundY);
    _drawGrassDetails(canvas, size, groundY);
    _drawPixelTrees(canvas, size, groundY);
    _drawPixelHouses(canvas, size, groundY);
    _drawPixelFlowers(canvas, size, groundY);

    final cx = size.width / 2;
    final cy = size.height * 0.55;

    for (final sim in simulations) {
      _drawDashedLine(
          canvas, cx, cy, sim.x * size.width, sim.y * size.height, sim);
    }

    final bounce = 2 * sin(tick * pi * 2);
    final stepPhase = tick * 2 * pi;
    _drawPlayerCharacter(canvas, cx, cy + bounce, stepPhase);
  }

  void _drawSky(Canvas canvas, Size size, double groundY) {
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF87CEEB),
          Color(0xFFB8E4F9),
          Color(0xFFDCF0FF),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, groundY));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, groundY), skyPaint);

    final cloudPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    _drawPixelCloud(
        canvas, size.width * 0.12, groundY * 0.25, 1.2, cloudPaint);
    _drawPixelCloud(
        canvas, size.width * 0.5, groundY * 0.4, 0.9, cloudPaint);
    _drawPixelCloud(
        canvas, size.width * 0.82, groundY * 0.2, 1.0, cloudPaint);
  }

  void _drawPixelCloud(
      Canvas canvas, double x, double y, double s, Paint paint) {
    final p = 4.0 * s;
    for (final dy in [0.0, -p]) {
      for (final dx in [-3 * p, -2 * p, -1 * p, 0.0, p, 2 * p]) {
        canvas.drawRect(Rect.fromLTWH(x + dx, y + dy, p, p), paint);
      }
    }
    for (final dx in [-4 * p, -3 * p, 3 * p, 4 * p]) {
      canvas.drawRect(Rect.fromLTWH(x + dx, y + p, p, p), paint);
    }
    for (final dx in [-2 * p, -1 * p, 0.0, p]) {
      canvas.drawRect(Rect.fromLTWH(x + dx, y - 2 * p, p, p), paint);
    }
  }

  void _drawMountains(Canvas canvas, Size size, double groundY) {
    final mtPaint = Paint()..color = const Color(0xFF7CB342);
    final mtDark = Paint()..color = const Color(0xFF689F38);
    final snowPaint = Paint()..color = Colors.white;

    final peaks = [
      [size.width * 0.15, groundY, 60.0],
      [size.width * 0.45, groundY, 45.0],
      [size.width * 0.75, groundY, 55.0],
    ];
    for (final pk in peaks) {
      final px = pk[0], py = pk[1], h = pk[2];
      final path = Path()
        ..moveTo(px - h * 1.2, py)
        ..lineTo(px, py - h)
        ..lineTo(px + h * 1.2, py)
        ..close();
      canvas.drawPath(path, mtPaint);
      final darkPath = Path()
        ..moveTo(px + h * 0.3, py)
        ..lineTo(px, py - h)
        ..lineTo(px + h * 1.2, py)
        ..close();
      canvas.drawPath(darkPath, mtDark);
      final snowPath = Path()
        ..moveTo(px - h * 0.25, py - h * 0.7)
        ..lineTo(px, py - h)
        ..lineTo(px + h * 0.25, py - h * 0.7)
        ..close();
      canvas.drawPath(snowPath, snowPaint);
    }
  }

  void _drawGround(Canvas canvas, Size size, double groundY) {
    final grassPaint = Paint()..color = const Color(0xFF8BC34A);
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, size.width, size.height - groundY),
      grassPaint,
    );

    const tileW = 20.0;
    const tileH = 20.0;
    final darkGrass = Paint()..color = const Color(0xFF7CB342);
    for (double x = 0; x < size.width; x += tileW) {
      for (double y = groundY; y < size.height; y += tileH) {
        final ix = (x / tileW).floor();
        final iy = ((y - groundY) / tileH).floor();
        if ((ix + iy) % 2 == 0) {
          canvas.drawRect(Rect.fromLTWH(x, y, tileW, tileH), darkGrass);
        }
      }
    }
  }

  void _drawWater(Canvas canvas, Size size, double groundY) {
    final waterPaint = Paint()..color = const Color(0xFF42A5F5);
    final waterX = size.width * 0.7;
    final waterW = size.width * 0.28;
    final waterY = groundY + (size.height - groundY) * 0.5;
    final waterH = (size.height - groundY) * 0.25;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(waterX, waterY, waterW, waterH),
        const Radius.circular(8),
      ),
      waterPaint,
    );

    final wavePaint = Paint()
      ..color = const Color(0xFF64B5F6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 3; i++) {
      final wy = waterY + 8 + i * (waterH / 4);
      final wavePath = Path();
      for (double wx = waterX + 4; wx < waterX + waterW - 4; wx += 12) {
        final yOff = 2 * sin((wx + tick * 100) * 0.1 + i);
        if (wx == waterX + 4) {
          wavePath.moveTo(wx, wy + yOff);
        } else {
          wavePath.lineTo(wx, wy + yOff);
        }
      }
      canvas.drawPath(wavePath, wavePaint);
    }
  }

  void _drawPaths(Canvas canvas, Size size, double groundY) {
    final pathPaint = Paint()..color = const Color(0xFFD7CCC8);
    final pathBorder = Paint()..color = const Color(0xFFBCAAA4);
    final cx = size.width / 2;
    final pathY = groundY + (size.height - groundY) * 0.45;
    const pathW = 20.0;

    canvas.drawRect(
      Rect.fromLTWH(0, pathY - pathW / 2, size.width * 0.7, pathW),
      pathPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, pathY - pathW / 2, size.width * 0.7, 2),
      pathBorder,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, pathY + pathW / 2 - 2, size.width * 0.7, 2),
      pathBorder,
    );
    canvas.drawRect(
      Rect.fromLTWH(cx - pathW / 2, groundY, pathW, size.height - groundY),
      pathPaint,
    );
  }

  void _drawGrassDetails(Canvas canvas, Size size, double groundY) {
    final rng = Random(42);
    final grassBlade = Paint()
      ..color = const Color(0xFF558B2F)
      ..strokeWidth = 1.5;
    for (int i = 0; i < 40; i++) {
      final gx = rng.nextDouble() * size.width;
      final gy = groundY + rng.nextDouble() * (size.height - groundY);
      final sway = 2 * sin(tick * pi * 2 + i * 0.5);
      canvas.drawLine(
        Offset(gx, gy),
        Offset(gx + sway, gy - 6 - rng.nextDouble() * 4),
        grassBlade,
      );
    }
  }

  void _drawPixelTrees(Canvas canvas, Size size, double groundY) {
    final positions = [
      Offset(size.width * 0.08, groundY + (size.height - groundY) * 0.15),
      Offset(size.width * 0.88, groundY + (size.height - groundY) * 0.2),
      Offset(size.width * 0.12, groundY + (size.height - groundY) * 0.7),
      Offset(size.width * 0.55, groundY + (size.height - groundY) * 0.12),
      Offset(size.width * 0.35, groundY + (size.height - groundY) * 0.82),
    ];
    for (final pos in positions) {
      _drawRoundTree(canvas, pos.dx, pos.dy);
    }
  }

  void _drawRoundTree(Canvas canvas, double x, double y) {
    canvas.drawRect(
      Rect.fromLTWH(x - 3, y + 4, 6, 14),
      Paint()..color = const Color(0xFF795548),
    );
    canvas.drawCircle(
        Offset(x, y - 6), 14, Paint()..color = const Color(0xFF4CAF50));
    canvas.drawCircle(
        Offset(x - 4, y - 9), 8, Paint()..color = const Color(0xFF66BB6A));
    canvas.drawCircle(
        Offset(x + 5, y - 2), 7, Paint()..color = const Color(0xFF388E3C));
  }

  void _drawPixelHouses(Canvas canvas, Size size, double groundY) {
    _drawPokemonHouse(canvas, size.width * 0.25,
        groundY + (size.height - groundY) * 0.35, const Color(0xFFEFC9AF));
    _drawPokemonHouse(canvas, size.width * 0.55,
        groundY + (size.height - groundY) * 0.65, const Color(0xFFB3E5FC));
  }

  void _drawPokemonHouse(Canvas canvas, double x, double y, Color wallColor) {
    canvas.drawRect(
        Rect.fromLTWH(x - 16, y - 4, 32, 24), Paint()..color = wallColor);
    canvas.drawRect(Rect.fromLTWH(x - 20, y - 8, 40, 6),
        Paint()..color = const Color(0xFFD84315));
    final roofPath = Path()
      ..moveTo(x - 22, y - 6)
      ..lineTo(x, y - 24)
      ..lineTo(x + 22, y - 6)
      ..close();
    canvas.drawPath(roofPath, Paint()..color = const Color(0xFFE53935));
    canvas.drawRect(Rect.fromLTWH(x - 4, y + 4, 8, 16),
        Paint()..color = const Color(0xFF5D4037));
    canvas.drawRect(Rect.fromLTWH(x - 14, y - 2, 6, 6),
        Paint()..color = const Color(0xFF81D4FA));
    canvas.drawRect(Rect.fromLTWH(x + 8, y - 2, 6, 6),
        Paint()..color = const Color(0xFF81D4FA));
    canvas.drawRect(Rect.fromLTWH(x - 12, y, 2, 2),
        Paint()..color = Colors.white.withValues(alpha: 0.6));
  }

  void _drawPixelFlowers(Canvas canvas, Size size, double groundY) {
    final rng = Random(123);
    const colors = [
      Color(0xFFFFEB3B),
      Color(0xFFE91E63),
      Color(0xFFFF9800),
      Color(0xFFCE93D8),
    ];
    for (int i = 0; i < 25; i++) {
      final fx = rng.nextDouble() * size.width;
      final fy = groundY + rng.nextDouble() * (size.height - groundY);
      final sway = 1.5 * sin(tick * pi * 2 + i * 0.7);
      canvas.drawLine(
        Offset(fx, fy),
        Offset(fx + sway, fy + 5),
        Paint()
          ..color = const Color(0xFF4CAF50)
          ..strokeWidth = 1.5,
      );
      canvas.drawCircle(
          Offset(fx + sway, fy - 1), 3, Paint()..color = colors[i % 4]);
      canvas.drawCircle(
          Offset(fx + sway, fy - 1), 1.2, Paint()..color = Colors.white);
    }
  }

  void _drawPlayerCharacter(
      Canvas canvas, double x, double y, double stepPhase) {
    final legOff = sin(stepPhase) * 3;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + 22), width: 20, height: 8),
      Paint()..color = Colors.black.withValues(alpha: 0.1),
    );

    final skinPaint = Paint()..color = const Color(0xFFFFCC80);
    final hairPaint = Paint()..color = const Color(0xFF5D4037);
    final shirtPaint = Paint()..color = const Color(0xFF1B76F2);
    final pantsPaint = Paint()..color = const Color(0xFF1A237E);
    final shoePaint = Paint()..color = const Color(0xFFD32F2F);

    canvas.drawRect(
        Rect.fromLTWH(x - 3, y + 12 + legOff, 4, 8), pantsPaint);
    canvas.drawRect(
        Rect.fromLTWH(x - 1, y + 12 - legOff, 4, 8), pantsPaint);
    canvas.drawRect(
        Rect.fromLTWH(x - 3, y + 19 + legOff, 5, 3), shoePaint);
    canvas.drawRect(
        Rect.fromLTWH(x - 1, y + 19 - legOff, 5, 3), shoePaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - 8, y + 2, 16, 12),
        const Radius.circular(3),
      ),
      shirtPaint,
    );

    canvas.drawOval(Rect.fromLTWH(x - 6, y - 8, 12, 10), skinPaint);
    canvas.drawRect(Rect.fromLTWH(x - 6, y - 12, 12, 4), hairPaint);

    canvas.drawOval(
        Rect.fromLTWH(x - 5, y - 6, 5, 5), Paint()..color = Colors.white);
    canvas.drawOval(
        Rect.fromLTWH(x + 0, y - 6, 5, 5), Paint()..color = Colors.white);
    canvas.drawOval(
        Rect.fromLTWH(x - 4, y - 5, 3, 3), Paint()..color = Colors.black);
    canvas.drawOval(
        Rect.fromLTWH(x + 1, y - 5, 3, 3), Paint()..color = Colors.black);

    canvas.drawPath(
      Path()
        ..moveTo(x - 2, y)
        ..quadraticBezierTo(x, y + 3, x + 2, y),
      Paint()
        ..color = const Color(0xFFE65100)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawRect(Rect.fromLTWH(x - 4, y - 18, 8, 5),
        Paint()..color = const Color(0xFF1565C0));
    canvas.drawRect(
        Rect.fromLTWH(x - 2, y - 22, 4, 5), Paint()..color = Colors.white);
    canvas.drawCircle(
        Offset(x, y - 24), 3, Paint()..color = const Color(0xFFFFC107));

    final tp = TextPainter(
      text: const TextSpan(
        text: 'Você',
        style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontSize: 10,
            fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(x, y + 30),
        width: tp.width + 10,
        height: tp.height + 4,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(bgRect, Paint()..color = Colors.white.withValues(alpha: 0.9));
    tp.paint(canvas, Offset(x - tp.width / 2, y + 28));
  }

  Color _zoneLineColor(MapZone zone) => switch (zone) {
        MapZone.forest => const Color(0xFF66BB6A),
        MapZone.town   => const Color(0xFFFFB74D),
        MapZone.lake   => const Color(0xFF42A5F5),
        MapZone.meadow => const Color(0xFFD4E157),
      };

  void _drawDashedLine(Canvas canvas, double x1, double y1, double x2,
      double y2, SimulationEntry sim) {
    final paint = Paint()
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    if (sim.status == SimulationStatus.chatting) {
      paint.color = _zoneLineColor(sim.zone).withValues(alpha: 0.30);
    } else {
      final compat = sim.compatibility ?? 0;
      paint.color =
          (compat > 0.6 ? const Color(0xFFEF5350) : const Color(0xFF9E9E9E))
              .withValues(alpha: 0.2);
    }

    const dashLen = 5.0;
    const gapLen = 4.0;
    final dx = x2 - x1;
    final dy = y2 - y1;
    final dist = sqrt(dx * dx + dy * dy);
    final steps = (dist / (dashLen + gapLen)).floor();
    for (int i = 0; i < steps; i++) {
      final startFrac = (i * (dashLen + gapLen)) / dist;
      final endFrac = ((i * (dashLen + gapLen)) + dashLen) / dist;
      if (endFrac > 1) break;
      canvas.drawLine(
        Offset(x1 + dx * startFrac, y1 + dy * startFrac),
        Offset(x1 + dx * endFrac, y1 + dy * endFrac),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_PokemonWorldPainter old) => true;
}
