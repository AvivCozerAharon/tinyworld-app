import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tinyworld_app/core/theme/styles.dart';

class SpeedButton extends StatelessWidget {
  final double speed;
  final VoidCallback onTap;

  const SpeedButton({super.key, required this.speed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = speed == 1.0 ? "1" : speed == 1.5 ? "1.5" : "2";
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: TwColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(TwRadius.pill),
          border: Border.all(color: TwColors.primary.withValues(alpha: 0.3)),
        ),
        child: Text(
          '$label×',
          style: GoogleFonts.spaceGrotesk(
            color: TwColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
