import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tinyworld_app/core/storage/local_storage.dart';
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

  static const _twBlue = Color(0xFF1B76F2);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'tinyworld',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _twBlue,
          brightness: Brightness.light,
          primary: _twBlue,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFAFDFB),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            height: 1.15,
          ),
          headlineMedium: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            height: 1.2,
          ),
          titleLarge:
              TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.02),
          bodyLarge: TextStyle(fontSize: 15, height: 1.6),
          bodyMedium: TextStyle(fontSize: 14, height: 1.5),
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _twBlue,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF1A1A2E),
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: _twBlue.withValues(alpha: 0.1),
          labelTextStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ),
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
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
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
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Perfil',
                  isActive: _currentIndex == 2,
                  onTap: () {
                    setState(() => _currentIndex = 2);
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
                  color: isActive
                      ? const Color(0xFF1B76F2).withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: AnimatedNavIcon(
                  icon: icon,
                  activeIcon: activeIcon,
                  isActive: isActive,
                  size: 24,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? const Color(0xFF1B76F2)
                      : const Color(0xFF9CA3AF),
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
