//auth_wrapper.dart
// ============================================================================
// Auth Wrapper — Routes based on Firebase auth state
//
// FIXES:
//  1. Converted to StatefulWidget so AuthService is instantiated once and
//     held for the widget's lifetime — not recreated on every rebuild.
//  2. The terms FutureBuilder now caches its Future in _termsFuture keyed
//     to the user's uid, so it does not re-fire every time the auth stream
//     emits a new event (e.g. token refresh), which previously caused
//     flickering.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'terms_and_conditions_screen.dart';
import 'main_menu_screen.dart';

class AuthWrapper extends StatefulWidget {
  static const routeName = '/auth-wrapper';

  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {

  // FIX 1: single instance, created once for this widget's lifetime
  final AuthService _authService = AuthService();

  // FIX 2: cache the future so FutureBuilder does not re-fire on every
  // auth stream emission for the same user
  String? _lastCheckedUid;
  Future<bool>? _termsFuture;

  Future<bool> _getTermsFuture(String uid) {
    if (_lastCheckedUid != uid || _termsFuture == null) {
      _lastCheckedUid = uid;
      _termsFuture = _authService.userHasAcceptedTerms(uid);
    }
    return _termsFuture!;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == null) {
          return const LoginScreen();
        }

        final user = snapshot.data!;

        return FutureBuilder<bool>(
          future: _getTermsFuture(user.uid),
          builder: (context, termsSnapshot) {
            if (termsSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final hasAcceptedTerms = termsSnapshot.data ?? false;

            if (hasAcceptedTerms) {
              return const MainMenuScreen();
            } else {
              return const TermsAndConditionsScreen();
            }
          },
        );
      },
    );
  }
}