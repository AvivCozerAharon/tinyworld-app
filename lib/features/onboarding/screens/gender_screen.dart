import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      onBack: () => context.go('/onboarding/basic-info'),
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
            ),
            const SizedBox(height: 12),
            _GenderCard(
              icon: Icons.female,
              label: 'Feminino',
              value: 'female',
              name: name,
            ),
            const SizedBox(height: 12),
            _GenderCard(
              icon: Icons.balance,
              label: 'Não-binário',
              value: 'non_binary',
              name: name,
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
  const _GenderCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/onboarding/birthdate', extra: {
        'name': name,
        'gender': value,
      }),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1B76F2).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF1B76F2), size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Color(0xFFC4C9D0)),
          ],
        ),
      ),
    );
  }
}
