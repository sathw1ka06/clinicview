import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // <-- 1. Added dotenv import
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'core/colors.dart';
import 'providers/app_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/security_questions_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/main/main_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/upload/upload_screen.dart';

// <-- 2. Made main() async so it can wait for the file to load
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force it to tell us if the file load fails
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("🟢 SUCCESS: ENV file found. Contents: ${dotenv.env}");
  } catch (e) {
    debugPrint("🔴 CRITICAL FAILURE: Could not load .env file. Error: $e");
  }

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (context) => AppProvider())],
      child: const CliniviewApp(),
    ),
  );
}

class CliniviewApp extends StatelessWidget {
  const CliniviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Cliniview Workspace',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryButton,
          surface: AppColors.surface,
        ),
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme)
            .apply(
              bodyColor: AppColors.textPrimary,
              displayColor: AppColors.textPrimary,
            ),
      ),
      routerConfig: _router,
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/login',

  redirect: (context, state) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final loggedIn = provider.currentUser != null;

    final isAuthPage =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register' ||
        state.matchedLocation == '/security-questions';

    // Not logged in? Block protected pages.
    if (!loggedIn && !isAuthPage) {
      return '/login';
    }

    // Already logged in? Don't allow login/register pages.
    if (loggedIn && isAuthPage) {
      return '/home';
    }

    return null;
  },

  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/security-questions',
      builder: (context, state) => const SecurityQuestionsScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainScreen(child: child),
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/upload',
          builder: (context, state) => const UploadScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);
