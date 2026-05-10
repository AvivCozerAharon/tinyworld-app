import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tinyworld_app/core/theme/styles.dart';

class StageView extends StatelessWidget {
  final String avatarUrl;
  final String genderLabel;
  final String currentMessage;
  final double? progress;
  final VoidCallback onSkip;
  final bool isLive;

  const StageView({
    super.key,
    required this.avatarUrl,
    required this.genderLabel,
    required this.currentMessage,
    this.progress,
    required this.onSkip,
    this.isLive = false,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [TwColors.bg, TwColors.surface],
        ),
      ),
      child: Stack(
        children: [
          // Progress bar at very top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 2,
              child: LinearProgressIndicator(
                value: isLive ? null : progress,
                minHeight: 2,
                backgroundColor: TwColors.border,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(TwColors.primary),
              ),
            ),
          ),

          // Skip button
          Positioned(
            top: top + 8,
            right: 16,
            child: GestureDetector(
              onTap: onSkip,
              child: Text(
                'Pular →',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: TwColors.muted,
                ),
              ),
            ),
          ),

          // Main centered content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: TwColors.border),
                      borderRadius:
                          BorderRadius.circular(TwRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.diamond,
                            size: 10, color: TwColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'TINYWORLD · AGENTES',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: TwColors.muted,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '↓  Arraste para ver a conversa',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      color: TwColors.muted.withValues(alpha: 0.6),
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Avatar with crossfade
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _StageAvatar(
                      key: ValueKey(avatarUrl),
                      url: avatarUrl,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Gender label with crossfade
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: Text(
                      genderLabel,
                      key: ValueKey(genderLabel),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: TwColors.muted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Message pill with slide+fade
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0, 0.15),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          )),
                          child: child,
                        ),
                      );
                    },
                    child: _MessagePill(
                      key: ValueKey(currentMessage),
                      text: currentMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StageAvatar extends StatelessWidget {
  final String url;
  const _StageAvatar({required super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: url.contains('dicebear') || url.endsWith('.svg')
          ? SvgPicture.network(
              url,
              width: 80,
              height: 80,
              placeholderBuilder: (_) => _placeholder(),
            )
          : Image.network(
              url,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            ),
    );
  }

  Widget _placeholder() => Container(
        width: 80,
        height: 80,
        decoration: const BoxDecoration(
          color: TwColors.card,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.person, size: 36, color: TwColors.muted),
      );
}

class _MessagePill extends StatelessWidget {
  final String text;
  const _MessagePill({required super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: TwColors.card,
        borderRadius: BorderRadius.circular(TwRadius.xxl),
        border: Border.all(color: TwColors.border),
      ),
      child: Text(
        text,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 15,
          color: TwColors.onBg,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
