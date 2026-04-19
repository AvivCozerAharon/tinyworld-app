import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tinyworld_app/core/theme/styles.dart';
import 'package:tinyworld_app/features/onboarding/onboarding_controller.dart';
import 'package:tinyworld_app/features/onboarding/widgets/avatar_preview.dart';
import 'package:tinyworld_app/shared/widgets/onboarding_scaffold.dart';
import 'package:google_fonts/google_fonts.dart';

const _skinTones = [
  Color(0xFFFDDEBA), // light
  Color(0xFFF5C99C), // light-medium
  Color(0xFFE8A87C), // medium
  Color(0xFFC98B5C), // medium-dark
  Color(0xFF8D5524), // dark
  Color(0xFF4A2912), // deep
];

const _hairColors = [
  Color(0xFF1C1C1C), // black
  Color(0xFF4A3728), // dark brown
  Color(0xFF8B5E3C), // brown
  Color(0xFFB8860B), // dark blonde
  Color(0xFFE8C45A), // blonde
  Color(0xFFCC2936), // red
  Color(0xFF8B8B8B), // grey
  Color(0xFFFFFFFF), // white
];

class AvatarScreen extends ConsumerStatefulWidget {
  final Object? extra;
  const AvatarScreen({super.key, this.extra});
  @override
  ConsumerState<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends ConsumerState<AvatarScreen>
    with SingleTickerProviderStateMixin {
  String _selectedStyle = 'casual';
  List<Map<String, dynamic>> _variations = [];
  late TabController _tabController;

  // Customization state
  int _skinToneIdx = 0;
  int _hairColorIdx = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final data = widget.extra as Map<String, dynamic>?;
    if (data != null) {
      _variations = List<Map<String, dynamic>>.from(data['variations'] as List);
      if (_variations.isNotEmpty) {
        _selectedStyle = _variations.first['style'] as String;
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _selectedAvatarUrl {
    final v = _variations.where((v) => v['style'] == _selectedStyle).firstOrNull;
    return v?['preview_url'] as String? ?? '';
  }

  Future<void> _confirm() async {
    ref.read(onboardingControllerProvider.notifier).setAppearance({
      'skin_tone': _skinToneToHex(_skinTones[_skinToneIdx]),
      'hair_color': _colorToHex(_hairColors[_hairColorIdx]),
    });
    final ok = await ref
        .read(onboardingControllerProvider.notifier)
        .saveAvatar(_selectedStyle);
    if (ok && mounted) context.push('/onboarding/hobbies');
  }

  String _colorToHex(Color c) =>
      '#${c.r.toInt().toRadixString(16).padLeft(2, '0')}'
      '${c.g.toInt().toRadixString(16).padLeft(2, '0')}'
      '${c.b.toInt().toRadixString(16).padLeft(2, '0')}';

  String _skinToneToHex(Color c) => _colorToHex(c);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    return OnboardingScaffold(
      step: 6,
      totalSteps: 9,
      title: 'Seu avatar',
      subtitle: 'Escolha e personalize como você vai aparecer.',
      bottom: OnboardingButton(
        onPressed: _variations.isNotEmpty ? _confirm : null,
        isLoading: state.isLoading,
        child: const Text('Usar este avatar'),
      ),
      child: _variations.isEmpty
          ? const Center(
              child: Text(
                'Nenhuma variação disponível',
                style: TextStyle(color: TwColors.muted, fontSize: 14),
              ),
            )
          : Column(
              children: [
                // Large preview
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      gradient: TwGradients.card,
                      borderRadius: BorderRadius.circular(TwRadius.xl),
                      border: Border.all(color: TwColors.border),
                    ),
                    child: Center(
                      child: _selectedAvatarUrl.isNotEmpty
                          ? AvatarPreview(avatarUrl: _selectedAvatarUrl, size: 100)
                          : const Icon(Icons.person, size: 60, color: TwColors.muted),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Tabs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: TwColors.card,
                      borderRadius: BorderRadius.circular(TwRadius.md),
                      border: Border.all(color: TwColors.border),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        gradient: TwGradients.primary,
                        borderRadius: BorderRadius.circular(TwRadius.sm),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorPadding: const EdgeInsets.all(3),
                      labelColor: Colors.white,
                      unselectedLabelColor: TwColors.muted,
                      labelStyle: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      unselectedLabelStyle: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      tabs: const [
                        Tab(text: 'Estilo'),
                        Tab(text: 'Aparência'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildStyleTab(),
                      _buildAppearanceTab(),
                    ],
                  ),
                ),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: TwColors.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(TwRadius.md),
                        border: Border.all(
                          color: TwColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(state.error!,
                          style: GoogleFonts.spaceGrotesk(
                              color: TwColors.error, fontSize: 13)),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildStyleTab() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _variations.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (_, i) {
        final v = _variations[i];
        final style = v['style'] as String;
        final url = v['preview_url'] as String;
        final isSelected = _selectedStyle == style;
        return GestureDetector(
          onTap: () => setState(() => _selectedStyle = style),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(TwRadius.xl),
              gradient: isSelected ? TwGradients.card : null,
              color: isSelected ? null : TwColors.card,
              border: Border.all(
                color: isSelected ? TwColors.primary : TwColors.border,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: TwColors.primary.withValues(alpha: 0.25),
                        blurRadius: 16,
                      )
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AvatarPreview(avatarUrl: url, size: 68),
                const SizedBox(height: 8),
                Text(
                  style[0].toUpperCase() + style.substring(1),
                  style: GoogleFonts.spaceGrotesk(
                    color: isSelected ? TwColors.primary : TwColors.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: TwColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppearanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('Tom de pele'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: List.generate(_skinTones.length, (i) {
              final isSelected = _skinToneIdx == i;
              return GestureDetector(
                onTap: () => setState(() => _skinToneIdx = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _skinTones[i],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? TwColors.primary : TwColors.border,
                      width: isSelected ? 2.5 : 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: TwColors.primary.withValues(alpha: 0.4),
                              blurRadius: 8,
                            )
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          _buildSectionLabel('Cor do cabelo'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(_hairColors.length, (i) {
              final isSelected = _hairColorIdx == i;
              final color = _hairColors[i];
              return GestureDetector(
                onTap: () => setState(() => _hairColorIdx = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? TwColors.primary
                          : color == const Color(0xFFFFFFFF)
                              ? TwColors.border
                              : Colors.transparent,
                      width: isSelected ? 2.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: TwColors.primary.withValues(alpha: 0.4),
                              blurRadius: 8,
                            )
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: color.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                        )
                      : null,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.spaceGrotesk(
        color: TwColors.muted,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}
