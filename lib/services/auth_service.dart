import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signUpWithEmailAndPassword(
      String email,
      String password,
      String displayName,
      ) async {
    try {
      print('Creating user account...');

      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;

      if (user != null) {
        await user.updateDisplayName(displayName);
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException in signUp: ${e.code} - ${e.message}');

      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The password is too weak';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account already exists with this email';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred during sign up';
      }

      throw Exception(errorMessage);
    } catch (e) {
      print('Error in signUp: $e');
      throw Exception('Failed to sign up: $e');
    }
  }

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      print('Signing in user...');

      final UserCredential result = await _auth
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('❌ Auth timeout after 15 seconds');
          throw TimeoutException('Login timed out');
        },
      );

      print('Sign in successful');
      return result.user;
    } on TimeoutException catch (e) {
      print('Timeout error: $e');
      throw Exception('Connection timeout. Please check your internet and try again.');
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException in signIn: ${e.code} - ${e.message}');

      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid email or password';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Check your internet connection.';
          break;
        default:
          errorMessage = e.message ?? 'Failed to sign in';
      }

      throw Exception(errorMessage);
    } catch (e) {
      print('Error in signIn: $e');
      throw Exception('Failed to sign in: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('User signed out successfully');
    } catch (e) {
      print('Error signing out: $e');
      throw Exception('Failed to sign out');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error sending password reset email: $e');
      throw Exception('Failed to send password reset email');
    }
  }
}