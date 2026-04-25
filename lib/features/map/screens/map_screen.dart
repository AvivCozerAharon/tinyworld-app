import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tinyworld_app/features/map/game/tiny_world_game.dart';
import 'package:tinyworld_app/features/map/map_controller.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});
  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  late final TinyWorldGame _game;

  @override
  void initState() {
    super.initState();
    _game = TinyWorldGame();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mapControllerProvider.notifier).startSearch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mapControllerProvider);

    ref.listen(mapControllerProvider, (_, next) => _game.updateState(next));

    final active = state.activeSimulations;
    final completed = active.where((s) => s.status == SimulationStatus.completed).toList();
    final chatting = active.where((s) => s.status == SimulationStatus.chatting).toList();

    return Scaffold(
      body: Stack(
        children: [
          GameWidget(game: _game),
          Positioned(
            top: 48,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () =>
                    ref.read(mapControllerProvider.notifier).stopSearch(),
                icon: const Icon(Icons.stop, color: Color(0xFF1B76F2)),
                tooltip: 'Parar busca',
              ),
            ),
          ),
          if (state.isSearching)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B76F2),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1B76F2).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        chatting.isNotEmpty
                            ? '${chatting.length} conversando...'
                            : 'Procurando amizades...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (state.searchDone && completed.isEmpty && active.isEmpty)
            Positioned.fill(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.explore_off, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma conexão encontrada',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tente novamente mais tarde. Novas pessoas podem aparecer em breve!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () =>
                            ref.read(mapControllerProvider.notifier).startSearch(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Buscar novamente'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (completed.isNotEmpty)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: completed.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final sim = completed[i];
                    final compat = sim.compatibility ?? 0;
                    final pct = (compat * 100).toInt();
                    return GestureDetector(
                      onTap: () => context.go('/chats/${sim.jobId}'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: compat > 0.6 ? const Color(0xFFEF5350) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble,
                              size: 18,
                              color: compat > 0.6 ? Colors.white : const Color(0xFF757575),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$pct%',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: compat > 0.6 ? Colors.white : const Color(0xFF757575),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
