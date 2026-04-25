import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tinyworld_app/core/theme/styles.dart';
import 'package:tinyworld_app/features/profile/profile_controller.dart';

const _categoryIcons = {
  'personalidade': Icons.person_outline,
  'valores': Icons.favorite_outline,
  'sentimentos': Icons.emoji_emotions_outlined,
  'sonhos': Icons.star_outline,
  'rotina': Icons.schedule,
  'relacionamento': Icons.people_outline,
  'gosto': Icons.palette_outlined,
  'entretenimento': Icons.movie_outlined,
  'lifestyle': Icons.fitness_center_outlined,
  'social': Icons.groups_outlined,
  'digital': Icons.devices_outlined,
  'curiosidade': Icons.lightbulb_outline,
  'diversao': Icons.celebration_outlined,
  'crescimento': Icons.trending_up_outlined,
  'passado': Icons.history,
  'criatividade': Icons.brush_outlined,
  'preference': Icons.tune_outlined,
  'pattern': Icons.pattern_outlined,
  'fact': Icons.info_outline,
};

const _categoryColors = {
  'personalidade': TwColors.primary,
  'valores': TwColors.secondary,
  'sentimentos': Color(0xFFFD79A8),
  'sonhos': Color(0xFFFDCB6E),
  'rotina': Color(0xFF00CEC9),
  'relacionamento': Color(0xFFE84393),
  'gosto': TwColors.primary,
  'entretenimento': Color(0xFF0984E3),
  'lifestyle': Color(0xFF00B894),
  'social': Color(0xFF55EFC4),
  'digital': Color(0xFF636E72),
  'curiosidade': Color(0xFFFDCB6E),
  'diversao': Color(0xFFFF7675),
  'crescimento': Color(0xFF00B894),
  'passado': Color(0xFFA29BFE),
  'criatividade': Color(0xFFFD79A8),
  'preference': TwColors.primary,
  'pattern': TwColors.primary,
  'fact': Color(0xFF636E72),
};

const _categoryLabels = {
  'personalidade': 'Personalidade',
  'valores': 'Valores',
  'sentimentos': 'Sentimentos',
  'sonhos': 'Sonhos',
  'rotina': 'Rotina',
  'relacionamento': 'Relacionamento',
  'gosto': 'Gostos',
  'entretenimento': 'Entretenimento',
  'lifestyle': 'Lifestyle',
  'social': 'Social',
  'digital': 'Digital',
  'curiosidade': 'Curiosidade',
  'diversao': 'Diversao',
  'crescimento': 'Crescimento',
  'passado': 'Passado',
  'criatividade': 'Criatividade',
  'preference': 'Preferencia',
  'pattern': 'Padrao',
  'fact': 'Fato',
};

class BrainScreen extends ConsumerStatefulWidget {
  const BrainScreen({super.key});

  @override
  ConsumerState<BrainScreen> createState() => _BrainScreenState();
}

class _BrainScreenState extends ConsumerState<BrainScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(brainControllerProvider.notifier).loadMemories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(brainControllerProvider);

    return Scaffold(
      backgroundColor: TwColors.bg,
      appBar: AppBar(
        backgroundColor: TwColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: TwColors.onBg),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: TwGradients.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text('T',
                    style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 8),
            Text('Meu Cerebro',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: TwColors.onBg)),
          ],
        ),
        actions: [
          if (state.total > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: TwColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(TwRadius.pill),
                    border: Border.all(
                        color: TwColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.memory,
                          size: 14, color: TwColors.primary),
                      const SizedBox(width: 4),
                      Text('${state.total}',
                          style: GoogleFonts.spaceGrotesk(
                            color: TwColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          )),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: state.isLoading && state.memories.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: TwColors.primary))
          : state.error != null && state.memories.isEmpty
              ? _buildError(context, ref, state.error!)
              : state.memories.isEmpty
                  ? _buildEmpty(context)
                  : _buildContent(state, ref),
    );
  }

  Widget _buildError(
      BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: TwColors.error),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar memorias',
              style: GoogleFonts.spaceGrotesk(
                color: TwColors.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                  color: TwColors.muted, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () =>
                  ref.read(brainControllerProvider.notifier).loadMemories(),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: TwColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(Icons.psychology,
                  size: 48, color: TwColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'Seu cerebro esta vazio!',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: TwColors.onBg,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Va em "Treinar meu agente" no perfil\npara alimentar seu cerebro com memorias.',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                  color: TwColors.muted, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Voltar ao perfil'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BrainState state, WidgetRef ref) {
    final grouped = <String, List<MemoryItem>>{};
    for (final m in state.memories) {
      grouped.putIfAbsent(m.category, () => []).add(m);
    }

    return RefreshIndicator(
      color: TwColors.primary,
      backgroundColor: TwColors.card,
      onRefresh: () => ref.read(brainControllerProvider.notifier).loadMemories(),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          const SizedBox(height: 8),
          _buildSummaryCard(grouped),
          const SizedBox(height: 16),
          ...grouped.entries
              .map((e) => _buildCategorySection(e.key, e.value)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, List<MemoryItem>> grouped) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: TwGradients.accentDiagonal,
        borderRadius: BorderRadius.circular(TwRadius.xl),
        boxShadow: [
          BoxShadow(
            color: TwColors.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'O que seu agente sabe de voce',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: grouped.entries.map((e) {
              final color = _categoryColors[e.key] ?? TwColors.onBg;
              final label = _categoryLabels[e.key] ?? e.key;
              final icon = _categoryIcons[e.key] ?? Icons.circle_outlined;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(TwRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text('$label (${e.value.length})',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(String category, List<MemoryItem> items) {
    final color = _categoryColors[category] ?? TwColors.muted;
    final label = _categoryLabels[category] ?? category;
    final icon = _categoryIcons[category] ?? Icons.circle_outlined;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: TwColors.onBg,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${items.length}',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 12, fontWeight: FontWeight.w700, color: color),
                ),
              ),
            ],
          ),
        ),
        ...items.asMap().entries.map((e) => _buildMemoryCard(e.value, color, e.key)),
      ],
    );
  }

  Widget _buildMemoryCard(MemoryItem memory, Color accentColor, int index) {
    final text = memory.fact
        .replaceFirst(RegExp(r'^\[treino-agente\] Sobre '), '')
        .replaceFirst(RegExp(r"^Sobre '.*?':\s*"), '');

    return TweenAnimationBuilder(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + index * 50),
      curve: Curves.easeOutCubic,
      builder: (ctx, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 8),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: TwColors.card,
          borderRadius: BorderRadius.circular(TwRadius.md),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 6),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  color: TwColors.onBg,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
