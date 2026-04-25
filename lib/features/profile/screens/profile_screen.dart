import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tinyworld_app/core/theme/styles.dart';
import 'package:tinyworld_app/features/auth/auth_controller.dart';
import 'package:tinyworld_app/features/chats/chats_controller.dart';
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
