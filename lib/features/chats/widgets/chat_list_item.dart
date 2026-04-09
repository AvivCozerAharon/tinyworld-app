import 'package:flutter/material.dart';
import 'package:tinyworld_app/features/chats/chats_controller.dart';
import 'package:tinyworld_app/features/onboarding/widgets/avatar_preview.dart';

class ChatListItem extends StatelessWidget {
  final ChatItem chat;
  final VoidCallback onTap;

  const ChatListItem({super.key, required this.chat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: chat.otherAvatar.isNotEmpty
          ? AvatarPreview(avatarUrl: chat.otherAvatar, size: 48)
          : const CircleAvatar(child: Icon(Icons.person)),
      title: const Text('???', style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle:
          Text('Compatibilidade: ${(chat.compatibility * 100).toStringAsFixed(0)}%'),
      trailing: _StateChip(state: chat.humanizeState),
      onTap: onTap,
    );
  }
}

class _StateChip extends StatelessWidget {
  final String state;
  const _StateChip({required this.state});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      'humanized' => ('Humanizado', Colors.green),
      'humanize_pending' => ('Aguardando', Colors.orange),
      _ => ('Simulado', Colors.grey),
    };
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 10)),
      backgroundColor: color.withValues(alpha: 0.2),
    );
  }
}
