import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tinyworld_app/core/theme/styles.dart';
import 'package:tinyworld_app/features/auth/auth_controller.dart';
import 'package:tinyworld_app/features/chats/chats_controller.dart';
import 'package:tinyworld_app/features/profile/profile_controller.dart';
import 'package:tinyworld_app/features/onboarding/widgets/avatar_preview.dart';
import 'package:tinyworld_app/shared/widgets/app_animations.dart';
import 'package:tinyworld_app/core/storage/local_storage.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _picker = ImagePicker();
  final List<String?> _photoSlots = [null, null, null];
  final List<bool> _uploading = [false, false, false];
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);

    if (!state.isLoading && state.profile != null && !_initialized) {
      _initialized = true;
      final photos = state.profile!.photos;
      for (int i = 0; i < photos.length && i < 3; i++) {
        _photoSlots[i] = photos[i];
      }
    }

    return Scaffold(
      backgroundColor: TwColors.bg,
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: TwColors.primary))
          : state.error != null
              ? Center(child: Text(state.error!))
              : _buildContent(context, ref, state.profile!),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, ProfileData profile) {
    final chatsState = ref.watch(chatsControllerProvider);
    final totalChats = chatsState.chats.length;

    return RefreshIndicator(
      color: TwColors.primary,
      backgroundColor: TwColors.card,
      onRefresh: () => ref.read(profileControllerProvider.notifier).loadProfile(),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: 16),
          _buildHeader(context, ref, profile, totalChats),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text('Suas fotos',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: TwColors.muted,
                      letterSpacing: 0.5,
                    )),
                const Spacer(),
                Text('Visível após humanizar',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      color: TwColors.muted,
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(3, (i) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: i == 0 ? 0 : 5,
                    right: i == 2 ? 0 : 5,
                  ),
                  child: _buildPhotoSlot(i),
                ),
              )),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Ferramentas',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: TwColors.muted,
                  letterSpacing: 0.5,
                )),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SectionCard(
              title: 'Meu Cerebro',
              subtitle: 'Veja o que seu agente sabe sobre voce',
              icon: Icons.auto_awesome_outlined,
              color: const Color(0xFF6C5CE7),
              onTap: () => context.push('/profile/brain'),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SectionCard(
              title: 'Treinar meu agente',
              subtitle: 'Responda perguntas para melhorar seus matches',
              icon: Icons.psychology_outlined,
              color: TwColors.secondary,
              onTap: () => context.push('/profile/train'),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SectionCard(
              title: 'Configuracoes',
              subtitle: 'Editar nome, hobbies e preferencias',
              icon: Icons.settings_outlined,
              color: TwColors.onSurface,
              onTap: () => context.push('/profile/edit'),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _LogoutButton(
              onTap: () async {
                try {
                  await ref
                      .read(authControllerProvider.notifier)
                      .signOut();
                } catch (_) {
                  await localStorage.clearAll();
                }
                if (context.mounted) context.go('/login');
              },
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<Uint8List> _compress(Uint8List bytes) async {
    if (kIsWeb) return bytes;
    return await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: 800,
      minHeight: 800,
      quality: 80,
      format: CompressFormat.jpeg,
    );
  }

  Future<void> _pickPhoto(int index) async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _uploading[index] = true);
    try {
      final bytes = await file.readAsBytes();
      final compressed = await _compress(bytes);
      final b64 = base64Encode(compressed);
      setState(() => _photoSlots[index] = b64);
      final photos = _photoSlots.whereType<String>().toList();
      final ok = await ref.read(profileControllerProvider.notifier).savePhotos(photos);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar foto no servidor.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading[index] = false);
    }
  }

  Future<void> _removePhoto(int index) async {
    setState(() => _photoSlots[index] = null);
    final photos = _photoSlots.whereType<String>().toList();
    try {
      if (photos.isNotEmpty) {
        await ref.read(profileControllerProvider.notifier).savePhotos(photos);
      }
    } catch (_) {}
  }

  Widget _buildPhotoSlot(int i) {
    final b64 = _photoSlots[i];
    final loading = _uploading[i];
    return AspectRatio(
      aspectRatio: 0.85,
      child: GestureDetector(
        onTap: b64 == null && !loading ? () => _pickPhoto(i) : null,
        child: Container(
          decoration: BoxDecoration(
            color: TwColors.card,
            borderRadius: BorderRadius.circular(TwRadius.lg),
            border: Border.all(color: TwColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(TwRadius.lg - 1),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (b64 != null)
                  GestureDetector(
                    onTap: () => _showPhotoViewer(context, _photoSlots.whereType<String>().toList(), _photoSlots.whereType<String>().toList().indexOf(b64)),
                    child: Image.memory(base64Decode(b64), fit: BoxFit.cover),
                  )
                else if (loading)
                  const Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: TwColors.primary),
                  )
                else
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 28, color: TwColors.muted),
                      const SizedBox(height: 6),
                      Text(
                        i == 0 ? 'Principal' : 'Opcional',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: TwColors.muted,
                        ),
                      ),
                    ],
                  ),
                if (b64 != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => _removePhoto(i),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPhotoViewer(BuildContext context, List<String> photos, int initial) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _PhotoViewerDialog(photos: photos, initialIndex: initial),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref,
      ProfileData profile, int totalChats) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: TwGradients.card,
        borderRadius: BorderRadius.circular(TwRadius.xxl),
        border: Border.all(color: TwColors.border),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: TwColors.primary, width: 3),
            ),
            child: profile.avatarUrl.isNotEmpty
                ? AvatarPreview(avatarUrl: profile.avatarUrl, size: 100)
                : CircleAvatar(
                    radius: 50,
                    backgroundColor: TwColors.surface,
                    child: Text(
                      profile.name.isNotEmpty
                          ? profile.name[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: TwColors.primary,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            profile.name,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: TwColors.onBg,
            ),
          ),
          if (profile.hobbies.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: profile.hobbies
                  .take(5)
                  .map((h) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: TwColors.surface,
                          borderRadius: BorderRadius.circular(TwRadius.pill),
                          border: Border.all(color: TwColors.border),
                        ),
                        child: Text(h,
                            style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                color: TwColors.onSurface)),
                      ))
                  .toList(),
            ),
            if (profile.hobbies.length > 5)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  '+${profile.hobbies.length - 5}',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 12, color: TwColors.muted),
                ),
              ),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatItem(
                icon: Icons.chat_bubble_outline,
                label: 'Conexoes',
                value: '$totalChats',
                color: TwColors.primary,
              ),
              Container(
                width: 1,
                height: 32,
                color: TwColors.border,
              ),
              _StatItem(
                icon: Icons.auto_awesome_outlined,
                label: 'Memorias',
                value: '--',
                color: const Color(0xFF6C5CE7),
              ),
              Container(
                width: 1,
                height: 32,
                color: TwColors.border,
              ),
              _StatItem(
                icon: Icons.psychology_outlined,
                label: 'Treino',
                value: profile.onboardingCompleted ? 'Feito' : 'Pendente',
                color: TwColors.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: TwColors.onBg)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 11, color: TwColors.muted)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.color = TwColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(TwRadius.xl),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(TwRadius.md),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: TwColors.onBg,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          color: TwColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: TwColors.muted),
              ],
            ),
          ),
        ),
    );
  }
}

class _PhotoViewerDialog extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;

  const _PhotoViewerDialog({required this.photos, required this.initialIndex});

  @override
  State<_PhotoViewerDialog> createState() => _PhotoViewerDialogState();
}

class _PhotoViewerDialogState extends State<_PhotoViewerDialog> {
  late final PageController _ctrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Stack(
        children: [
          PageView.builder(
            controller: _ctrl,
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => Center(
              child: InteractiveViewer(
                child: Image.memory(
                  base64Decode(widget.photos[i]),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
            ),
          ),
          if (widget.photos.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.photos.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _current == i ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _current == i ? Colors.white : Colors.white38,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: TwColors.error),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TwRadius.lg)),
        ),
        child: Text(
          'Sair da conta',
          style: GoogleFonts.spaceGrotesk(
            color: TwColors.error,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
