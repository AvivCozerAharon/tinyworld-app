import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tinyworld_app/shared/widgets/onboarding_scaffold.dart';

class BirthDateScreen extends StatefulWidget {
  final String name;
  final String gender;
  const BirthDateScreen({super.key, required this.name, required this.gender});

  @override
  State<BirthDateScreen> createState() => _BirthDateScreenState();
}

class _BirthDateScreenState extends State<BirthDateScreen> {
  DateTime? _birthDate;

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
    );
    if (d != null) setState(() => _birthDate = d);
  }

  void _next() {
    if (_birthDate == null) return;
    context.go('/onboarding/orientation', extra: {
      'name': widget.name,
      'gender': widget.gender,
      'birth_date': _birthDate!.toIso8601String().split('T').first,
    });
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 3,
      totalSteps: 9,
      title: 'Quando você nasceu?',
      subtitle: 'Precisamos confirmar que você tem 18+.',
      onBack: () => context.go('/onboarding/gender', extra: widget.name),
      bottom: OnboardingButton(
        onPressed: _birthDate != null ? _next : null,
        child: const Text('Continuar'),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: GestureDetector(
          onTap: _pickDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.calendar_today,
                    size: 22,
                    color: _birthDate != null
                        ? const Color(0xFF1B76F2)
                        : const Color(0xFFC4C9D0)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
