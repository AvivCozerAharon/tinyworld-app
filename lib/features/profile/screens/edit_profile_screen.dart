import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tinyworld_app/core/api/rest_client.dart';
import 'package:tinyworld_app/features/profile/profile_controller.dart';

const _suggestedHobbies = [
  'Fotografia', 'Games', 'Música', 'Cozinhar', 'Viajar', 'Esportes',
  'Leitura', 'Cinema', 'Dança', 'Desenho', 'Tecnologia', 'Natureza',
  'Yoga', 'Café', 'Animes', 'Podcasts', 'Arte', 'Escrita',
  'Surf', 'Corrida', 'Pet', 'Astrologia', 'Moda', 'Séries',
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
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Salvar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          const SizedBox(height: 8),
          const Text(
            'Nome',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A2E)),
            decoration: InputDecoration(
              hintText: 'Seu nome',
              filled: true,
              fillColor: const Color(0xFFF5F7FA),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              const Text(
                'Hobbies',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
              ),
              const Spacer(),
              Text(
                '${_selectedHobbies.length}/10',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_selectedHobbies.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedHobbies.map((h) => _buildChip(h, selected: true)).toList(),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _newHobbyCtrl,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
            decoration: InputDecoration(
              hintText: 'Adicionar hobby...',
              hintStyle: const TextStyle(color: Color(0xFFC4C9D0)),
              filled: true,
              fillColor: const Color(0xFFF5F7FA),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Color(0xFF1B76F2)),
                onPressed: () => _addHobby(_newHobbyCtrl.text),
              ),
            ),
            onSubmitted: (v) => _addHobby(v),
          ),
          if (_suggested.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Sugestões',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _suggested.take(12).map((h) => _buildChip(h, selected: false)).toList(),
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
          color: selected ? const Color(0xFF1B76F2) : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(20),
          border: selected ? null : Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.close, size: 14, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }
}
