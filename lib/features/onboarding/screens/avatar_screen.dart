import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tinyworld_app/core/theme/styles.dart';
import 'package:tinyworld_app/features/onboarding/onboarding_controller.dart';
import 'package:tinyworld_app/features/onboarding/widgets/avatar_preview.dart';
import 'package:tinyworld_app/features/onboarding/widgets/color_swatch_grid.dart';
import 'package:tinyworld_app/features/onboarding/widgets/option_card_list.dart';
import 'package:tinyworld_app/shared/widgets/onboarding_scaffold.dart';

// ── Palettes ──────────────────────────────────────────────────────────────────

const _skinColors = [
  // Realistic tones
  'fddcb5', 'edb98a', 'd08b5b', 'ae5d29', '694d3d', '3d1a00',
  // Fun
  'ae8ee4', 'f9c74f', '90e0ef', '95d5b2', 'ffb3c6', '48cae4',
];

const _hairColors = [
  // Realistic
  '2c1b18', '724133', 'b58143', 'c93305', 'ecdcbf', '929598',
  // Fun
  '7b2d8b', '2196f3', 'e91e63', '4caf50', 'ff9800', '00bcd4',
];

const _clotheColors = [
  '3c4f5c', '65c9ff', '5199e4', '25557c', 'e6e6e6', 'ffffff',
  'ff5c5c', 'ff488e', 'a7ffc4', 'ffafb9', '262e33', 'ffd700',
];

// ── Options ───────────────────────────────────────────────────────────────────

const _hairOptions = [
  AvatarOption('shortCurly',           'Curly'),
  AvatarOption('shortFlat',            'Flat'),
  AvatarOption('shortRound',           'Round'),
  AvatarOption('shortWaved',           'Waved'),
  AvatarOption('sides',                'Sides'),
  AvatarOption('dreads01',             'Dreads'),
  AvatarOption('theCaesar',            'Caesar'),
  AvatarOption('frizzle',              'Frizzle'),
  AvatarOption('straight01',           'Straight'),
  AvatarOption('curly',                'Long Curly'),
  AvatarOption('bob',                  'Bob'),
  AvatarOption('bun',                  'Bun'),
  AvatarOption('fro',                  'Fro'),
  AvatarOption('dreads',               'Long Dreads'),
  AvatarOption('miaWallace',           'Mia'),
  AvatarOption('hat',                  'Hat'),
  AvatarOption('hijab',                'Hijab'),
  AvatarOption('turban',               'Turban'),
];

const _eyeOptions = [
  AvatarOption('default',    'Default'),
  AvatarOption('happy',      'Happy'),
  AvatarOption('wink',       'Wink'),
  AvatarOption('hearts',     'Hearts'),
  AvatarOption('squint',     'Squint'),
  AvatarOption('surprised',  'Surprised'),
  AvatarOption('side',       'Side'),
  AvatarOption('cry',        'Cry'),
  AvatarOption('eyeRoll',    'Roll'),
  AvatarOption('xDizzy',     'Dizzy'),
];

const _eyebrowOptions = [
  AvatarOption('default',                'Default'),
  AvatarOption('defaultNatural',         'Natural'),
  AvatarOption('raisedExcited',          'Excited'),
  AvatarOption('raisedExcitedNatural',   'Excited+'),
  AvatarOption('angry',                  'Angry'),
  AvatarOption('angryNatural',           'Angry+'),
  AvatarOption('sadConcerned',           'Sad'),
  AvatarOption('sadConcernedNatural',    'Sad+'),
  AvatarOption('upDown',                 'Up-Down'),
  AvatarOption('unibrowNatural',         'Unibrow'),
  AvatarOption('flatNatural',            'Flat'),
];

const _mouthOptions = [
  AvatarOption('smile',       'Smile'),
  AvatarOption('default',     'Default'),
  AvatarOption('serious',     'Serious'),
  AvatarOption('tongue',      'Tongue'),
  AvatarOption('twinkle',     'Twinkle'),
  AvatarOption('sad',         'Sad'),
  AvatarOption('screamOpen',  'Scream'),
  AvatarOption('eating',      'Eating'),
  AvatarOption('grimace',     'Grimace'),
  AvatarOption('disbelief',   'Disbelief'),
];

