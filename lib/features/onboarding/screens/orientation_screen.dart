import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tinyworld_app/core/theme/styles.dart';
import 'package:tinyworld_app/features/onboarding/onboarding_controller.dart';
import 'package:tinyworld_app/shared/widgets/onboarding_scaffold.dart';

class OrientationScreen extends ConsumerStatefulWidget {
  final String name;
  final String gender;
  final String birthDate;
  const OrientationScreen({
    super.key,
    required this.name,
    required this.gender,
    required this.birthDate,
  });

  @override
  ConsumerState<OrientationScreen> createState() => _OrientationScreenState();
}

class _OrientationScreenState extends ConsumerState<OrientationScreen> {
  String _orientation = 'bi';

  final _orientations = [
    ('Heterossexual', 'hetero'),
    ('Gay', 'gay'),
    ('Lésbica', 'lesbian'),
    ('Bissexual', 'bi'),
    ('Pansexual', 'pan'),
    ('Assexual', 'asexual'),
    ('Outro', 'other'),
  ];

  Future<void> _submit() async {
    final ok = await ref.read(onboardingControllerProvider.notifier).register(
          name: widget.name,
          birthDate: widget.birthDate,
          sexualOrientation: _orientation,
          gender: widget.gender,
        );
    if (ok && mounted) context.push('/onboarding/liveness');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    return OnboardingScaffold(
      step: 4,
      totalSteps: 9,
      title: 'Orientação sexual',
      subtitle: 'Usamos isso para encontrar melhores matches.',
      bottom: OnboardingButton(
        onPressed: _submit,
        isLoading: state.isLoading,
        child: const Text('Continuar'),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _orientations.map((o) {
                final isSelected = _orientation == o.$2;
                return GestureDetector(
                  onTap: () => setState(() => _orientation = o.$2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 11),
                    decoration: BoxDecoration(
                      gradient: isSelected ? TwGradients.primary : null,
                      color: isSelected ? null : TwColors.card,
                      borderRadius: BorderRadius.circular(TwRadius.pill),
                      border: Border.all(
                        color: isSelected ? TwColors.primary : TwColors.border,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: TwColors.primary.withValues(alpha: 0.25),
                                blurRadius: 10,
                              )
                            ]
                          : null,
                    ),
                    child: Text(
                      o.$1,
                      style: GoogleFonts.spaceGrotesk(
                        color: isSelected ? Colors.white : TwColors.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (state.error != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TwColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(TwRadius.md),
                  border: Border.all(
                      color: TwColors.error.withValues(alpha: 0.3)),
                ),
                child: Text(
                  state.error!,
                  style: GoogleFonts.spaceGrotesk(
                      color: TwColors.error, fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
