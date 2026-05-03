import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/user_profile.dart';
import '../models/food_scan.dart';
import '../utils/constants.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/foundation.dart';

/// ✅ FIXED: Handles connection lifecycle and channel shutdowns gracefully
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;

  FirebaseService._internal() {
    print('🔥 FirebaseService singleton initialized');
    _configureFirestore();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Configure Firestore for better connection handling
  void _configureFirestore() {
    try {
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      print('✅ [FIREBASE] Persistence configured');
    } catch (e) {
      // Settings already set — safe to ignore
      print('⚠️ [FIREBASE] Settings already configured: $e');
    }
  }

  // Upload scan image with compression
  Future<String> uploadScanImage(File imageFile, String userId) async {
    try {
      if (kDebugMode) {
        print('📤 Starting upload for user: $userId');
      }

      final compressedBytes = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        quality: 55,
        minWidth: 768,
        minHeight: 768,
        format: CompressFormat.jpeg,
      );

      if (compressedBytes == null) {
        throw Exception('Failed to compress image');
      }

      print('📦 Compressed size: ${compressedBytes.length} bytes');

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('scans/$userId/$fileName');

      await ref
          .putData(
        compressedBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      )
          .timeout(const Duration(seconds: 12));

      final downloadUrl = await ref.getDownloadURL().timeout(
        const Duration(seconds: 8),
      );

      print('✅ Upload complete: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Upload error: $e');

      if (e.toString().contains('unauthorized') ||
          e.toString().contains('permission')) {
        throw Exception(
            'Storage permission denied. Please check Firebase Storage rules.');
      }

      rethrow;
    }
  }

  // Save scan to Firestore
  Future<void> saveScan(FoodScan scan) async {
    try {
      print('Saving scan to Firestore: ${scan.id}');

      await _firestore
          .collection(AppConstants.scansCollection)
          .doc(scan.id)
          .set(scan.toMap());

      print('Scan saved successfully');
    } catch (e) {
      print('Error saving scan: $e');
      throw Exception('Failed to save scan: $e');
    }
  }

  // Get user scans stream
  Stream<List<FoodScan>> getUserScans(String userId) {
    return _firestore
        .collection(AppConstants.scansCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('scannedAt', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) {
      final scans = <FoodScan>[];

      for (final doc in snapshot.docs) {
        try {
          scans.add(FoodScan.fromMap(doc.data(), doc.id));
        } catch (_) {}
      }

      return scans;
    });
  }



  Future<void> deleteScan(String scanId) async {
    try {
      await _firestore
          .collection(AppConstants.scansCollection)
          .doc(scanId)
          .delete();
    } catch (e) {
      print('Error deleting scan: $e');
      throw Exception('Failed to delete scan: $e');
    }
  }

  Future<void> consumeScanCredit(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'scanCredits': FieldValue.increment(-1),
    });
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final uid = userId.trim();
      if (uid.isEmpty) {
        print('getUserProfile skipped: userId is empty');
        return null;
      }

      print('🔥 [FIREBASE] Loading profile for: $uid');

      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (!doc.exists) {
        print('⚠️ [FIREBASE] Profile document does not exist');
        return null;
      }

      final data = doc.data();
      if (data == null) {
        print('⚠️ [FIREBASE] Profile data is null');
        return null;
      }

      print('✅ [FIREBASE] Profile loaded successfully');
      print('   - Age: ${data['age']}');
      print('   - Gender: ${data['gender']}');
      print('   - Height: ${data['height']}');
      print('   - Weight: ${data['weight']}');
      print('   - BMI: ${data['bmi']}');

      return UserProfile.fromMap(data).copyWith(uid: uid);
    } catch (e) {
      print('❌ [FIREBASE] Error loading profile: $e');
      return null;
    }
  }

  /// ✅ UPDATED: Offline-safe write (no server verification), graceful error handling
  Future<void> updateUserProfile(UserProfile profile) async {
    final uid = profile.uid.trim();
    if (uid.isEmpty) {
      throw Exception('User UID is empty.');
    }

    print('💾 [FIREBASE] === UPDATE PROFILE START ===');
    print('   User ID: $uid');
    print('   Age: ${profile.age}');
    print('   Gender: ${profile.gender}');
    print('   Height: ${profile.height}');
    print('   Weight: ${profile.weight}');
    print('   BMI: ${profile.bmi}');

    final profileMap = profile.toUpdateMap();
    final docRef = _firestore.collection(AppConstants.usersCollection).doc(uid);

    try {
      await docRef.set(profileMap, SetOptions(merge: true));
      print('✅ [FIREBASE] Profile saved successfully');
    } catch (e) {
      final errorStr = e.toString();

      if (errorStr.contains('PERMISSION_DENIED')) {
        print('❌ [FIREBASE] Permission denied: $e');
        throw Exception('Permission denied. Check Firestore security rules.');
      }

      if (errorStr.contains('Channel shutdownNow') ||
          errorStr.contains('UNAVAILABLE') ||
          errorStr.contains('Unable to resolve host') ||
          errorStr.contains('UnknownHostException') ||
          errorStr.contains('network')) {
        print('⚠️ [FIREBASE] Offline — write queued for sync: $e');
        return;
      }

      print('❌ [FIREBASE] Unexpected error: $e');
      throw Exception('Failed to save profile: $e');
    }
  }

  // AFTER — uses FieldValue.increment which works offline
  Future<UserProfile> consumeOneScanAtomic(String userId) async {
    final uid = userId.trim();
    if (uid.isEmpty) throw Exception('User UID is empty.');

    final docRef = _firestore.collection(AppConstants.usersCollection).doc(uid);

    Future<UserProfile> attempt() {
      return _firestore.runTransaction((tx) async {
        final snap = await tx.get(docRef);

        if (!snap.exists) {
          throw Exception('User profile missing for $uid');
        }

        final data = (snap.data() as Map<String, dynamic>?) ?? {};

        final int free = (data['freeScansRemaining'] ?? AppConstants.freeScans) is int
            ? (data['freeScansRemaining'] ?? AppConstants.freeScans) as int
            : AppConstants.freeScans;

        final int credits = (data['scanCredits'] ?? 0) is int
            ? (data['scanCredits'] ?? 0) as int
            : 0;

        if (free <= 0 && credits <= 0) {
          throw Exception('No scans remaining');
        }

        final int newFree = free > 0 ? free - 1 : free;
        final int newCredits = free > 0 ? credits : credits - 1;

        tx.update(docRef, {
          'freeScansRemaining': newFree,
          'scanCredits': newCredits,
        });

        final merged = <String, dynamic>{
          ...data,
          'freeScansRemaining': newFree,
          'scanCredits': newCredits,
        };

        return UserProfile.fromMap(merged).copyWith(uid: uid);
      });
    }

    try {
      return await attempt();
    } catch (e) {
      final errorStr = e.toString();

      if (errorStr.contains('cloud_firestore/unavailable') ||
          errorStr.contains('UNAVAILABLE') ||
          errorStr.contains('Channel shutdownNow') ||
          errorStr.contains('Unable to resolve host') ||
          errorStr.contains('UnknownHostException') ||
          errorStr.contains('network')) {
        print('⚠️ Retrying consumeOneScanAtomic after transient Firestore error: $e');
        await Future.delayed(const Duration(milliseconds: 700));
        return await attempt();
      }

      rethrow;
    }
  }

  Future<void> updateSubscription(
      String userId,
      bool isPremium,
      DateTime? expiryDate,
      ) async {
    try {
      final uid = userId.trim();
      if (uid.isEmpty) {
        throw Exception('Cannot update subscription: userId is empty');
      }

      await _firestore.collection(AppConstants.usersCollection).doc(uid).set({
        'isPremium': isPremium,
        'subscriptionExpiryDate':
        expiryDate != null ? Timestamp.fromDate(expiryDate) : null,
      }, SetOptions(merge: true));

      print('✅ Subscription updated for user: $uid');
    } catch (e) {
      print('❌ Error updating subscription: $e');
      throw Exception('Failed to update subscription: $e');
    }
  }



  Future<void> deleteUserData(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();

      final scans = await _firestore
          .collection('scans')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in scans.docs) {
        await doc.reference.delete();
      }

      await _firestore.collection('subscriptions').doc(userId).delete();

      print('User data deleted for: $userId');
    } catch (e) {
      print('Error deleting user data: $e');
      throw Exception('Failed to delete user data');
    }
  }

  Future<String> resolveImageUrl(String imageUrl) async {
    final url = imageUrl.trim().replaceAll('\\', '/');
    if (url.isEmpty) return '';

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    if (url.startsWith('gs://')) {
      try {
        final ref = _storage.refFromURL(url);
        return await ref.getDownloadURL();
      } catch (e) {
        print('❌ [FIREBASE] resolveImageUrl failed for gs:// url: $e');
        return '';
      }
    }

    if (url.startsWith('scans/')) {
      try {
        final ref = _storage.ref().child(url);
        return await ref.getDownloadURL();
      } catch (e) {
        print('❌ [FIREBASE] resolveImageUrl failed for path url: $e');
        return '';
      }
    }

    return '';
  }

  Future<void> addExtraFamilyMemberSlot(String ownerId) async {
    // FIXED — must match family_service.dart which uses users collection
    final docRef = _firestore.collection('users').doc(ownerId); // CORRECT


    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(docRef);

      if (!snap.exists) {
        tx.set(docRef, {
          'ownerId': ownerId,
          'baseMaxMembers': AppConstants.familyMaxMembers,
          'extraMemberSlots': 1,
          'memberIds': [ownerId],
          'planActive': true,
          'planExpiry': null,
        }, SetOptions(merge: true));
        return;
      }

      final data = snap.data() as Map<String, dynamic>;
      final current = (data['extraMemberSlots'] ?? 0) as int;

      tx.update(docRef, {'extraMemberSlots': current + 1});
    });
  }

  Future<void> updateScanImageUrl(String scanId, String imageUrl) async {
    try {
      await _firestore.collection(AppConstants.scansCollection).doc(scanId).update({
        'imageUrl': imageUrl,
      });
      print('✅ Scan imageUrl updated for scanId=$scanId');
    } catch (e) {
      print('❌ Failed to update scan imageUrl: $e');
    }
  }

  Future<int> getFamilyMaxMembers(String ownerId) async {
    // Also in getFamilyMaxMembers():
    final doc = await _firestore.collection('users').doc(ownerId).get(); // CORRECT

    if (!doc.exists) return AppConstants.familyMaxMembers;

    final data = doc.data()!;
    final baseMax =
    (data['baseMaxMembers'] ?? AppConstants.familyMaxMembers) as int;
    final extra = (data['extraMemberSlots'] ?? 0) as int;
    return baseMax + extra;
  }
}