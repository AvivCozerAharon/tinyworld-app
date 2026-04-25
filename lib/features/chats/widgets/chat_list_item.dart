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

  String _timeAgo(String ts) {
    if (ts.isEmpty) return '';
    try {
      final dt = DateTime.parse(ts);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays > 30) return '${diff.inDays ~/ 30}m';
      if (diff.inDays > 0) return '${diff.inDays}d';
      if (diff.inHours > 0) return '${diff.inHours}h';
      if (diff.inMinutes > 0) return '${diff.inMinutes}min';
      return 'agora';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final compat = chat.compatibility;
    final ring = _ringColor(compat);
    final timeAgo = _timeAgo(chat.ts);
    final preview = chat.lastMessage;
    final isHumanized = chat.humanizeState == 'humanized';
    final displayName = isHumanized && chat.otherName.isNotEmpty
        ? chat.otherName
        : '???';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TwColors.card,
          borderRadius: BorderRadius.circular(TwRadius.xl),
          border: Border.all(color: TwColors.border),
        ),
        child: Row(
          children: [
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          style: GoogleFonts.spaceGrotesk(
                            color: TwColors.onBg,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (timeAgo.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          timeAgo,
                          style: GoogleFonts.spaceGrotesk(
                            color: TwColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (preview.isNotEmpty)
                    Text(
                      preview,
                      style: GoogleFonts.spaceGrotesk(
                        color: TwColors.onSurface,
                        fontSize: 13,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
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
                          '${(compat * 100).toInt()}% compatível',
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
            const SizedBox(width: 8),
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
      'humanize_pending_sent' => ('Aguardando', TwColors.warning),
      'humanize_pending_received' => ('Conectar', TwColors.primary),
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
