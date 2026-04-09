import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tinyworld_app/core/storage/local_storage.dart';
import 'package:tinyworld_app/features/onboarding/screens/basic_info_screen.dart';
import 'package:tinyworld_app/features/onboarding/screens/liveness_screen.dart';
import 'package:tinyworld_app/features/onboarding/screens/avatar_screen.dart';
import 'package:tinyworld_app/features/onboarding/screens/hobbies_screen.dart';
import 'package:tinyworld_app/features/onboarding/screens/ai_chat_screen.dart';
import 'package:tinyworld_app/features/onboarding/screens/welcome_screen.dart';
import 'package:tinyworld_app/features/map/screens/map_screen.dart';
import 'package:tinyworld_app/features/chats/screens/chats_list_screen.dart';
import 'package:tinyworld_app/features/chats/screens/conversation_screen.dart';

final _router = GoRouter(
  redirect: (context, state) async {
    final done = await localStorage.isOnboardingDone();
    if (!done && !state.uri.path.startsWith('/onboarding')) {
      return '/onboarding/basic-info';
    }
    return null;
  },
  routes: [
    GoRoute(
        path: '/onboarding/basic-info',
        builder: (_, __) => const BasicInfoScreen()),
    GoRoute(
        path: '/onboarding/liveness',
        builder: (_, __) => const LivenessScreen()),
    GoRoute(
        path: '/onboarding/avatar',
        builder: (_, state) => AvatarScreen(extra: state.extra)),
    GoRoute(
        path: '/onboarding/hobbies',
        builder: (_, __) => const HobbiesScreen()),
    GoRoute(
        path: '/onboarding/chat',
        builder: (_, __) => const AiChatScreen()),
    GoRoute(
        path: '/onboarding/welcome',
        builder: (_, __) => const WelcomeScreen()),
    ShellRoute(
      builder: (_, __, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, __) => const MapScreen()),
        GoRoute(path: '/chats', builder: (_, __) => const ChatsListScreen()),
        GoRoute(
          path: '/chats/live/:otherUserId',
          builder: (_, state) => ConversationScreen(
              simId: state.pathParameters['otherUserId']!,
              isLive: true),
        ),
        GoRoute(
          path: '/chats/:simId',
          builder: (_, state) => ConversationScreen(
              simId: state.pathParameters['simId']!),
        ),
      ],
    ),
  ],
);

class TinyWorldApp extends StatelessWidget {
  const TinyWorldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TinyWorld',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          titleLarge: TextStyle(fontWeight: FontWeight.w700),
          bodyLarge: TextStyle(fontSize: 15, height: 1.5),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0.5,
        ),
        navigationBarTheme: NavigationBarThemeData(
          labelTextStyle: WidgetStatePropertyAll(
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          setState(() => _currentIndex = i);
          if (i == 0) context.go('/');
          if (i == 1) context.go('/chats');
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.map_outlined), label: 'Explorar'),
          NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline), label: 'Chats'),
        ],
      ),
    );
  }
}
