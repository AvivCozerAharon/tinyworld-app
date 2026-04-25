import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tinyworld_app/core/theme/styles.dart';

const _compatPhrases = [
  (0, 30, 'Conexão fraca — mas toda amizade começa em algum lugar.'),
  (30, 60, 'Boa energia! Vocês têm bastante em comum.'),
  (60, 80, 'Ótima química! Essa poderia ser uma amizade incrível.'),
  (80, 101, 'Conexão rara! Vocês foram feitos um para o outro.'),
];

class CompatibilityResultCard extends StatefulWidget {
  final double? compatibility;
  final double? scoreA;
  final double? scoreB;
  final String labelMe;
  final String labelOther;
  final Color colorMe;
  final Color colorOther;
  final int? completedTurns;
  final bool? earlyStopped;
  final VoidCallback? onStartRealChat;

  const CompatibilityResultCard({
    super.key,
    required this.compatibility,
    required this.scoreA,
    required this.scoreB,
    required this.labelMe,
    required this.labelOther,
    required this.colorMe,
    required this.colorOther,
    this.completedTurns,
    this.earlyStopped,
    this.onStartRealChat,
  });

  @override
  State<CompatibilityResultCard> createState() =>
      _CompatibilityResultCardState();
}

class _CompatibilityResultCardState extends State<CompatibilityResultCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _progress;
  ConfettiController? _confettiCtrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    if (widget.compatibility != null) {
      _ctrl.forward();
      if (widget.compatibility! > 0.7) {
        _confettiCtrl =
            ConfettiController(duration: const Duration(seconds: 2));
        _confettiCtrl!.play();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _confettiCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compatibility == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _progress,
      builder: (_, __) {
        final t = _progress.value;
        final animPct = (widget.compatibility! * 100 * t).toInt();
        final finalPct = (widget.compatibility! * 100).toInt();

        final finalRingColor = finalPct > 70
            ? TwColors.success
            : finalPct > 40
                ? TwColors.warning
                : TwColors.error;
        final ringColor = Color.lerp(TwColors.muted, finalRingColor, t)!;

        final phrase = _compatPhrases
            .where((p) => finalPct >= p.$1 && finalPct < p.$2)
            .map((p) => p.$3)
            .firstOrNull;

        return Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [TwColors.card, TwColors.cardAlt],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(TwRadius.xl),
                border: Border.all(color: TwColors.border),
                boxShadow: [
                  BoxShadow(
                    color: TwColors.primary.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    height: 4,
                    decoration: const BoxDecoration(
                      gradient: TwGradients.accent,
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(TwRadius.xl)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 90,
                          height: 90,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 90,
                                height: 90,
                                child: CircularProgressIndicator(
                                  value: widget.compatibility! * t,
                                  strokeWidth: 6,
                                  backgroundColor: TwColors.border,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      ringColor),
                                  strokeCap: StrokeCap.round,
                                ),
                              ),
                              Text(
                                '$animPct%',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: ringColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Compatibilidade',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            color: TwColors.muted,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (phrase != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            phrase,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              color: TwColors.onSurface,
                              height: 1.4,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _ScoreBar(
                                label: widget.labelMe,
                                score: widget.scoreA,
                                color: widget.colorMe),
                            const SizedBox(width: 12),
                            _ScoreBar(
                                label: widget.labelOther,
                                score: widget.scoreB,
                                color: widget.colorOther),
                          ],
                        ),
                        if (widget.completedTurns != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: TwColors.surface,
                              borderRadius:
                                  BorderRadius.circular(TwRadius.pill),
                            ),
                            child: Text(
                              '${widget.completedTurns} turnos${widget.earlyStopped == true ? ' · encerrado cedo' : ''}',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                color: TwColors.muted,
                              ),
                            ),
                          ),
                        ],
                        if (widget.onStartRealChat != null) ...[
                          const SizedBox(height: 20),
                          TwGradientButton(
                            onPressed: widget.onStartRealChat,
                            gradient: TwGradients.accent,
                            child: const Text('Iniciar conversa real'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_confettiCtrl != null)
              ConfettiWidget(
                confettiController: _confettiCtrl!,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                gravity: 0.2,
                colors: const [
                  TwColors.primary,
                  TwColors.secondary,
                  TwColors.success,
                  TwColors.warning,
                ],
              ),
          ],
        );
      },
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final double? score;
  final Color color;

  const _ScoreBar({required this.label, required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    final v = score ?? 0.0;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: GoogleFonts.spaceGrotesk(fontSize: 11, color: TwColors.muted)),
              Text(
                '${(v * 100).toInt()}',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: v,
              minHeight: 6,
              backgroundColor: TwColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
