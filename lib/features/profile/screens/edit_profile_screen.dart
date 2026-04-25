import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tinyworld_app/core/api/rest_client.dart';
import 'package:tinyworld_app/core/theme/styles.dart';
import 'package:tinyworld_app/features/profile/profile_controller.dart';

const _suggestedHobbies = [
  'Fotografia', 'Games', 'Musica', 'Cozinhar', 'Viajar', 'Esportes',
  'Leitura', 'Cinema', 'Danca', 'Desenho', 'Tecnologia', 'Natureza',
  'Yoga', 'Cafe', 'Animes', 'Podcasts', 'Arte', 'Escrita',
  'Surf', 'Corrida', 'Pet', 'Astrologia', 'Moda', 'Series',
];

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameCtrl;
  final Set<String> _selectedHobbies = {};
  final Set<String> _suggested = Set.from(_suggestedHobbies);
  bool _isSaving = false;
  final _newHobbyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileControllerProvider).profile;
    _nameCtrl = TextEditingController(text: profile?.name ?? '');
    _selectedHobbies.addAll(profile?.hobbies ?? []);
    for (final h in _selectedHobbies) {
      _suggested.remove(h);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _newHobbyCtrl.dispose();
    super.dispose();
  }

  void _addHobby(String hobby) {
    if (hobby.trim().isEmpty || _selectedHobbies.length >= 10) return;
    setState(() {
      _selectedHobbies.add(hobby.trim());
      _suggested.remove(hobby.trim());
      _newHobbyCtrl.clear();
    });
  }

  void _removeHobby(String hobby) {
    setState(() {
      _selectedHobbies.remove(hobby);
      _suggested.add(hobby);
    });
  }

  Future<void> _save() async {
    if (_selectedHobbies.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos 3 hobbies')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await apiClient.put('/profile/me', data: {
        'name': _nameCtrl.text.trim(),
        'hobbies': _selectedHobbies.toList(),
      });
      await ref.read(profileControllerProvider.notifier).loadProfile();
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TwColors.bg,
      appBar: AppBar(
        backgroundColor: TwColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: TwColors.onBg),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Configuracoes',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: TwColors.onBg)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: TwColors.primary))
                  : Text('Salvar',
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: TwColors.primary,
                      )),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          const SizedBox(height: 8),
          Text('Nome',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: TwColors.muted)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            style: GoogleFonts.spaceGrotesk(
                fontSize: 16, color: TwColors.onBg),
            decoration: InputDecoration(
              hintText: 'Seu nome',
              filled: true,
              fillColor: TwColors.card,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TwRadius.md),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TwRadius.md),
                  borderSide: const BorderSide(
                      color: TwColors.border, width: 1)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TwRadius.md),
                  borderSide: const BorderSide(
                      color: TwColors.primary, width: 1.5)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Text('Hobbies',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: TwColors.muted)),
              const Spacer(),
              Text('${_selectedHobbies.length}/10',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 12, color: TwColors.muted)),
            ],
          ),
          const SizedBox(height: 12),
          if (_selectedHobbies.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedHobbies
                  .map((h) => _buildChip(h, selected: true))
                  .toList(),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _newHobbyCtrl,
            style: GoogleFonts.spaceGrotesk(
                fontSize: 14, color: TwColors.onBg),
            decoration: InputDecoration(
              hintText: 'Adicionar hobby...',
              hintStyle: GoogleFonts.spaceGrotesk(
                  color: TwColors.muted, fontSize: 14),
              filled: true,
              fillColor: TwColors.card,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TwRadius.md),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TwRadius.md),
                  borderSide: const BorderSide(
                      color: TwColors.border, width: 1)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TwRadius.md),
                  borderSide: const BorderSide(
                      color: TwColors.primary, width: 1.5)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: IconButton(
                icon: const Icon(Icons.add_circle_outline,
                    color: TwColors.primary),
                onPressed: () => _addHobby(_newHobbyCtrl.text),
              ),
            ),
            onSubmitted: (v) => _addHobby(v),
          ),
          if (_suggested.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Sugestoes',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: TwColors.muted)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _suggested
                  .take(12)
                  .map((h) => _buildChip(h, selected: false))
                  .toList(),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildChip(String label, {required bool selected}) {
    return GestureDetector(
      onTap: () => selected ? _removeHobby(label) : _addHobby(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? TwColors.primary.withValues(alpha: 0.15)
              : TwColors.card,
          borderRadius: BorderRadius.circular(TwRadius.pill),
          border: selected
              ? Border.all(
                  color: TwColors.primary.withValues(alpha: 0.4), width: 1.5)
              : Border.all(color: TwColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? TwColors.primary : TwColors.onSurface,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.close, size: 14, color: TwColors.primary),
            ],
          ],
        ),
      ),
    );
  }
}
