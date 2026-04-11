import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinyworld_app/features/chats/chats_controller.dart';

class HumanizeButton extends ConsumerWidget {
  final String simId;
  final String currentState;

  const HumanizeButton(
      {super.key, required this.simId, required this.currentState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (currentState) {
      'humanized' => const SizedBox.shrink(),
      'humanize_pending_sent' => const FilledButton.tonal(
          onPressed: null,
          child: Text('Aguardando resposta...'),
        ),
      'humanize_pending_received' => FilledButton(
          onPressed: () async {
            final ok = await ref
                .read(chatsControllerProvider.notifier)
                .acceptHumanize(simId);
            if (ok && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Conexão aceita!')),
              );
            }
          },
          child: const Text('Aceitar conexão'),
        ),
      _ => FilledButton.icon(
          onPressed: () async {
            final ok = await ref
                .read(chatsControllerProvider.notifier)
                .requestHumanize(simId);
            if (ok && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Solicitação enviada!')),
              );
            }
          },
          icon: const Icon(Icons.people),
          label: const Text('Humanizar'),
        ),
    };
  }
}
