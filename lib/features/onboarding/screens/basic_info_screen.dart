import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tinyworld_app/features/onboarding/onboarding_controller.dart';
import 'package:tinyworld_app/shared/widgets/onboarding_scaffold.dart';

class BasicInfoScreen extends ConsumerStatefulWidget {
  const BasicInfoScreen({super.key});
  @override
  ConsumerState<BasicInfoScreen> createState() => _BasicInfoScreenState();
}

class _BasicInfoScreenState extends ConsumerState<BasicInfoScreen> {
  final _nameCtrl = TextEditingController();
  DateTime? _birthDate;
  String _orientation = 'bi';
  final _focusNode = FocusNode();

  final _orientations = [
    ('Heterossexual', 'hetero'),
    ('Gay', 'gay'),
    ('Lésbica', 'lesbian'),
    ('Bissexual', 'bi'),
    ('Pansexual', 'pan'),
    ('Assexual', 'asexual'),
    ('Outro', 'other'),
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
    );
    if (d != null) setState(() => _birthDate = d);
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty || _birthDate == null) return;
    final ok = await ref.read(onboardingControllerProvider.notifier).register(
          name: _nameCtrl.text.trim(),
          birthDate: _birthDate!.toIso8601String().split('T').first,
          sexualOrientation: _orientation,
        );
    if (ok && mounted) context.go('/onboarding/liveness');
  }

  bool get _isValid => _nameCtrl.text.trim().isNotEmpty && _birthDate != null;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    return OnboardingScaffold(
      step: 1,
      title: 'Quem é você?',
      subtitle: 'Precisamos saber um pouco sobre você para começar.',
      bottom: OnboardingButton(
        onPressed: _isValid ? _submit : null,
        isLoading: state.isLoading,
        child: const Text('Continuar'),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 8),
            OnboardingInput(
              controller: _nameCtrl,
              label: 'SEU NOME',
              hint: 'Como quer ser chamado?',
              focusNode: _focusNode,
              onSubmitted: (_) => _pickDate(),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _birthDate != null
                        ? const Color(0xFF1B76F2).withValues(alpha: 0.3)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DATA DE NASCIMENTO',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _birthDate == null
                                ? 'Selecionar data'
                                : '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}',
                            style: TextStyle(
                              color: _birthDate != null
                                  ? const Color(0xFF1A1A2E)
                                  : const Color(0xFFC4C9D0),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.calendar_today,
                        size: 20,
                        color: _birthDate != null
                            ? const Color(0xFF1B76F2)
                            : const Color(0xFFC4C9D0)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'ORIENTAÇÃO SEXUAL',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 10),
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
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF6B7280),
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
