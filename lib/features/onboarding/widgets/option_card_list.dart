import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tinyworld_app/core/theme/styles.dart';

class AvatarOption {
  final String value;
  final String label;
  const AvatarOption(this.value, this.label);
}

class OptionCardList extends StatelessWidget {
  final List<AvatarOption> options;
  final String selected;
  final ValueChanged<String> onChanged;

  const OptionCardList({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final opt = options[i];
          final isSelected = selected == opt.value;
          return GestureDetector(
            onTap: () => onChanged(opt.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 80,
              decoration: BoxDecoration(
                gradient: isSelected ? TwGradients.card : null,
                color: isSelected ? null : TwColors.card,
                borderRadius: BorderRadius.circular(TwRadius.md),
                border: Border.all(
                  color: isSelected ? TwColors.primary : TwColors.border,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: TwColors.primary.withValues(alpha: 0.25), blurRadius: 12)]
                    : null,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    opt.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? TwColors.primary : TwColors.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
