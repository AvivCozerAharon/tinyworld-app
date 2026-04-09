import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tinyworld_app/core/api/rest_client.dart';
import 'package:tinyworld_app/features/chats/chats_controller.dart';
import 'package:tinyworld_app/features/chats/widgets/chat_list_item.dart';

class ChatsListScreen extends ConsumerStatefulWidget {
  const ChatsListScreen({super.key});
  @override
  ConsumerState<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends ConsumerState<ChatsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatsControllerProvider.notifier).loadChats();
    });
  }

  Future<void> _showSimulateDialog() async {
    // Load users from debug endpoint
    List<Map<String, dynamic>> users = [];
    try {
      final resp = await apiClient.get('/debug/users');
      users = (resp.data as List).cast<Map<String, dynamic>>();
    } catch (_) {}

    if (!mounted) return;

    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => _UserPickerDialog(users: users),
    );

    if (selected != null && mounted) {
      context.go('/chats/live/$selected');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Conexões')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSimulateDialog,
        icon: const Icon(Icons.bolt),
        label: const Text('Simular'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.chats.isEmpty
              ? const Center(
                  child: Text('Nenhuma simulação ainda. Use o botão abaixo!'))
              : ListView.separated(
                  itemCount: state.chats.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) => ChatListItem(
                    chat: state.chats[i],
                    onTap: () =>
                        context.go('/chats/${state.chats[i].simId}'),
                  ),
                ),
    );
  }
}

class _UserPickerDialog extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  const _UserPickerDialog({required this.users});

  @override
  Widget build(BuildContext context) {
    final ready = users
        .where((u) =>
            u['onboarding_completed'] == true && u['verified'] == true)
        .toList();

    return AlertDialog(
      title: const Text('Simular com quem?'),
      content: SizedBox(
        width: 300,
        child: ready.isEmpty
            ? const Text('Nenhum usuário disponível.')
            : ListView.builder(
                shrinkWrap: true,
                itemCount: ready.length,
                itemBuilder: (_, i) {
                  final u = ready[i];
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(u['name'] as String),
                    subtitle: Text(u['birth_date'] as String? ?? ''),
                    onTap: () =>
                        Navigator.of(context).pop(u['user_id'] as String),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
