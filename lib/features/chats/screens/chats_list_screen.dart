import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tinyworld_app/core/api/rest_client.dart';
import 'package:tinyworld_app/core/theme/styles.dart';
import 'package:tinyworld_app/features/chats/chats_controller.dart';
import 'package:tinyworld_app/features/chats/widgets/chat_list_item.dart';
import 'package:tinyworld_app/shared/widgets/app_animations.dart';

enum _ChatFilter { todos, simulado, humano }

class ChatsListScreen extends ConsumerStatefulWidget {
  const ChatsListScreen({super.key});
  @override
  ConsumerState<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends ConsumerState<ChatsListScreen> {
  _ChatFilter _filter = _ChatFilter.todos;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatsControllerProvider.notifier).loadChats();
    });
  }

  Future<void> _showSimulateDialog() async {
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

  List<ChatItem> _filtered(List<ChatItem> chats) {
    return switch (_filter) {
      _ChatFilter.simulado =>
        chats.where((c) => c.humanizeState == 'simulated').toList(),
      _ChatFilter.humano =>
        chats.where((c) => c.humanizeState == 'humanized').toList(),
      _ => chats,
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatsControllerProvider);
    final visible = _filtered(state.chats);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Conexões',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            color: TwColors.onBg,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: _FilterTabs(
            current: _filter,
            onChanged: (f) => setState(() => _filter = f),
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
          : visible.isEmpty
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
                    itemCount: visible.length,
                    itemBuilder: (_, i) {
                      final chat = visible[i];
                      return Dismissible(
                        key: Key(chat.simId),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: TwColors.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(TwRadius.xl),
                            border: Border.all(
                                color: TwColors.error.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(Icons.delete_outline,
                              color: TwColors.error),
                        ),
                        confirmDismiss: (_) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: TwColors.surface,
                              title: Text('Remover conversa?',
                                  style: GoogleFonts.spaceGrotesk(
                                      color: TwColors.onBg,
                                      fontWeight: FontWeight.w700)),
                              content: Text(
                                  'Isso vai remover da sua lista. A simulação continua salva.',
                                  style: GoogleFonts.spaceGrotesk(
                                      color: TwColors.muted)),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(ctx).pop(false),
                                  child: Text('Cancelar',
                                      style: GoogleFonts.spaceGrotesk(
                                          color: TwColors.muted)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: Text('Remover',
                                      style: GoogleFonts.spaceGrotesk(
                                          color: TwColors.error,
                                          fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          ) ??
                              false;
                        },
                        onDismissed: (_) {
                          ref
                              .read(chatsControllerProvider.notifier)
                              .deleteChat(chat.simId);
                        },
                        child: ChatListItem(
                          chat: chat,
                          onTap: () => context.go('/chats/${chat.simId}'),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  final _ChatFilter current;
  final ValueChanged<_ChatFilter> onChanged;

  const _FilterTabs({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
      child: Row(
        children: [
          _Tab(label: 'Todos', active: current == _ChatFilter.todos,
              onTap: () => onChanged(_ChatFilter.todos)),
          const SizedBox(width: 8),
          _Tab(label: 'Simulado', active: current == _ChatFilter.simulado,
              onTap: () => onChanged(_ChatFilter.simulado)),
          const SizedBox(width: 8),
          _Tab(label: 'Humano', active: current == _ChatFilter.humano,
              onTap: () => onChanged(_ChatFilter.humano)),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Tab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? TwColors.primary.withValues(alpha: 0.15)
              : TwColors.card,
          borderRadius: BorderRadius.circular(TwRadius.pill),
          border: Border.all(
            color: active
                ? TwColors.primary.withValues(alpha: 0.4)
                : TwColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? TwColors.primary : TwColors.muted,
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
