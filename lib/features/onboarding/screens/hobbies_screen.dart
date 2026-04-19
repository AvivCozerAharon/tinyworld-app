import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tinyworld_app/core/theme/styles.dart';
import 'package:tinyworld_app/features/onboarding/onboarding_controller.dart';
import 'package:tinyworld_app/features/onboarding/widgets/hobby_grid.dart';
import 'package:tinyworld_app/shared/widgets/onboarding_scaffold.dart';

class HobbiesScreen extends ConsumerStatefulWidget {
  const HobbiesScreen({super.key});
  @override
  ConsumerState<HobbiesScreen> createState() => _HobbiesScreenState();
}

class _HobbiesScreenState extends ConsumerState<HobbiesScreen> {
  List<String> _selected = [];

  Future<void> _submit() async {
    if (_selected.length < 3) return;
    final ok = await ref
        .read(onboardingControllerProvider.notifier)
        .saveHobbies(_selected);
    if (ok && mounted) context.push('/onboarding/chat');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final count = _selected.length;

    return OnboardingScaffold(
      step: 7,
      totalSteps: 9,
      title: 'Seus interesses',
      subtitle: 'Escolha pelo menos 3 hobbies para personalizar suas conexões.',
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  '$count selecionado${count != 1 ? 's' : ''}',
                  style: GoogleFonts.spaceGrotesk(
                    color: count >= 3 ? TwColors.primary : TwColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (count >= 3)
                  const Icon(Icons.check_circle,
                      size: 18, color: TwColors.primary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OnboardingButton(
            onPressed: count >= 3 ? _submit : null,
            isLoading: state.isLoading,
            child: const Text('Continuar'),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
        child: HobbyGrid(
          selected: _selected,
          onChanged: (v) => setState(() => _selected = v),
        ),
      ),
    );
  }
}
