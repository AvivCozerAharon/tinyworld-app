import 'dart:math';
import 'dart:ui' show Canvas, RRect, Radius;
import 'package:flame/components.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart' show Color, Colors, TextStyle, FontWeight, Paint;
import 'package:tinyworld_app/features/map/map_controller.dart';

Color _colorFromId(String id) {
  const palette = [
    Color(0xFF4A90D9),
    Color(0xFFE67E22),
    Color(0xFF27AE60),
    Color(0xFF8E44AD),
    Color(0xFFE74C3C),
  ];
  final hash = id.codeUnits.fold(0, (a, b) => a ^ b);
  return palette[hash.abs() % palette.length];
}

String _initialsFromId(String id) {
  if (id.length >= 2) return id.substring(0, 2).toUpperCase();
  return id.toUpperCase();
}

class NpcComponent extends PositionComponent {
  SimulationEntry _sim;
  double _typingTimer = 0;

  _AvatarCircle? _avatar;
  _ChatBubble? _bubble;
  _StatusDots? _dots;
  _CompatPill? _pill;

  NpcComponent(this._sim, Vector2 screenPosition)
      : super(position: screenPosition, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _rebuild();
  }

  void updateFrom(SimulationEntry sim) {
    _sim = sim;
    _typingTimer = 0;
    if (isMounted) _rebuild();
  }

  void _rebuild() {
    _avatar = null;
    _bubble = null;
    _dots = null;
    _pill = null;
    removeAll(children.toList());

    final color = _colorFromId(_sim.otherUserId);
    final initials = _initialsFromId(_sim.otherUserId);

    _avatar = _AvatarCircle(color: color, initials: initials);
    add(_avatar!);

    if (_sim.lastTurnText != null) {
      _bubble = _ChatBubble(text: _sim.lastTurnText!);
      add(_bubble!);
    }

    if (_sim.activeAgentId != null) {
      _dots = _StatusDots();
      add(_dots!);
    } else if (_sim.status == SimulationStatus.completed &&
        _sim.compatibility != null) {
      _pill = _CompatPill(compatibility: _sim.compatibility!);
      add(_pill!);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _typingTimer += dt;
    if (_bubble != null && _typingTimer > 5.0) {
      _bubble?.removeFromParent();
      _bubble = null;
    }
    _dots?.tick(_typingTimer);
  }
}

class _AvatarCircle extends PositionComponent {
  final Color color;
  final String initials;

  _AvatarCircle({required this.color, required this.initials})
      : super(anchor: Anchor.center, size: Vector2.all(40));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleComponent(
      radius: 20,
      paint: PaletteEntry(color).paint(),
      anchor: Anchor.center,
    ));
    add(TextComponent(
      text: initials,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      anchor: Anchor.center,
    ));
  }
}

class _ChatBubble extends PositionComponent {
  final String text;

  _ChatBubble({required this.text})
      : super(position: Vector2(-60, -70), anchor: Anchor.bottomLeft);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final truncated = text.length > 40 ? '${text.substring(0, 37)}...' : text;
    add(_RoundedBubble(size: Vector2(120, 36)));
    add(TextComponent(
      text: truncated,
      position: Vector2(6, 8),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF333333),
          fontSize: 9,
        ),
      ),
    ));
  }
}

class _RoundedBubble extends PositionComponent {
  _RoundedBubble({required Vector2 size}) : super(size: size);

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(size.toRect(), const Radius.circular(8)),
      paint,
    );
  }
}

class _StatusDots extends PositionComponent {
  final List<CircleComponent> _dots = [];

  _StatusDots() : super(position: Vector2(-15, 22), anchor: Anchor.topLeft);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    for (int i = 0; i < 3; i++) {
      final dot = CircleComponent(
        radius: 3,
        position: Vector2(i * 10.0, 0),
        paint: PaletteEntry(const Color(0xFF888888)).paint(),
        anchor: Anchor.center,
      );
      _dots.add(dot);
      add(dot);
    }
  }

  void tick(double t) {
    for (int i = 0; i < _dots.length; i++) {
      _dots[i].position.y = -4 * sin((t * 4) + i * 1.0);
    }
  }
}

class _CompatPill extends PositionComponent {
  final double compatibility;

  _CompatPill({required this.compatibility})
      : super(position: Vector2(-24, 22), anchor: Anchor.topLeft);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final pct = (compatibility * 100).toInt();
    final color = compatibility > 0.6
        ? const Color(0xFFEF5350)
        : const Color(0xFF888888);
    add(RectangleComponent(
      size: Vector2(48, 20),
      paint: PaletteEntry(color).paint(),
    ));
    add(TextComponent(
      text: '$pct%',
      position: Vector2(6, 4),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    ));
  }
}
