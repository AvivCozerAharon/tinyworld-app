import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tinyworld_app/core/storage/local_storage.dart';
import 'package:tinyworld_app/features/auth/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _showEmailForm = false;
  late AnimationController _floatCtrl;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B76F2), Color(0xFF0D4A8F)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    _buildPixelScene(size),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(flex: 2),
                            _buildLogo(),
                            const SizedBox(height: 24),
                            const Text(
                              'Small world.\nDeep connections.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Seu agente encontra as pessoas certas\nantes do primeiro olá.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                            const Spacer(flex: 3),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildBottomSheet(authState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return ListenableBuilder(
      listenable: _floatCtrl,
      builder: (_, __) {
        final dy = 4 * sin(_floatCtrl.value * pi);
        return Transform.translate(
          offset: Offset(0, dy),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFE8F4FD)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'tiny',
                      style: TextStyle(
                        color: Color(0xFF1B76F2),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: 'world',
                      style: TextStyle(
                        color: Color(0xFF3B82F6),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPixelScene(Size size) {
    return ListenableBuilder(
      listenable: _floatCtrl,
      builder: (_, __) {
        return CustomPaint(
          size: size,
          painter: _PixelScenePainter(_floatCtrl.value),
        );
      },
    );
  }

  Widget _buildBottomSheet(AuthState authState) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_showEmailForm) ...[
            _SocialButton(
              icon: _googleIcon(),
              label: 'Continuar com Google',
              onPressed: () => _handleGoogle(authState),
              isLoading: authState.isLoading,
            ),
            const SizedBox(height: 12),
            _SocialButton(
              icon: _appleIcon(),
              label: 'Continuar com Apple',
              onPressed: () => _handleApple(authState),
            ),
            const SizedBox(height: 12),
            _SocialButton(
              icon: const Icon(Icons.email_outlined,
                  size: 20, color: Color(0xFF1B76F2)),
              label: 'Continuar com email',
              onPressed: () => setState(() => _showEmailForm = true),
              isOutlined: true,
            ),
          ] else ...[
            _buildEmailForm(authState),
          ],
          if (authState.error != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                authState.error!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Ao continuar, você concorda com nossos\nTermos de Uso e Política de Privacidade',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailForm(AuthState authState) {
    return Column(
      children: [
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'Email',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: const Color(0xFFF5F7FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _passCtrl,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Senha',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: const Color(0xFFF5F7FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFF1B76F2), Color(0xFF3B82F6)],
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: authState.isLoading
                    ? null
                    : () {
                        final email = _emailCtrl.text.trim();
                        final pass = _passCtrl.text.trim();
                        if (email.isEmpty || pass.isEmpty) return;
                        ref
                            .read(authControllerProvider.notifier)
                            .signInWithEmail(email, pass)
                            .then((ok) {
                          if (ok && mounted) {
                            final user = ref
                                .read(authControllerProvider)
                                .firebaseUser;
                            if (user != null) {
                              final done =
                                  localStorage.isOnboardingDone();
                              done.then((isDone) {
                                if (mounted) {
                                  context.go(isDone
                                      ? '/'
                                      : '/onboarding/basic-info');
                                }
                              });
                            }
                          }
                        });
                      },
                borderRadius: BorderRadius.circular(14),
                child: Center(
                  child: authState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Entrar',
                          style: TextStyle(
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
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() => _showEmailForm = false),
          child: Text(
            'Voltar',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Future<void> _handleGoogle(AuthState authState) async {
    final ok =
        await ref.read(authControllerProvider.notifier).signInWithGoogle();
    if (ok && mounted) {
      final user = ref.read(authControllerProvider).firebaseUser;
      if (user != null) {
        final done = await localStorage.isOnboardingDone();
        if (mounted) context.go(done ? '/' : '/onboarding/basic-info');
      }
    }
  }

  Future<void> _handleApple(AuthState authState) async {
    final ok =
        await ref.read(authControllerProvider.notifier).signInWithApple();
    if (ok && mounted) {
      final user = ref.read(authControllerProvider).firebaseUser;
      if (user != null) {
        final done = await localStorage.isOnboardingDone();
        if (mounted) context.go(done ? '/' : '/onboarding/basic-info');
      }
    }
  }

  Widget _googleIcon() {
    return SizedBox(
      width: 20,
      height: 20,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Center(
          child: Text(
            'G',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF4285F4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _appleIcon() {
    return const Icon(Icons.apple, size: 22, color: Colors.black87);
  }
}

class _SocialButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isOutlined;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _buildChild(),
            )
          : Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isLoading ? null : onPressed,
                  borderRadius: BorderRadius.circular(14),
                  child: _buildChild(),
                ),
              ),
            ),
    );
  }

  Widget _buildChild() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          icon,
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1A1A2E),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PixelScenePainter extends CustomPainter {
  final double tick;

  _PixelScenePainter(this.tick);

  @override
  void paint(Canvas canvas, Size size) {
    final groundY = size.height * 0.65;

    final groundPaint = Paint()..color = const Color(0xFF4CAF50);
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, size.width, size.height - groundY),
      groundPaint,
    );

    final darkGrass = Paint()..color = const Color(0xFF45A049);
    const tileW = 24.0;
    const tileH = 24.0;
    for (double x = 0; x < size.width; x += tileW) {
      for (double y = groundY; y < size.height; y += tileH) {
        final ix = (x / tileW).floor();
        final iy = ((y - groundY) / tileH).floor();
        if ((ix + iy) % 2 == 0) {
          canvas.drawRect(
            Rect.fromLTWH(x, y, tileW, tileH),
            darkGrass,
          );
        }
      }
    }

    _drawPixelTree(canvas, size.width * 0.1, groundY - 20, 1.2);
    _drawPixelTree(canvas, size.width * 0.85, groundY - 30, 1.5);
    _drawPixelTree(canvas, size.width * 0.65, groundY - 15, 1.0);

    _drawPixelHouse(canvas, size.width * 0.35, groundY);

    final charY = groundY - 30;
    final bounce = 2 * sin(tick * pi * 2);
    _drawPixelChar(canvas, size.width * 0.5, charY + bounce,
        const Color(0xFF1B76F2), true);
    _drawPixelChar(
        canvas, size.width * 0.25, charY + 10, const Color(0xFFEF5350), false);
    _drawPixelChar(canvas, size.width * 0.75, charY - 5,
        const Color(0xFFFFC107), false);

    _drawConnectionLine(canvas, size.width * 0.5, charY + bounce,
        size.width * 0.25, charY + 10);
    _drawConnectionLine(canvas, size.width * 0.5, charY + bounce,
        size.width * 0.75, charY - 5);
  }

  void _drawPixelTree(Canvas canvas, double x, double y, double scale) {
    final s = scale;
    final trunkPaint = Paint()..color = const Color(0xFF795548);
    canvas.drawRect(
      Rect.fromLTWH(x - 3 * s, y + 8 * s, 6 * s, 16 * s),
      trunkPaint,
    );
    final foliagePaint = Paint()..color = const Color(0xFF2E7D32);
    canvas.drawRect(
      Rect.fromLTWH(x - 14 * s, y - 12 * s, 28 * s, 24 * s),
      foliagePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(x - 10 * s, y - 20 * s, 20 * s, 12 * s),
      foliagePaint,
    );
  }

  void _drawPixelHouse(Canvas canvas, double x, double groundY) {
    final wallPaint = Paint()..color = const Color(0xFFEFC9AF);
    canvas.drawRect(
      Rect.fromLTWH(x - 20, groundY - 30, 40, 30),
      wallPaint,
    );
    final roofPaint = Paint()..color = const Color(0xFFD84315);
    canvas.drawRect(
      Rect.fromLTWH(x - 24, groundY - 42, 48, 14),
      roofPaint,
    );
    final doorPaint = Paint()..color = const Color(0xFF795548);
    canvas.drawRect(
      Rect.fromLTWH(x - 5, groundY - 18, 10, 18),
      doorPaint,
    );
  }

  void _drawPixelChar(
      Canvas canvas, double x, double y, Color color, bool hasCrown) {
    canvas.drawRect(
      Rect.fromLTWH(x - 6, y, 12, 14),
      Paint()..color = color,
    );
    canvas.drawRect(
      Rect.fromLTWH(x - 5, y - 10, 10, 10),
      Paint()..color = color,
    );
    canvas.drawRect(
      Rect.fromLTWH(x - 5, y - 10, 3, 2),
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      Rect.fromLTWH(x + 2, y - 10, 3, 2),
      Paint()..color = Colors.white,
    );
    if (hasCrown) {
      canvas.drawRect(
        Rect.fromLTWH(x - 6, y - 15, 12, 4),
        Paint()..color = const Color(0xFFFFC107),
      );
      canvas.drawRect(
        Rect.fromLTWH(x - 6, y - 18, 3, 3),
        Paint()..color = const Color(0xFFFFC107),
      );
      canvas.drawRect(
        Rect.fromLTWH(x + 3, y - 18, 3, 3),
        Paint()..color = const Color(0xFFFFC107),
      );
    }
  }

  void _drawConnectionLine(
      Canvas canvas, double x1, double y1, double x2, double y2) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 2;
    const dashLen = 6.0;
    const gapLen = 4.0;
    final dx = x2 - x1;
    final dy = y2 - y1;
    final dist = sqrt(dx * dx + dy * dy);
    final steps = (dist / (dashLen + gapLen)).floor();
    for (int i = 0; i < steps; i++) {
      final startFrac = (i * (dashLen + gapLen)) / dist;
      final endFrac = ((i * (dashLen + gapLen)) + dashLen) / dist;
      if (endFrac > 1) break;
      canvas.drawLine(
        Offset(x1 + dx * startFrac, y1 + dy * startFrac),
        Offset(x1 + dx * endFrac, y1 + dy * endFrac),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_PixelScenePainter old) => true;
}