const _accessoryOptions = [
  AvatarOption('blank',          'Nenhum'),
  AvatarOption('prescription01', 'Prescrição 1'),
  AvatarOption('prescription02', 'Prescrição 2'),
  AvatarOption('round',          'Redondo'),
  AvatarOption('kurt',           'Kurt'),
  AvatarOption('sunglasses',     'Sol'),
  AvatarOption('wayfarers',      'Wayfarer'),
  AvatarOption('eyepatch',       'Monóculo'),
];

const _facialHairOptions = [
  AvatarOption('blank',           'Nenhum'),
  AvatarOption('beardLight',      'Leve'),
  AvatarOption('beardMedium',     'Médio'),
  AvatarOption('beardMajestic',   'Majestoso'),
  AvatarOption('moustacheFancy',  'Bigode'),
  AvatarOption('moustacheMagnum', 'Magnum'),
];

const _clotheOptions = [
  AvatarOption('shirtCrewNeck',    'Camiseta'),
  AvatarOption('shirtScoopNeck',   'Decote'),
  AvatarOption('shirtVNeck',       'V-Neck'),
  AvatarOption('hoodie',           'Moletom'),
  AvatarOption('blazerAndShirt',   'Blazer'),
  AvatarOption('blazerAndSweater', 'Blazer+'),
  AvatarOption('collarAndSweater', 'Colarinho'),
  AvatarOption('overall',          'Macacão'),
  AvatarOption('graphicShirt',     'Estampada'),
];

// ── Named hair color → hex (from liveness detection) ────────────────────────

const _namedHairToHex = {
  'brown': '724133',
  'black': '2c1b18',
  'blonde': 'b58143',
  'red': 'c93305',
  'white': 'ecdcbf',
  'gray': '929598',
};

// ── State model ───────────────────────────────────────────────────────────────

class _AvatarState {
  final String skinColor;
  final String top;
  final String hairColor;
  final String eyeType;
  final String eyebrowType;
  final String mouthType;
  final String facialHairType;
  final String accessories;
  final String clotheType;
  final String clotheColor;

  const _AvatarState({
    required this.skinColor,
    required this.top,
    required this.hairColor,
    required this.eyeType,
    required this.eyebrowType,
    required this.mouthType,
    required this.facialHairType,
    required this.accessories,
    required this.clotheType,
    required this.clotheColor,
  });

  _AvatarState copyWith({
    String? skinColor,
    String? top,
    String? hairColor,
    String? eyeType,
    String? eyebrowType,
    String? mouthType,
    String? facialHairType,
    String? accessories,
    String? clotheType,
    String? clotheColor,
  }) =>
      _AvatarState(
        skinColor:      skinColor      ?? this.skinColor,
        top:            top            ?? this.top,
        hairColor:      hairColor      ?? this.hairColor,
        eyeType:        eyeType        ?? this.eyeType,
        eyebrowType:    eyebrowType    ?? this.eyebrowType,
        mouthType:      mouthType      ?? this.mouthType,
        facialHairType: facialHairType ?? this.facialHairType,
        accessories:    accessories    ?? this.accessories,
        clotheType:     clotheType     ?? this.clotheType,
        clotheColor:    clotheColor    ?? this.clotheColor,
      );

  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{
      'skinColor':    skinColor,
      'top':          top,
      'hairColor':    hairColor,
      'eyes':         eyeType,
      'eyebrows':     eyebrowType,
      'mouth':        mouthType,
      'clothing':     clotheType,
      'clothesColor': clotheColor,
    };
    if (facialHairType != 'blank') {
      m['facialHair'] = facialHairType;
      m['facialHairProbability'] = '100';
    }
    if (accessories != 'blank') {
      m['accessories'] = accessories;
      m['accessoriesProbability'] = '100';
    }
    return m;
  }

  String buildUrl(String seed) {
    return Uri.https('api.dicebear.com', '/7.x/avataaars/svg', {
      'seed': seed,
      'backgroundColor': 'b6e3f4,c0aede,d1d4f9,ffd5dc,ffdfbf',
      ...toMap().map((k, v) => MapEntry(k, v.toString())),
    }).toString();
  }
}

