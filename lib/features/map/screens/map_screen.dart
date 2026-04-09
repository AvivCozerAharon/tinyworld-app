import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tinyworld_app/features/map/map_controller.dart';
import 'package:tinyworld_app/features/map/widgets/map_canvas.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});
  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with TickerProviderStateMixin {
  late AnimationController _walkCtrl;
  late Animation<double> _walkAnim;

  @override
  void initState() {
    super.initState();
    _walkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat();
    _walkAnim = CurvedAnimation(parent: _walkCtrl, curve: Curves.easeInOut);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mapControllerProvider.notifier).startSearch();
    });
  }

  @override
  void dispose() {
    _walkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mapControllerProvider);
    final active = state.activeSimulations;
    final completed =
        active.where((s) => s.status == SimulationStatus.completed).toList();
    final chatting =
        active.where((s) => s.status == SimulationStatus.chatting).toList();

    return Scaffold(
      body: Stack(
        children: [
          MapCanvas(
            simulations: active,
            walkAnimation: _walkAnim,
            onSimTap: (sim) {
              if (sim.status == SimulationStatus.completed) {
                context.go('/chats/${sim.jobId}');
              }
            },
          ),
          Positioned(
            top: 48,
            right: 16,
            child: IconButton.filled(
              onPressed: () =>
                  ref.read(mapControllerProvider.notifier).stopSearch(),
              icon: const Icon(Icons.stop),
              tooltip: 'Parar busca',
            ),
          ),
          if (state.isSearching)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: compat > 0.6
                              ? const Color(0xFFEF5350).withValues(alpha: 0.9)
                              : Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
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
                              color: compat > 0.6
                                  ? Colors.white
                                  : const Color(0xFF757575),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$pct%',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: compat > 0.6
                                    ? Colors.white
                                    : const Color(0xFF757575),
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
