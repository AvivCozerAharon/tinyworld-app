import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tinyworld_app/core/theme/styles.dart';
import 'package:tinyworld_app/shared/widgets/onboarding_scaffold.dart';

class GenderScreen extends StatelessWidget {
  final String name;
  const GenderScreen({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 2,
      totalSteps: 9,
      title: 'Qual é o seu gênero?',
      subtitle: 'Isso nos ajuda a personalizar sua experiência.',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            _GenderCard(
              icon: Icons.male,
              label: 'Masculino',
              value: 'male',
              name: name,
              color: const Color(0xFF5B8EFF),
            ),
            const SizedBox(height: 12),
            _GenderCard(
              icon: Icons.female,
              label: 'Feminino',
              value: 'female',
              name: name,
              color: TwColors.secondary,
            ),
            const SizedBox(height: 12),
            _GenderCard(
              icon: Icons.transgender,
              label: 'Não-binário',
              value: 'non_binary',
              name: name,
              color: TwColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String name;
  final Color color;
  const _GenderCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.name,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/onboarding/birthdate', extra: {
        'name': name,
        'gender': value,
      }),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: TwColors.card,
          borderRadius: BorderRadius.circular(TwRadius.lg),
          border: Border.all(color: TwColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: TwColors.onBg,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: TwColors.muted),
          ],
        ),
      ),
    );
  }
}
