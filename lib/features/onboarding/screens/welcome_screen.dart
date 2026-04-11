import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tinyworld_app/features/onboarding/onboarding_controller.dart';
import 'package:tinyworld_app/features/onboarding/widgets/avatar_preview.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});
  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;
  late Animation<double> _slideUp;
  late List<_Confetti> _confetti;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _fadeIn = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _scaleIn = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
    );
    _slideUp = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
    );
    _confetti = List.generate(30, (_) => _Confetti());
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFFAFDFB),
      body: SafeArea(
        child: Stack(
          children: [
            ListenableBuilder(
              listenable: _ctrl,
              builder: (_, __) => CustomPaint(
                painter: _ConfettiPainter(
                  confetti: _confetti,
                  progress: _ctrl.value,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),
                    FadeTransition(
                      opacity: _fadeIn,
                      child: ScaleTransition(
                        scale: _scaleIn,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF1B76F2),
                                Color(0xFF3B82F6),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1B76F2)
                                    .withValues(alpha: 0.3),
                                blurRadius: 32,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: state.avatarUrl != null
                              ? AvatarPreview(
                                  avatarUrl: state.avatarUrl!, size: 140)
                              : Container(
                                  width: 140,
                                  height: 140,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF1B76F2),
                                  ),
                                  child: const Icon(Icons.person,
                                      size: 60, color: Colors.white24),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SlideTransition(
                      position: Tween(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(_slideUp),
                      child: FadeTransition(
                        opacity: _fadeIn,
                        child: Column(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) =>
                                  const LinearGradient(
                                colors: [
                                  Color(0xFF1B76F2),
                                  Color(0xFF3B82F6),
                                ],
                              ).createShader(bounds),
                              child: const Text(
                                'Bem-vindo\nao TinyWorld!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Seu agente já está pronto\npara explorar o mundo.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(flex: 3),
                    FadeTransition(
                      opacity: _fadeIn,
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1B76F2), Color(0xFF3B82F6)],
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => context.go('/'),
                            borderRadius: BorderRadius.circular(14),
                            child: const Center(
                              child: Text(
                                'Explorar o mundo',
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
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Confetti {
  final double x;
  final double startY;
  final double speed;
  final double size;
  final Color color;
  final double rotation;

  _Confetti()
      : x = Random().nextDouble(),
        startY = -0.1 - Random().nextDouble() * 0.3,
        speed = 0.3 + Random().nextDouble() * 0.5,
        size = 4 + Random().nextDouble() * 6,
        color = [
          const Color(0xFF1B76F2),
          const Color(0xFF3B82F6),
          const Color(0xFFFFC107),
          const Color(0xFF4CAF50),
          const Color(0xFFFF6B6B),
          const Color(0xFFE040FB),
        ][Random().nextInt(6)],
        rotation = Random().nextDouble() * pi * 2;
}

class _ConfettiPainter extends CustomPainter {
  final List<_Confetti> confetti;
  final double progress;

  _ConfettiPainter({required this.confetti, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < 0.2) return;
    final showProgress = ((progress - 0.2) / 0.8).clamp(0.0, 1.0);
    for (final c in confetti) {
      final y = (c.startY + c.speed * showProgress * 1.5) * size.height;
      final x = c.x * size.width;
      if (y > size.height) continue;
      final opacity = (1.0 - (y / size.height)).clamp(0.0, 0.8);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(c.rotation + showProgress * 2);
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero, width: c.size, height: c.size * 0.5),
        Paint()..color = c.color.withValues(alpha: opacity),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => progress != old.progress;
}
