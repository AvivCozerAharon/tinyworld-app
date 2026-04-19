import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tinyworld_app/core/theme/styles.dart';
import 'package:tinyworld_app/shared/widgets/onboarding_scaffold.dart';

class BirthDateScreen extends StatefulWidget {
  final String name;
  final String gender;
  const BirthDateScreen({super.key, required this.name, required this.gender});

  @override
  State<BirthDateScreen> createState() => _BirthDateScreenState();
}

class _BirthDateScreenState extends State<BirthDateScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() {}));
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  DateTime? get _parsedDate {
    final text = _ctrl.text;
    if (text.length < 10) return null;
    final parts = text.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    if (day < 1 || day > 31 || month < 1 || month > 12 || year < 1900) return null;
    try {
      final d = DateTime(year, month, day);
      if (d.day != day || d.month != month) return null;
      return d;
    } catch (_) {
      return null;
    }
  }

  bool get _isValid {
    final d = _parsedDate;
    if (d == null) return false;
    final cutoff = DateTime(d.year + 18, d.month, d.day);
    return !cutoff.isAfter(DateTime.now());
  }

  void _next() {
    final d = _parsedDate;
    if (d == null) {
      setState(() => _error = 'Data inválida.');
      return;
    }
    final cutoff = DateTime(d.year + 18, d.month, d.day);
    if (cutoff.isAfter(DateTime.now())) {
      setState(() => _error = 'Você precisa ter 18 anos ou mais.');
      return;
    }
    setState(() => _error = null);
    context.push('/onboarding/orientation', extra: {
      'name': widget.name,
      'gender': widget.gender,
      'birth_date':
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
    });
  }

  @override
  Widget build(BuildContext context) {
    final filled = _ctrl.text.length == 10;
    return OnboardingScaffold(
      step: 3,
      totalSteps: 9,
      title: 'Quando você nasceu?',
      subtitle: 'Precisamos confirmar que você tem 18+.',
      bottom: OnboardingButton(
        onPressed: _isValid ? _next : null,
        child: const Text('Continuar'),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DATA DE NASCIMENTO',
              style: GoogleFonts.spaceGrotesk(
                color: TwColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrl,
              focusNode: _focus,
              keyboardType: TextInputType.number,
              inputFormatters: [_DateMaskFormatter()],
              style: GoogleFonts.spaceGrotesk(
                color: TwColors.onBg,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
              decoration: InputDecoration(
                hintText: 'DD/MM/AAAA',
                hintStyle: GoogleFonts.spaceGrotesk(
                  color: TwColors.muted,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
                filled: true,
                fillColor: TwColors.card,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TwRadius.lg),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TwRadius.lg),
                  borderSide: BorderSide(
                    color: filled ? TwColors.primary : TwColors.border,
                    width: filled ? 1.5 : 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TwRadius.lg),
                  borderSide: const BorderSide(color: TwColors.primary, width: 1.5),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: GoogleFonts.spaceGrotesk(
                  color: TwColors.error,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DateMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 8) return oldValue;

    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 2 || i == 4) buf.write('/');
      buf.write(digits[i]);
    }

    final result = buf.toString();
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}
