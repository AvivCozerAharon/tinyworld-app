import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tinyworld_app/core/theme/styles.dart';
import 'package:tinyworld_app/features/auth/auth_controller.dart';
import 'package:tinyworld_app/features/profile/profile_controller.dart';
import 'package:tinyworld_app/features/onboarding/widgets/avatar_preview.dart';
import 'package:tinyworld_app/shared/widgets/app_animations.dart';
import 'package:tinyworld_app/core/storage/local_storage.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text(state.error!))
              : _buildContent(context, ref, state.profile!),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, ProfileData profile) {
    return RefreshIndicator(
      color: TwColors.primary,
      onRefresh: () => ref.read(profileControllerProvider.notifier).loadProfile(),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          const SizedBox(height: 12),
          Center(
            child: profile.avatarUrl.isNotEmpty
                ? AvatarPreview(avatarUrl: profile.avatarUrl, size: 96)
                : CircleAvatar(
                    radius: 48,
                    backgroundColor: TwColors.card,
                    child: Text(
                      profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: TwColors.primary,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              profile.name,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: TwColors.onBg,
              ),
            ),
          ),
          if (profile.hobbies.isNotEmpty) ...[
            const SizedBox(height: 8),
            Center(
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: profile.hobbies
                    .map((h) => Chip(
                          label: Text(h,
                              style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12, color: TwColors.onBg)),
                          backgroundColor: TwColors.card,
                          side: const BorderSide(color: TwColors.border),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: 32),
          _SectionCard(
            title: 'Meu Cérebro',
            subtitle: 'Veja o que seu agente sabe sobre você',
            icon: Icons.auto_awesome_outlined,
            color: const Color(0xFF6C5CE7),
            onTap: () => context.go('/profile/brain'),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Treinar meu agente',
            subtitle: 'Responda perguntas para melhorar seus matches',
            icon: Icons.psychology_outlined,
            onTap: () => context.go('/profile/train'),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Configurações',
            subtitle: 'Editar nome, hobbies e preferências',
            icon: Icons.settings_outlined,
            onTap: () => context.go('/profile/edit'),
          ),
          const SizedBox(height: 32),
          _LogoutButton(
            onTap: () async {
              try {
                await ref.read(authControllerProvider.notifier).signOut();
              } catch (_) {
                await localStorage.clearAll();
              }
              if (context.mounted) context.go('/login');
            },
          ),
          const SizedBox(height: 24),
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
      child: Container(
        decoration: BoxDecoration(
          color: TwColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TwColors.border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
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
          side: const BorderSide(color: Color(0xFFFF6B6B)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          'Sair da conta',
          style: GoogleFonts.spaceGrotesk(
            color: const Color(0xFFFF6B6B),
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
