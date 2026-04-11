import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    if (ok && mounted) context.go('/onboarding/liveness');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    return OnboardingScaffold(
      step: 4,
      totalSteps: 9,
      title: 'Orientação sexual',
      subtitle: 'Usamos isso para encontrar melhores matches.',
      onBack: () => context.go('/onboarding/birthdate', extra: {
        'name': widget.name,
        'gender': widget.gender,
      }),
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
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1B76F2)
                          : const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1B76F2)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Text(
                      o.$1,
                      style: TextStyle(
                        color:
                            isSelected ? Colors.white : const Color(0xFF6B7280),
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
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
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  state.error!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
