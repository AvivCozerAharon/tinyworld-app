import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tinyworld_app/core/storage/local_storage.dart';
import 'package:tinyworld_app/core/theme/styles.dart';
import 'package:tinyworld_app/features/auth/screens/login_screen.dart';
import 'package:tinyworld_app/features/onboarding/screens/liveness_screen.dart';
import 'package:tinyworld_app/features/onboarding/screens/avatar_screen.dart';
import 'package:tinyworld_app/features/onboarding/screens/hobbies_screen.dart';
import 'package:tinyworld_app/features/onboarding/screens/ai_chat_screen.dart';
import 'package:tinyworld_app/features/onboarding/screens/welcome_screen.dart';
import 'package:tinyworld_app/features/onboarding/screens/name_screen.dart';
import 'package:tinyworld_app/features/onboarding/screens/gender_screen.dart';
import 'package:tinyworld_app/features/onboarding/screens/birthdate_screen.dart';
import 'package:tinyworld_app/features/onboarding/screens/orientation_screen.dart';
import 'package:tinyworld_app/features/map/screens/map_screen.dart';
import 'package:tinyworld_app/features/chats/screens/chats_list_screen.dart';
import 'package:tinyworld_app/features/chats/screens/conversation_screen.dart';
import 'package:tinyworld_app/features/profile/screens/profile_screen.dart';
import 'package:tinyworld_app/features/profile/screens/train_agent_screen.dart';
import 'package:tinyworld_app/features/profile/screens/brain_screen.dart';
import 'package:tinyworld_app/features/profile/screens/edit_profile_screen.dart';
import 'package:tinyworld_app/features/companion/screens/companion_screen.dart';
import 'package:tinyworld_app/shared/widgets/app_animations.dart';

final _router = GoRouter(
  redirect: (context, state) {
    final done = LocalStorage.onboardingDone ?? false;
    final isLogin = state.uri.path == '/login';
    if (!done && !isLogin && !state.uri.path.startsWith('/onboarding')) {
      return '/login';
    }
    return null;
  },
  routes: [
    GoRoute(
        path: '/login',
        pageBuilder: (_, __) =>
            AppAnimations.pageTransition(child: const LoginScreen()),
        builder: (_, __) => const LoginScreen()),
    GoRoute(
        path: '/onboarding/basic-info',
        pageBuilder: (_, __) =>
            AppAnimations.pageTransition(child: const NameScreen()),
        builder: (_, __) => const NameScreen()),
    GoRoute(
        path: '/onboarding/gender',
        pageBuilder: (_, state) => AppAnimations.pageTransition(
            child: GenderScreen(name: state.extra as String)),
        builder: (_, state) => GenderScreen(name: state.extra as String)),
    GoRoute(
        path: '/onboarding/birthdate',
        pageBuilder: (_, state) {
          final e = state.extra as Map<String, String>;
          return AppAnimations.pageTransition(
              child: BirthDateScreen(name: e['name']!, gender: e['gender']!));
        },
        builder: (_, state) {
          final e = state.extra as Map<String, String>;
          return BirthDateScreen(name: e['name']!, gender: e['gender']!);
        }),
    GoRoute(
        path: '/onboarding/orientation',
        pageBuilder: (_, state) {
          final e = state.extra as Map<String, String>;
          return AppAnimations.pageTransition(
              child: OrientationScreen(
                  name: e['name']!,
                  gender: e['gender']!,
                  birthDate: e['birth_date']!));
        },
        builder: (_, state) {
          final e = state.extra as Map<String, String>;
          return OrientationScreen(
              name: e['name']!,
              gender: e['gender']!,
              birthDate: e['birth_date']!);
        }),
    GoRoute(
        path: '/onboarding/liveness',
        pageBuilder: (_, __) =>
            AppAnimations.pageTransition(child: const LivenessScreen()),
        builder: (_, __) => const LivenessScreen()),
    GoRoute(
        path: '/onboarding/avatar',
        pageBuilder: (_, __) =>
            AppAnimations.pageTransition(child: AvatarScreen(extra: __.extra)),
        builder: (_, state) => AvatarScreen(extra: state.extra)),
    GoRoute(
        path: '/onboarding/hobbies',
        pageBuilder: (_, __) =>
            AppAnimations.pageTransition(child: const HobbiesScreen()),
        builder: (_, __) => const HobbiesScreen()),
    GoRoute(
        path: '/onboarding/chat',
        pageBuilder: (_, __) =>
            AppAnimations.pageTransition(child: const AiChatScreen()),
        builder: (_, __) => const AiChatScreen()),
    GoRoute(
        path: '/onboarding/welcome',
        pageBuilder: (_, __) =>
            AppAnimations.pageTransition(child: const WelcomeScreen()),
        builder: (_, __) => const WelcomeScreen()),
    ShellRoute(
      builder: (_, __, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, __) => const MapScreen()),
        GoRoute(path: '/chats', builder: (_, __) => const ChatsListScreen()),
        GoRoute(
          path: '/chats/live/:otherUserId',
          pageBuilder: (_, state) => AppAnimations.pageTransition(
              child: ConversationScreen(
                  simId: state.pathParameters['otherUserId']!, isLive: true)),
          builder: (_, state) => ConversationScreen(
              simId: state.pathParameters['otherUserId']!, isLive: true),
        ),
        GoRoute(
          path: '/chats/:simId',
          pageBuilder: (_, state) => AppAnimations.pageTransition(
              child: ConversationScreen(simId: state.pathParameters['simId']!)),
          builder: (_, state) =>
              ConversationScreen(simId: state.pathParameters['simId']!),
        ),
        GoRoute(path: '/companion', builder: (_, __) => const CompanionScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        GoRoute(
            path: '/profile/train',
            pageBuilder: (_, __) =>
                AppAnimations.pageTransition(child: const TrainAgentScreen()),
            builder: (_, __) => const TrainAgentScreen()),
        GoRoute(
            path: '/profile/brain',
            pageBuilder: (_, __) =>
                AppAnimations.pageTransition(child: const BrainScreen()),
            builder: (_, __) => const BrainScreen()),
        GoRoute(
            path: '/profile/edit',
            pageBuilder: (_, __) =>
                AppAnimations.pageTransition(child: const EditProfileScreen()),
            builder: (_, __) => const EditProfileScreen()),
      ],
    ),
  ],
);

