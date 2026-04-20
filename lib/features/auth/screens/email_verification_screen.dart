import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tinyworld_app/core/api/rest_client.dart';
import 'package:tinyworld_app/core/theme/styles.dart';
import 'package:tinyworld_app/features/auth/auth_controller.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  const EmailVerificationScreen({super.key, required this.email});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  final List<TextEditingController> _cells =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());

  bool _loading = false;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sendOtp();
  }

  @override
  void dispose() {
    for (final c in _cells) { c.dispose(); }
    for (final n in _nodes) { n.dispose(); }
    super.dispose();
  }

  String get _code => _cells.map((c) => c.text).join();

  Future<void> _sendOtp() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await apiClient.post('/auth/send-otp');
    } catch (_) {
      // Non-fatal — user can retry
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _verify() async {
    final code = _code;
    if (code.length < 6) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await apiClient.post('/auth/verify-otp', data: {'code': code});
      if (mounted) {
        final done = await ref
            .read(authControllerProvider.notifier)
            .checkOnboardingFromServer();
        if (mounted) context.go(done ? '/' : '/onboarding/basic-info');
      }
    } catch (_) {
      setState(() {
        _error = 'Código inválido ou expirado.';
        _loading = false;
      });
      // Clear cells on error
      for (final c in _cells) { c.clear(); }
      _nodes[0].requestFocus();
    }
  }

  void _onCellChanged(int index, String value) {
    if (value.length > 1) {
      // Pasted value — distribute across cells
      final chars = value.replaceAll(RegExp(r'\D'), '').split('');
      for (int i = 0; i < 6 && i < chars.length; i++) {
        _cells[i].text = chars[i];
      }
      final next = chars.length < 6 ? chars.length : 5;
      _nodes[next].requestFocus();
      if (chars.length >= 6) _verify();
      return;
    }
    if (value.isNotEmpty && index < 5) {
      _nodes[index + 1].requestFocus();
    }
    if (_code.length == 6) _verify();
  }

  void _onKeyDown(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _cells[index].text.isEmpty &&
        index > 0) {
      _nodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TwColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: TwColors.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'Confirme seu email',
                style: GoogleFonts.spaceGrotesk(
                  color: TwColors.onBg,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.spaceGrotesk(
                      color: TwColors.onSurface, fontSize: 14, height: 1.5),
                  children: [
                    const TextSpan(text: 'Enviamos um código para '),
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(
                          color: TwColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // 6-digit OTP cells
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) => _buildCell(i)),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TwColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(TwRadius.md),
                    border:
                        Border.all(color: TwColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Text(_error!,
                      style: GoogleFonts.spaceGrotesk(
                          color: TwColors.error, fontSize: 13)),
                ),
              ],
              const SizedBox(height: 32),
              if (_loading)
                const Center(
                    child: CircularProgressIndicator(color: TwColors.primary))
              else
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: TwGradients.primary,
                      borderRadius: BorderRadius.circular(TwRadius.lg),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _code.length == 6 ? _verify : null,
                        borderRadius: BorderRadius.circular(TwRadius.lg),
                        child: Center(
                          child: Text(
                            'Verificar',
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Center(
                child: _sending
                    ? Text('Enviando código...',
                        style: GoogleFonts.spaceGrotesk(
                            color: TwColors.muted, fontSize: 13))
                    : TextButton(
                        onPressed: _sendOtp,
                        child: Text(
                          'Reenviar código',
                          style: GoogleFonts.spaceGrotesk(
                              color: TwColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCell(int i) {
    return SizedBox(
      width: 46,
      height: 58,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (e) => _onKeyDown(i, e),
        child: TextField(
          controller: _cells[i],
          focusNode: _nodes[i],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          style: GoogleFonts.spaceGrotesk(
            color: TwColors.onBg,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: TwColors.card,
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: TwColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: TwColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: TwColors.primary, width: 2),
            ),
          ),
          onChanged: (v) => _onCellChanged(i, v),
        ),
      ),
    );
  }
}
