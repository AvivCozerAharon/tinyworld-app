import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tinyworld_app/core/api/rest_client.dart';
import 'package:tinyworld_app/core/theme/styles.dart';
import 'package:tinyworld_app/features/chats/chats_controller.dart';
import 'package:tinyworld_app/features/chats/widgets/chat_list_item.dart';
import 'package:tinyworld_app/shared/widgets/app_animations.dart';

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
      appBar: AppBar(
        title: Text(
          'Conexões',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            color: TwColors.onBg,
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: TwGradients.accent,
          borderRadius: BorderRadius.circular(TwRadius.pill),
          boxShadow: [
            BoxShadow(
              color: TwColors.primary.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _showSimulateDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.bolt, color: Colors.white),
          label: Text(
            'Simular',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: TwColors.primary))
          : state.chats.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: TwColors.card,
                          shape: BoxShape.circle,
                          border: Border.all(color: TwColors.border),
                        ),
                        child: const Icon(Icons.chat_bubble_outline,
                            size: 36, color: TwColors.muted),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Nenhuma simulação ainda',
                        style: GoogleFonts.spaceGrotesk(
                          color: TwColors.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Use o mapa para encontrar conexões!',
                        style: GoogleFonts.spaceGrotesk(
                          color: TwColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: TwColors.primary,
                  backgroundColor: TwColors.card,
                  onRefresh: () =>
                      ref.read(chatsControllerProvider.notifier).loadChats(),
                  child: StaggeredListView(
                    itemCount: state.chats.length,
                    itemBuilder: (_, i) => ChatListItem(
                      chat: state.chats[i],
                      onTap: () =>
                          context.go('/chats/${state.chats[i].simId}'),
                    ),
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
      backgroundColor: TwColors.surface,
      title: Text(
        'Simular com quem?',
        style: GoogleFonts.spaceGrotesk(
          color: TwColors.onBg,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SizedBox(
        width: 300,
        child: ready.isEmpty
            ? Text('Nenhum usuário disponível.',
                style: GoogleFonts.spaceGrotesk(color: TwColors.muted))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: ready.length,
                itemBuilder: (_, i) {
                  final u = ready[i];
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: TwColors.card,
                      child: Icon(Icons.person, color: TwColors.muted),
                    ),
                    title: Text(u['name'] as String,
                        style: GoogleFonts.spaceGrotesk(
                            color: TwColors.onBg, fontWeight: FontWeight.w600)),
                    subtitle: Text(u['birth_date'] as String? ?? '',
                        style: GoogleFonts.spaceGrotesk(
                            color: TwColors.muted, fontSize: 12)),
                    onTap: () =>
                        Navigator.of(context).pop(u['user_id'] as String),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar',
              style: GoogleFonts.spaceGrotesk(color: TwColors.muted)),
        ),
      ],
    );
  }
}
