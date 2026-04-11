import 'dart:math';
import 'package:flutter/material.dart';

class VoiceWaveButton extends StatefulWidget {
  final bool isListening;
  final VoidCallback onTap;
  final double size;
  final double? soundLevel;

  const VoiceWaveButton({
    super.key,
    required this.isListening,
    required this.onTap,
    this.size = 56,
    this.soundLevel,
  });

  @override
  State<VoiceWaveButton> createState() => _VoiceWaveButtonState();
}

class _VoiceWaveButtonState extends State<VoiceWaveButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void didUpdateWidget(VoiceWaveButton old) {
    super.didUpdateWidget(old);
    if (widget.isListening && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!widget.isListening && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.isListening
              ? const Color(0xFF1B76F2)
              : const Color(0xFFF5F7FA),
          boxShadow: widget.isListening
              ? [
                  BoxShadow(
                    color: const Color(0xFF1B76F2).withValues(alpha: 0.3),
                    blurRadius: 16,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: widget.isListening
            ? _buildWaveBars()
            : Icon(
                Icons.mic,
                size: widget.size * 0.4,
                color: const Color(0xFF6B7280),
              ),
      ),
    );
  }

  Widget _buildWaveBars() {
    const barCount = 5;
    final level = widget.soundLevel ?? 2.0;
    final normalizedLevel = (level.clamp(0.0, 10.0) / 10.0);

    return Center(
      child: ListenableBuilder(
        listenable: _ctrl,
        builder: (_, __) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(barCount, (i) {
              final phase = (_ctrl.value * 2 * pi) + (i * 0.8);
              final wave = sin(phase) * 0.5 + 0.5;
              final baseHeight = widget.size * 0.15;
              final maxExtra =
                  widget.size * 0.35 * (0.4 + normalizedLevel * 0.6);
              final barHeight = baseHeight + wave * maxExtra;

              return Container(
                width: 3,
                height: barHeight,
                margin: EdgeInsets.only(left: i == 0 ? 0 : 2.5, right: 2.5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
