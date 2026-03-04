//auth_service.dart
// ============================================================================
// Authentication Service — Real Firebase Implementation
//
// FIX:
//  userHasAcceptedTerms previously caught ALL exceptions and returned false,
//  meaning a user with no internet connection would be silently routed to the
//  Terms screen on every login even if they had already accepted. It now only
//  returns false for genuine "not accepted" cases. Network and Firestore
//  errors throw so the caller can handle them and show a proper message.
// ============================================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<User?> login(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  Future<User?> register(String email, String password) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final User? user = result.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'email': email.trim(),
          'hasAcceptedTerms': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred during registration. Please try again.';
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Error logging out. Please try again.';
    }
  }

  // FIX: Three distinct outcomes now:
  //   - true  → document exists and hasAcceptedTerms is true
  //   - false → document exists but not accepted, OR first-time user (doc created)
  //   - throws → network / Firestore failure so the caller can respond properly
  Future<bool> userHasAcceptedTerms(String uid) async {
    try {
      final DocumentSnapshot doc =
      await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        return data?['hasAcceptedTerms'] ?? false;
      }

      // First-time user — create their record and send them to Terms screen
      await _firestore.collection('users').doc(uid).set({
        'email': _auth.currentUser?.email ?? '',
        'hasAcceptedTerms': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return false;
    } on FirebaseException catch (e) {
      // Re-throw so callers (AuthWrapper, LoginScreen) can show an error
      // instead of silently misbehaving
      throw 'Could not verify terms acceptance: ${e.message ?? e.code}';
    }
  }

  Future<void> setTermsAccepted(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'email': _auth.currentUser?.email ?? '',
        'hasAcceptedTerms': true,
        'termsAcceptedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw 'Permission denied. Please check Firestore rules.';
      }
      throw 'Error updating terms: ${e.message}';
    } catch (e) {
      throw 'Error updating terms acceptance. Please try again.';
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password authentication is not enabled.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      default:
        return 'Authentication error: ${e.message ?? "Unknown error"}';
    }
  }
}