const _defaultState = _AvatarState(
  skinColor:      'fddcb5',
  top:            'ShortHairShortCurly',
  hairColor:      '724133',
  eyeType:        'Default',
  eyebrowType:    'Default',
  mouthType:      'Smile',
  facialHairType: 'blank',
  accessories:    'blank',
  clotheType:     'ShirtCrewNeck',
  clotheColor:    '3c4f5c',
);

// ── Screen ────────────────────────────────────────────────────────────────────

enum _AvatarTab { skin, hair, face, accessories, clothes }

class AvatarScreen extends ConsumerStatefulWidget {
  final Object? extra;
  const AvatarScreen({super.key, this.extra});

  @override
  ConsumerState<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends ConsumerState<AvatarScreen> {
  _AvatarTab _tab = _AvatarTab.skin;
  late _AvatarState _state;
  late _AvatarState _livenessDefaults;
  String _previewUrl = '';
  String _cachedSeed = '';

  @override
  void initState() {
    super.initState();
    _livenessDefaults = _buildDefaults();
    _state = _livenessDefaults;
    _previewUrl = _state.buildUrl('preview');
    _cachedSeed = 'preview';
  }

  void _setAvatarState(_AvatarState newState) {
    setState(() {
      _state = newState;
      _previewUrl = newState.buildUrl(_cachedSeed);
    });
  }

  _AvatarState _buildDefaults() {
    final data = widget.extra as Map<String, dynamic>?;
    final appearance = data?['appearance'] as Map<String, dynamic>? ?? {};
    final hairName = appearance['hair_color'] as String? ?? 'brown';
    final hasGlasses = appearance['has_glasses'] as bool? ?? false;
    final hasBeard = appearance['has_beard'] as bool? ?? false;
    return _defaultState.copyWith(
      hairColor:      _namedHairToHex[hairName] ?? '724133',
      accessories:    hasGlasses ? 'prescription01' : 'blank',
      facialHairType: hasBeard   ? 'beardMedium'   : 'blank',
    );
  }

  Future<void> _confirm() async {
    if (ref.read(onboardingControllerProvider).isLoading) return;
    ref.read(onboardingControllerProvider.notifier).setAppearance(_state.toMap());
    final ok = await ref
        .read(onboardingControllerProvider.notifier)
        .saveAvatar('custom');
    if (ok && mounted) context.push('/onboarding/hobbies');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final userId = state.userId ?? 'preview';
    if (_cachedSeed != userId) {
      _cachedSeed = userId;
      _previewUrl = _state.buildUrl(userId);
    }
    final previewUrl = _previewUrl;

    return OnboardingScaffold(
      step: 6,
      totalSteps: 9,
      title: 'Seu avatar',
      subtitle: 'Personalize como você vai aparecer.',
      bottom: OnboardingButton(
        onPressed: _confirm,
        isLoading: state.isLoading,
        child: const Text('Usar este avatar'),
      ),
      child: Column(
        children: [
          // ── Preview + reset ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    gradient: TwGradients.card,
                    borderRadius: BorderRadius.circular(TwRadius.xl),
                    border: Border.all(color: TwColors.border),
                  ),
                  child: Center(
                    child: AvatarPreview(avatarUrl: previewUrl, size: 120),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: GestureDetector(
                    onTap: () => _setAvatarState(_livenessDefaults),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: TwColors.card,
                        borderRadius: BorderRadius.circular(TwRadius.md),
                        border: Border.all(color: TwColors.border),
                      ),
                      child: Text(
                        'Resetar',
                        style: GoogleFonts.spaceGrotesk(
                          color: TwColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Options area ─────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildTabContent(),
            ),
          ),
          // ── Tab bar ───────────────────────────────────────────────────────
          _buildTabBar(),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TwColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(TwRadius.md),
                  border: Border.all(color: TwColors.error.withValues(alpha: 0.3)),
                ),
                child: Text(state.error!,
                    style: GoogleFonts.spaceGrotesk(color: TwColors.error, fontSize: 13)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    const tabs = [
      (_AvatarTab.skin,        Icons.face,                  'Pele'),
      (_AvatarTab.hair,        Icons.waves,                 'Cabelo'),
      (_AvatarTab.face,        Icons.sentiment_satisfied,   'Rosto'),
      (_AvatarTab.accessories, Icons.style,                 'Acess.'),
      (_AvatarTab.clothes,     Icons.checkroom,             'Roupa'),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      decoration: BoxDecoration(
        color: TwColors.card,
        borderRadius: BorderRadius.circular(TwRadius.md),
        border: Border.all(color: TwColors.border),
      ),
      child: Row(
        children: tabs.map((t) {
          final (tab, icon, label) = t;
          final isActive = _tab == tab;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tab = tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: isActive ? TwGradients.primary : null,
                  borderRadius: BorderRadius.circular(TwRadius.sm),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18, color: isActive ? Colors.white : TwColors.muted),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? Colors.white : TwColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent() {
    return switch (_tab) {
      _AvatarTab.skin        => _buildSkinTab(),
      _AvatarTab.hair        => _buildHairTab(),
      _AvatarTab.face        => _buildFaceTab(),
      _AvatarTab.accessories => _buildAccessoriesTab(),
      _AvatarTab.clothes     => _buildClothesTab(),
    };
  }

  Widget _buildSkinTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _sectionLabel('Tom de pele'),
          const SizedBox(height: 10),
          ColorSwatchGrid(
            colors: _skinColors,
            selected: _state.skinColor,
            onChanged: (v) => _setAvatarState(_state.copyWith(skinColor: v)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHairTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _sectionLabel('Tipo de cabelo'),
          const SizedBox(height: 10),
          OptionCardList(
            options: _hairOptions,
            selected: _state.top,
            onChanged: (v) => _setAvatarState(_state.copyWith(top: v)),
          ),
          const SizedBox(height: 16),
          _sectionLabel('Cor do cabelo'),
          const SizedBox(height: 10),
          ColorSwatchGrid(
            colors: _hairColors,
            selected: _state.hairColor,
            onChanged: (v) => _setAvatarState(_state.copyWith(hairColor: v)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFaceTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _sectionLabel('Olhos'),
          const SizedBox(height: 10),
          OptionCardList(
            options: _eyeOptions,
            selected: _state.eyeType,
            onChanged: (v) => _setAvatarState(_state.copyWith(eyeType: v)),
          ),
          const SizedBox(height: 16),
          _sectionLabel('Sobrancelhas'),
          const SizedBox(height: 10),
          OptionCardList(
            options: _eyebrowOptions,
            selected: _state.eyebrowType,
            onChanged: (v) => _setAvatarState(_state.copyWith(eyebrowType: v)),
          ),
          const SizedBox(height: 16),
          _sectionLabel('Boca'),
          const SizedBox(height: 10),
          OptionCardList(
            options: _mouthOptions,
            selected: _state.mouthType,
            onChanged: (v) => _setAvatarState(_state.copyWith(mouthType: v)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAccessoriesTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _sectionLabel('Óculos'),
          const SizedBox(height: 10),
          OptionCardList(
            options: _accessoryOptions,
            selected: _state.accessories,
            onChanged: (v) => _setAvatarState(_state.copyWith(accessories: v)),
          ),
          const SizedBox(height: 16),
          _sectionLabel('Barba / Bigode'),
          const SizedBox(height: 10),
          OptionCardList(
            options: _facialHairOptions,
            selected: _state.facialHairType,
            onChanged: (v) => _setAvatarState(_state.copyWith(facialHairType: v)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildClothesTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _sectionLabel('Tipo de roupa'),
          const SizedBox(height: 10),
          OptionCardList(
            options: _clotheOptions,
            selected: _state.clotheType,
            onChanged: (v) => _setAvatarState(_state.copyWith(clotheType: v)),
          ),
          const SizedBox(height: 16),
          _sectionLabel('Cor da roupa'),
          const SizedBox(height: 10),
          ColorSwatchGrid(
            colors: _clotheColors,
            selected: _state.clotheColor,
            onChanged: (v) => _setAvatarState(_state.copyWith(clotheColor: v)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
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
