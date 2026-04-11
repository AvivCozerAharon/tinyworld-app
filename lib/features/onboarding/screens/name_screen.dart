import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tinyworld_app/shared/widgets/onboarding_scaffold.dart';

class NameScreen extends StatefulWidget {
  const NameScreen({super.key});
  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final valid = _ctrl.text.trim().isNotEmpty;
    return OnboardingScaffold(
      step: 1,
      totalSteps: 9,
      title: 'Como quer ser chamado?',
      subtitle: 'Seu nome será visível para seus matches.',
      showBack: false,
      bottom: OnboardingButton(
        onPressed: valid
            ? () => context.go('/onboarding/gender', extra: _ctrl.text.trim())
            : null,
        child: const Text('Continuar'),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: OnboardingInput(
          controller: _ctrl,
          label: 'SEU NOME',
          hint: 'Digite seu nome...',
          focusNode: _focus,
          onSubmitted: (_) {
            if (_ctrl.text.trim().isNotEmpty) {
              context.go('/onboarding/gender', extra: _ctrl.text.trim());
            }
          },
        ),
      ),
    );
  }
}
