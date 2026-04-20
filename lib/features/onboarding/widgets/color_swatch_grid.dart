import 'package:flutter/material.dart';
import 'package:tinyworld_app/core/theme/styles.dart';

class ColorSwatchGrid extends StatelessWidget {
  final List<String> colors; // hex without #
  final String selected;
  final ValueChanged<String> onChanged;

  const ColorSwatchGrid({
    super.key,
    required this.colors,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: colors.map((hex) {
        final color = Color(int.parse('FF$hex', radix: 16));
        final isSelected = selected == hex;
        final isLight = color.computeLuminance() > 0.5;
        return GestureDetector(
          onTap: () => onChanged(hex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? TwColors.primary : (isLight ? TwColors.border : Colors.transparent),
                width: isSelected ? 2.5 : 1.5,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: TwColors.primary.withValues(alpha: 0.4), blurRadius: 8)]
                  : null,
            ),
            child: isSelected
                ? Icon(Icons.check, size: 16, color: isLight ? Colors.black : Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
