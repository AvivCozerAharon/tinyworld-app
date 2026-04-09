import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    if (ok && mounted) context.go('/onboarding/chat');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final count = _selected.length;

    return OnboardingScaffold(
      step: 4,
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
                  style: TextStyle(
                    color: count >= 3
                        ? const Color(0xFF6C63FF)
                        : Colors.white38,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (count >= 3)
                  Icon(Icons.check_circle,
                      size: 18, color: const Color(0xFF6C63FF).withOpacity(0.7)),
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
