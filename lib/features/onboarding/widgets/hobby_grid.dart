import 'package:flutter/material.dart';

const kAllHobbies = [
  ('Musica', Icons.music_note, Color(0xFFE91E63)),
  ('Filmes', Icons.movie, Color(0xFF9C27B0)),
  ('Esportes', Icons.sports_soccer, Color(0xFF4CAF50)),
  ('Culinaria', Icons.restaurant, Color(0xFFFF9800)),
  ('Games', Icons.sports_esports, Color(0xFF2196F3)),
  ('Leitura', Icons.book, Color(0xFF795548)),
  ('Viagens', Icons.flight, Color(0xFF00BCD4)),
  ('Arte', Icons.palette, Color(0xFFFF5722)),
  ('Fotografia', Icons.camera_alt, Color(0xFF607D8B)),
  ('Tecnologia', Icons.computer, Color(0xFF3F51B5)),
  ('Natureza', Icons.nature, Color(0xFF8BC34A)),
  ('Danca', Icons.music_video, Color(0xFFE040FB)),
];

class HobbyGrid extends StatefulWidget {
  final List<String> selected;
  final void Function(List<String>) onChanged;

  const HobbyGrid({super.key, required this.selected, required this.onChanged});

  @override
  State<HobbyGrid> createState() => _HobbyGridState();
}

class _HobbyGridState extends State<HobbyGrid> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selected);
  }

  void _toggle(String hobby) {
    setState(() {
      if (_selected.contains(hobby)) {
        _selected.remove(hobby);
      } else if (_selected.length < 10) {
        _selected.add(hobby);
      }
    });
    widget.onChanged(_selected);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: kAllHobbies.map((hobby) {
        final name = hobby.$1;
        final icon = hobby.$2;
        final color = hobby.$3;
        final isSelected = _selected.contains(name);
        return GestureDetector(
          onTap: () => _toggle(name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? color.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 18,
                    color: isSelected
                        ? color
                        : Colors.white.withValues(alpha: 0.35)),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? Colors.white : Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
