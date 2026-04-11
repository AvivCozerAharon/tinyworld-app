import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  'personalidade': Color(0xFF6C5CE7),
  'valores': Color(0xFFE17055),
  'sentimentos': Color(0xFFFD79A8),
  'sonhos': Color(0xFFFDCB6E),
  'rotina': Color(0xFF00CEC9),
  'relacionamento': Color(0xFFE84393),
  'gosto': Color(0xFF6C5CE7),
  'entretenimento': Color(0xFF0984E3),
  'lifestyle': Color(0xFF00B894),
  'social': Color(0xFF55EFC4),
  'digital': Color(0xFF636E72),
  'curiosidade': Color(0xFFFDCB6E),
  'diversao': Color(0xFFFF7675),
  'crescimento': Color(0xFF00B894),
  'passado': Color(0xFFA29BFE),
  'criatividade': Color(0xFFFD79A8),
  'preference': Color(0xFF1B76F2),
  'pattern': Color(0xFF6C5CE7),
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
  'diversao': 'Diversão',
  'crescimento': 'Crescimento',
  'passado': 'Passado',
  'criatividade': 'Criatividade',
  'preference': 'Preferência',
  'pattern': 'Padrão',
  'fact': 'Fato',
};

class BrainScreen extends ConsumerWidget {
  const BrainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(brainControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Cérebro'),
        actions: [
          if (state.total > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Chip(
                  avatar: const Icon(Icons.memory, size: 16),
                  label: Text('${state.total} memórias'),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.memories.isEmpty
              ? _buildEmpty(context)
              : _buildContent(state, ref),
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
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF1B76F2).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(Icons.psychology, size: 56, color: Color(0xFF1B76F2)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Seu cérebro está vazio!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 12),
            Text(
              'Vá em "Treinar meu agente" no perfil\npara alimentar seu cérebro com memórias.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14, height: 1.5),
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
      color: const Color(0xFF6C5CE7),
      onRefresh: () => ref.read(brainControllerProvider.notifier).loadMemories(),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          const SizedBox(height: 8),
          _buildSummaryCard(grouped),
          const SizedBox(height: 16),
          ...grouped.entries.map((e) => _buildCategorySection(e.key, e.value)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, List<MemoryItem>> grouped) {
    return Container(
      padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B76F2), Color(0xFF6C5CE7)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'O que seu agente sabe de você',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: grouped.entries.map((e) {
              final color = _categoryColors[e.key] ?? Colors.white;
              final label = _categoryLabels[e.key] ?? e.key;
              final icon = _categoryIcons[e.key] ?? Icons.circle_outlined;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text('$label (${e.value.length})',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
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
    final color = _categoryColors[category] ?? const Color(0xFF636E72);
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
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${items.length}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
                ),
              ),
            ],
          ),
        ),
        ...items.map((m) => _buildMemoryCard(m, color)),
      ],
    );
  }

  Widget _buildMemoryCard(MemoryItem memory, Color accentColor) {
    final text = memory.fact
        .replaceFirst(RegExp(r'^\[treino-agente\] Sobre '), '')
        .replaceFirst(RegExp(r"^Sobre '.*?':\s*"), '');

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
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
              style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
