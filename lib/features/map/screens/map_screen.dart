import 'dart:ui';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tinyworld_app/core/theme/styles.dart';
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

    final completed = state.activeSimulations
        .where((s) => s.status == SimulationStatus.completed)
        .toList();
    final chatting = state.activeSimulations
        .where((s) => s.status == SimulationStatus.chatting)
        .toList();

    return Scaffold(
      body: Stack(
        children: [
          GameWidget(game: _game),

          // Top HUD
          if (state.isSearching)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 0,
              right: 0,
              child: Center(child: _StatusPill(chatting: chatting, onStop: () {
                ref.read(mapControllerProvider.notifier).stopSearch();
              })),
            ),

          // Bottom match cards
          if (completed.isNotEmpty)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 0,
              right: 0,
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: completed.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => _MatchCard(
                  sim: completed[i],
                  onTap: () => context.go('/chats/${completed[i].jobId}'),
                ),
              ),
            ),

          // Empty state
          if (state.searchDone && completed.isEmpty && state.activeSimulations.isEmpty)
            Positioned.fill(
              child: Center(
                child: _EmptyState(
                  onRetry: () =>
                      ref.read(mapControllerProvider.notifier).startSearch(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final List<SimulationEntry> chatting;
  final VoidCallback onStop;

  const _StatusPill({required this.chatting, required this.onStop});

  @override
  Widget build(BuildContext context) {
    final label = chatting.isNotEmpty
        ? '${chatting.length} conversando...'
        : 'Procurando amizades...';

    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.only(left: 16, right: 8, top: 10, bottom: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onStop,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final SimulationEntry sim;
  final VoidCallback onTap;

  const _MatchCard({required this.sim, required this.onTap});

  Color get _compatColor {
    final c = sim.compatibility ?? 0;
    if (c >= 0.70) return const Color(0xFFE84E4E);
    if (c >= 0.45) return const Color(0xFFF59E0B);
    return TwColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final compat = sim.compatibility ?? 0;
    final pct = (compat * 100).round();
    final initial = sim.otherUserId.isNotEmpty
        ? sim.otherUserId[0].toUpperCase()
        : '?';

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 110,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _compatColor.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _compatColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: _compatColor, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: GoogleFonts.spaceGrotesk(
                        color: _compatColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$pct%',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'compatível',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRetry;

  const _EmptyState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.explore_off_rounded,
                  size: 44,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 14),
                Text(
                  'Nenhuma conexão encontrada',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Novas pessoas podem aparecer em breve!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: onRetry,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: TwGradients.primary,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      'Buscar novamente',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
