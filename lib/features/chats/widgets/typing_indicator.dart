import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  final Color? dotColor;
  final double dotSize;

  const TypingIndicator({super.key, this.dotColor, this.dotSize = 6});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.dotColor ??
        Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final phase = (_ctrl.value * 3 + i) % 1.0;
            final bounce = (phase < 0.5)
                ? Curves.easeOut.transform(phase * 2)
                : Curves.easeIn.transform(1.0 - (phase - 0.5) * 2);
            final y = -bounce * 4;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              transform: Matrix4.translationValues(0, y, 0),
              child: Container(
                width: widget.dotSize,
                height: widget.dotSize,
                decoration: BoxDecoration(
                  color: Color.fromRGBO(
                    color.red.toInt(),
                    color.green.toInt(),
                    color.blue.toInt(),
                    0.4 + bounce * 0.6,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
