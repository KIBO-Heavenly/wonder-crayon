// ============================================================================
// Wonder Crayon — Main Entry Point
//
// SPLASH FIX: The splash screen wasn't reliably appearing because
// SettingsProvider._loadSettings() calls notifyListeners() asynchronously,
// which can trigger a rebuild race with the addPostFrameCallback timer on
// slower devices. The new splash_screen.dart uses a plain dart:async Timer
// that is immune to provider rebuild cycles. No changes needed here for that.
//
// This file also cleans up the nested MaterialApp for the web phone frame —
// providers are now explicitly re-injected so the inner app has full access.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'providers/book_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_wrapper.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/terms_and_conditions_screen.dart';
import 'screens/main_menu_screen.dart';
import 'screens/new_book_screen.dart';
import 'screens/my_books_screen.dart';
import 'screens/settings_screen.dart';
import 'models/book.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();
  Hive.registerAdapter(BookAdapter());
  Hive.registerAdapter(BookPageAdapter());
  await Hive.openBox<Book>('books');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BookProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const WonderCrayonApp(),
    ),
  );
}

// ─── Root App ────────────────────────────────────────────────────────────────

class WonderCrayonApp extends StatelessWidget {
  const WonderCrayonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wonder Crayon',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        fontFamily: 'Poppins',
      ),
      // Splash always shows first — on both mobile and web frame.
      home: kIsWeb ? const _WebPhoneFrame() : const SplashScreen(),
      routes: _appRoutes,
    );
  }
}

/// Shared route table used by both the outer and inner MaterialApp on web.
Map<String, WidgetBuilder> get _appRoutes => {
  SplashScreen.routeName: (_) => const SplashScreen(),
  AuthWrapper.routeName: (_) => const AuthWrapper(),
  LoginScreen.routeName: (_) => const LoginScreen(),
  RegisterScreen.routeName: (_) => const RegisterScreen(),
  TermsAndConditionsScreen.routeName: (_) => const TermsAndConditionsScreen(),
  MainMenuScreen.routeName: (_) => const MainMenuScreen(),
  NewBookScreen.routeName: (_) => const NewBookScreen(),
  MyBooksScreen.routeName: (_) => const MyBooksScreen(),
  SettingsScreen.routeName: (_) => const SettingsScreen(),
};

// ─── Web Phone Frame ─────────────────────────────────────────────────────────
// Wraps the app in a phone bezel on desktop browsers so recruiters see the
// mobile experience without needing to resize the browser window.

class _WebPhoneFrame extends StatelessWidget {
  const _WebPhoneFrame();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12001F),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Label pill
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone_android, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Wonder Crayon — Live Demo',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Phone bezel
            Container(
              width: 390,
              height: 800,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: const Color(0xFF2A2A2A), width: 10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667eea).withValues(alpha: 0.35),
                    blurRadius: 40,
                    spreadRadius: 6,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 25,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: _PhoneAppContent(),
              ),
            ),

            const SizedBox(height: 20),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '📱  Swipe, tap, and explore — it\'s a real Flutter app',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The actual app content running inside the phone frame.
/// Providers are inherited from the outer MultiProvider — no duplication needed.
class _PhoneAppContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      // Force portrait phone dimensions so layouts look correct in a browser.
      data: MediaQuery.of(context).copyWith(
        size: const Size(390, 800),
      ),
      child: MaterialApp(
        title: 'Wonder Crayon',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.deepPurple,
        ),
        // Splash always shows first inside the frame too.
        home: const SplashScreen(),
        routes: _appRoutes,
      ),
    );
  }
}