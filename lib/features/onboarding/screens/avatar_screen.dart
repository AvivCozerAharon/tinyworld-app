import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tinyworld_app/features/onboarding/onboarding_controller.dart';
import 'package:tinyworld_app/features/onboarding/widgets/avatar_preview.dart';
import 'package:tinyworld_app/shared/widgets/onboarding_scaffold.dart';

class AvatarScreen extends ConsumerStatefulWidget {
  final Object? extra;
  const AvatarScreen({super.key, this.extra});
  @override
  ConsumerState<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends ConsumerState<AvatarScreen> {
  String _selectedStyle = 'casual';
  List<Map<String, dynamic>> _variations = [];

  @override
  void initState() {
    super.initState();
    final data = widget.extra as Map<String, dynamic>?;
    if (data != null) {
      _variations =
          List<Map<String, dynamic>>.from(data['variations'] as List);
      if (_variations.isNotEmpty) {
        _selectedStyle = _variations.first['style'] as String;
      }
    }
  }

  Future<void> _confirm() async {
    final ok = await ref
        .read(onboardingControllerProvider.notifier)
        .saveAvatar(_selectedStyle);
    if (ok && mounted) context.go('/onboarding/hobbies');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    return OnboardingScaffold(
      step: 3,
      title: 'Seu avatar',
      subtitle: 'Escolha como você vai aparecer no mundo.',
      bottom: OnboardingButton(
        onPressed: _variations.isNotEmpty ? _confirm : null,
        isLoading: state.isLoading,
        child: const Text('Usar este avatar'),
      ),
      child: _variations.isEmpty
          ? Center(
              child: Text(
                'Nenhuma variação disponível',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
              ),
            )
          : Column(
              children: [
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _variations.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (_, i) {
                      final v = _variations[i];
                      final style = v['style'] as String;
                      final url = v['preview_url'] as String;
                      final isSelected = _selectedStyle == style;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedStyle = style),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 130,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: isSelected
                                ? const Color(0xFF6C63FF).withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.04),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF6C63FF)
                                  : Colors.white.withValues(alpha: 0.08),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF6C63FF)
                                          .withValues(alpha: 0.3),
                                      blurRadius: 16,
                                    )
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? const Color(0xFF6C63FF)
                                          .withValues(alpha: 0.1)
                                      : null,
                                ),
                                child: AvatarPreview(
                                  avatarUrl: url,
                                  size: 72,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                style[0].toUpperCase() + style.substring(1),
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white54,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(state.error!,
                          style:
                              const TextStyle(color: Colors.redAccent, fontSize: 13)),
                    ),
                  ),
              ],
            ),
    );
  }
}