class TinyWorldApp extends StatelessWidget {
  const TinyWorldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'tinyworld',
      debugShowCheckedModeBanner: false,
      theme: TwTheme.dark,
      routerConfig: _router,
    );
  }
}

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/profile')) {
      _currentIndex = 3;
    } else if (location.startsWith('/companion')) {
      _currentIndex = 2;
    } else if (location.startsWith('/chats')) {
      _currentIndex = 1;
    } else {
      _currentIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: TwColors.surface,
          border: Border(
            top: BorderSide(color: TwColors.border, width: 0.5),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _NavButton(
                  icon: Icons.explore_outlined,
                  activeIcon: Icons.explore,
                  label: 'Explorar',
                  isActive: _currentIndex == 0,
                  onTap: () {
                    setState(() => _currentIndex = 0);
                    context.go('/');
                  },
                ),
                _NavButton(
                  icon: Icons.chat_bubble_outline,
                  activeIcon: Icons.chat_bubble,
                  label: 'Chats',
                  isActive: _currentIndex == 1,
                  onTap: () {
                    setState(() => _currentIndex = 1);
                    context.go('/chats');
                  },
                ),
                _NavButton(
                  icon: Icons.auto_awesome_outlined,
                  activeIcon: Icons.auto_awesome,
                  label: 'Tiny',
                  isActive: _currentIndex == 2,
                  onTap: () {
                    setState(() => _currentIndex = 2);
                    context.go('/companion');
                  },
                ),
                _NavButton(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Perfil',
                  isActive: _currentIndex == 3,
                  onTap: () {
                    setState(() => _currentIndex = 3);
                    context.go('/profile');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                decoration: BoxDecoration(
                  gradient: isActive ? TwGradients.primary : null,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconTheme(
                  data: IconThemeData(
                    color: isActive ? Colors.white : TwColors.muted,
                  ),
                  child: AnimatedNavIcon(
                    icon: icon,
                    activeIcon: activeIcon,
                    isActive: isActive,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? TwColors.primary : TwColors.muted,
                ),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
