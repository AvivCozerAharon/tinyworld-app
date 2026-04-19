import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tinyworld_app/core/theme/styles.dart';
import 'package:tinyworld_app/features/chats/chats_controller.dart';
import 'package:tinyworld_app/features/onboarding/widgets/avatar_preview.dart';

class ChatListItem extends StatelessWidget {
  final ChatItem chat;
  final VoidCallback onTap;

  const ChatListItem({super.key, required this.chat, required this.onTap});

  Color _ringColor(double compat) {
    final pct = (compat * 100).toInt();
    if (pct > 70) return TwColors.success;
    if (pct > 40) return TwColors.warning;
    return TwColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final compat = chat.compatibility;
    final pct = (compat * 100).toInt();
    final ring = _ringColor(compat);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TwColors.card,
          borderRadius: BorderRadius.circular(TwRadius.xl),
          border: Border.all(color: TwColors.border),
        ),
        child: Row(
          children: [
            // Avatar with compatibility ring
            SizedBox(
              width: 52,
              height: 52,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: CircularProgressIndicator(
                      value: compat,
                      strokeWidth: 3,
                      backgroundColor: TwColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(ring),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  chat.otherAvatar.isNotEmpty
                      ? ClipOval(
                          child: AvatarPreview(
                              avatarUrl: chat.otherAvatar, size: 42),
                        )
                      : Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            color: TwColors.surface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person,
                              size: 22, color: TwColors.muted),
                        ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '???',
                    style: GoogleFonts.spaceGrotesk(
                      color: TwColors.onBg,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: ring,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$pct% compatível',
                        style: GoogleFonts.spaceGrotesk(
                          color: TwColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // State chip
            _StateChip(state: chat.humanizeState),
          ],
        ),
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  final String state;
  const _StateChip({required this.state});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      'humanized' => ('Humano', TwColors.success),
      'humanize_pending' => ('Aguardando', TwColors.warning),
      _ => ('Simulado', TwColors.muted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(TwRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
