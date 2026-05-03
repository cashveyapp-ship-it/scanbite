import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../models/user_profile.dart';
import '../utils/constants.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseService _firebaseService = FirebaseService();

  User? _user;
  UserProfile? _userProfile;
  bool _isLoading = false;
  bool _isLoadingProfile = false;
  String? _profileLoadError;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileStreamSub;

  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get profileLoadError => _profileLoadError;

  bool get isBootstrapping =>
      _isLoading || (_isLoadingProfile && _userProfile == null);

  bool get isReviewer {
    final email = _user?.email?.toLowerCase().trim();
    return email == 'review@scanbiteapp.com';
  }

  bool get hasPremiumAccess {
    if (isReviewer) return true;

    final p = _userProfile;
    if (p == null) return false;

    if (p.isSubscriptionActive) return true;

    if (p.familyPlanOwnerId != null && p.familyPlanOwnerId!.isNotEmpty) {
      return p.isPremium;
    }

    return false;
  }

  AuthProvider() {
    _authService.authStateChanges.listen((User? user) {
      print('🔄 Auth state changed: ${user?.uid ?? "null"}');
      _user = user;

      if (user == null) {
        _cancelProfileStream();
        _userProfile = null;
        _isLoadingProfile = false;
        _profileLoadError = null;
      } else {
        print('👤 User logged in, starting profile stream...');
        _profileLoadError = null;
        _startProfileStream();
      }

      notifyListeners();
    });
  }

  void _startProfileStream() {
    if (_user == null) return;

    _profileStreamSub?.cancel();

    _isLoadingProfile = true;
    _profileLoadError = null;
    notifyListeners();

    _profileStreamSub = FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .snapshots()
        .listen(
          (doc) async {
        try {
          if (!doc.exists || doc.data() == null) {
            print('⚠️ Profile missing for ${_user!.uid}, creating default profile...');

            final fallbackProfile = UserProfile(
              uid: _user!.uid,
              email: (_user!.email ?? '').trim().toLowerCase(),
              displayName: (_user!.displayName ?? 'User').trim(),
              createdAt: DateTime.now(),
              onboardingCompleted: false,
              isPremium: false,
              freeScansRemaining: AppConstants.freeScans,
              scanCredits: 0,
              subscriptionExpiryDate: null,
              isFamilyPlanOwner: false,
              familyMemberIds: const [],
              totalFamilyMembers: 1,
            );

            await _firebaseService.updateUserProfile(fallbackProfile);
            _userProfile = fallbackProfile;
          } else {
            final data = doc.data()!;
            _userProfile = UserProfile.fromMap(data).copyWith(uid: _user!.uid);

            if (_userProfile!.email.trim().isEmpty) {
              _userProfile = _userProfile!.copyWith(
                email: (_user!.email ?? '').trim().toLowerCase(),
              );
            }
          }

          _profileLoadError = null;
        } catch (e) {
          print('❌ Profile stream processing error: $e');
          _profileLoadError = e.toString();
        }

        _isLoadingProfile = false;
        notifyListeners();
      },
      onError: (e) {
        print('❌ Profile stream error: $e');
        _profileLoadError = e.toString();
        _isLoadingProfile = false;
        notifyListeners();
      },
    );
  }

  void _cancelProfileStream() {
    _profileStreamSub?.cancel();
    _profileStreamSub = null;
  }

  Future<void> loadUserProfile() async {
    _startProfileStream();
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('🔐 Signing in: $email');

      await _authService.signInWithEmailAndPassword(email, password);

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        print('👤 User confirmed: ${currentUser.uid}');
      }

      print('✅ Sign in complete');
    } catch (e) {
      print('❌ Sign in error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password, String displayName) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('📝 Signing up: $email');

      await _authService.signUpWithEmailAndPassword(
        email,
        password,
        displayName,
      );

      final createdUser = FirebaseAuth.instance.currentUser;
      if (createdUser == null) {
        throw Exception('Signup succeeded but user is null');
      }

      _user = createdUser;

      final defaultProfile = UserProfile(
        uid: createdUser.uid,
        email: (createdUser.email ?? email.trim()).trim().toLowerCase(),
        displayName: createdUser.displayName ?? displayName.trim(),
        createdAt: DateTime.now(),
        onboardingCompleted: false,
        isPremium: false,
        freeScansRemaining: AppConstants.freeScans,
        scanCredits: 0,
        subscriptionExpiryDate: null,
        isFamilyPlanOwner: false,
        familyMemberIds: const [],
        totalFamilyMembers: 1,
      );

      await _firebaseService.updateUserProfile(defaultProfile);
      _userProfile = defaultProfile;
      _profileLoadError = null;
      _startProfileStream();

      print('✅ Sign up complete');
    } catch (e) {
      print('❌ Sign up error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _cancelProfileStream();
      _user = null;
      _userProfile = null;
      _isLoadingProfile = false;
      _profileLoadError = null;
      notifyListeners();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  Future<void> updateProfile(UserProfile updatedProfile) async {
    print('💾 AuthProvider.updateProfile called');

    _userProfile = updatedProfile;
    notifyListeners();

    try {
      await _firebaseService.updateUserProfile(updatedProfile);
      print('✅ Profile update saved to Firestore');
    } catch (e) {
      final errorStr = e.toString();

      if (errorStr.contains('PERMISSION_DENIED')) {
        print('❌ CRITICAL: Permission denied');
        rethrow;
      }

      if (errorStr.contains('Channel shutdownNow') ||
          errorStr.contains('UNAVAILABLE') ||
          errorStr.contains('Unable to resolve host')) {
        print('⚠️ Connection interrupted, data queued for sync: $e');
        return;
      }

      print('⚠️ Profile update encountered error (kept local): $e');
    }
  }

  Future<void> resetPassword(String email) async {
    await _authService.resetPassword(email);
  }

  Future<void> refreshProfileIfNeeded() async {}

  Future<void> changePassword(String currentPassword, String newPassword) async {
    if (_user == null) throw Exception('No user logged in');

    try {
      final credential = EmailAuthProvider.credential(
        email: _user!.email!,
        password: currentPassword,
      );
      await _user!.reauthenticateWithCredential(credential);
      await _user!.updatePassword(newPassword);
    } catch (e) {
      if (e.toString().contains('wrong-password')) {
        throw Exception('Current password is incorrect');
      }
      throw Exception('Failed to change password');
    }
  }

  Future<void> deleteAccount(String password) async {
    if (_user == null) throw Exception('No user logged in');

    try {
      final credential = EmailAuthProvider.credential(
        email: _user!.email!,
        password: password,
      );
      await _user!.reauthenticateWithCredential(credential);
      await _firebaseService.deleteUserData(_user!.uid);
      await _user!.delete();

      _cancelProfileStream();
      _user = null;
      _userProfile = null;
      _isLoadingProfile = false;
      _profileLoadError = null;
      notifyListeners();
    } catch (e) {
      if (e.toString().contains('wrong-password')) {
        throw Exception('Password is incorrect');
      }
      throw Exception('Failed to delete account');
    }
  }

  Future<void> consumeOneScanIfNeeded() async {
    if (hasPremiumAccess) return;
    if (_user == null) return;

    const maxAttempts = 3;
    const retryDelays = [
      Duration(seconds: 1),
      Duration(seconds: 2),
    ];

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final updated =
        await _firebaseService.consumeOneScanAtomic(_user!.uid);
        _userProfile = updated;
        notifyListeners();
        print(
          '✅ Scan consumed (attempt $attempt) — free: ${updated.freeScansRemaining}, credits: ${updated.scanCredits}',
        );
        return;
      } catch (e) {
        final errorStr = e.toString();
        final isTransient = errorStr.contains('unavailable') ||
            errorStr.contains('UNAVAILABLE') ||
            errorStr.contains('Channel shutdownNow') ||
            errorStr.contains('Unable to resolve host');

        if (isTransient && attempt < maxAttempts) {
          print(
            '⚠️ consumeOneScanIfNeeded transient error (attempt $attempt/$maxAttempts), retrying in ${retryDelays[attempt - 1].inSeconds}s...',
          );
          await Future.delayed(retryDelays[attempt - 1]);
          continue;
        }

        print('❌ consumeOneScanIfNeeded failed after $attempt attempt(s): $e');
        rethrow;
      }
    }
  }

  bool canScan() {
    if (hasPremiumAccess) return true;

    final p = _userProfile;
    if (p == null) return false;

    return (p.freeScansRemaining + p.scanCredits) > 0;
  }

  int getScansRemaining() {
    final p = _userProfile;
    if (p == null) return 0;
    return p.freeScansRemaining + p.scanCredits;
  }
}