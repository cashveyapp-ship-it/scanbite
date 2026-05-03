import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class FamilyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate unique 6-character family code
  String _generateFamilyCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No confusing chars
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  // ✅ Helper: compute max members = base(5) + extra slots
  int _getMaxMembersFromOwnerData(Map<String, dynamic> ownerData) {
    final extraSlots = ((ownerData['extraMemberSlots'] ?? 0) as num).toInt();
    return AppConstants.familyMaxMembers + extraSlots;
  }

  // ✅ Optional helper for UI / refresh
  Future<Map<String, dynamic>> getFamilyCapacity(String ownerId) async {
    final ownerDoc = await _firestore.collection('users').doc(ownerId).get();
    if (!ownerDoc.exists) {
      return {
        'maxMembers': AppConstants.familyMaxMembers,
        'extraMemberSlots': 0,
        'totalFamilyMembers': 0,
      };
    }

    final data = ownerDoc.data()!;
    final extraSlots = ((data['extraMemberSlots'] ?? 0) as num).toInt();
    final total = ((data['totalFamilyMembers'] ?? 0) as num).toInt();

    return {
      'maxMembers': AppConstants.familyMaxMembers + extraSlots,
      'extraMemberSlots': extraSlots,
      'totalFamilyMembers': total,
    };
  }

  // Create family plan when user subscribes
  Future<String> createFamilyPlan(String ownerId) async {
    try {
      String familyCode = _generateFamilyCode();

      // Make sure code is unique
      bool codeExists = true;
      while (codeExists) {
        final snapshot = await _firestore
            .collection('users')
            .where('familyCode', isEqualTo: familyCode)
            .limit(1)
            .get();

        if (snapshot.docs.isEmpty) {
          codeExists = false;
        } else {
          familyCode = _generateFamilyCode();
        }
      }

      await _firestore.collection('users').doc(ownerId).update({
        'isFamilyPlanOwner': true,
        'familyCode': familyCode,
        'familyPlanOwnerId': ownerId,
        'familyMemberIds': [ownerId],
        'totalFamilyMembers': 1,
        // ✅ FIX: set isPremium on owner so isSubscriptionActive getter works
        'isPremium': true,
        'isSubscriptionActive': true,
        'extraMemberSlots': 0,
        'extraMemberCost': 0.0,
      });

      print('✅ Family plan created with code: $familyCode');
      return familyCode;
    } catch (e) {
      print('❌ Error creating family plan: $e');
      throw Exception('Failed to create family plan: $e');
    }
  }

  // ✅ Call this AFTER $1.00 "extra slot" purchase succeeds
  Future<void> addExtraMemberSlot(String ownerId, {int quantity = 1}) async {
    try {
      final ownerRef = _firestore.collection('users').doc(ownerId);

      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(ownerRef);
        if (!snap.exists) throw Exception('Owner profile not found');

        final data = snap.data() as Map<String, dynamic>;
        final currentSlots = ((data['extraMemberSlots'] ?? 0) as num).toInt();
        final newSlots = currentSlots + quantity;

        tx.update(ownerRef, {
          'extraMemberSlots': newSlots,
          'extraMemberCost': newSlots * AppConstants.familyExtraMemberPrice,
        });
      });

      print('✅ Extra member slot(s) added for owner: $ownerId');
    } catch (e) {
      print('❌ Error adding extra member slot: $e');
      rethrow;
    }
  }

  // Join existing family plan
  Future<bool> joinFamilyPlan(String userId, String familyCode) async {
    try {
      final codeUpper = familyCode.toUpperCase();

      // Find the family plan owner by code
      final ownerSnapshot = await _firestore
          .collection('users')
          .where('familyCode', isEqualTo: codeUpper)
          .where('isFamilyPlanOwner', isEqualTo: true)
          .limit(1)
          .get();

      if (ownerSnapshot.docs.isEmpty) {
        throw Exception('Invalid family code');
      }

      final ownerDoc = ownerSnapshot.docs.first;
      final ownerId = ownerDoc.id;
      final ownerData = ownerDoc.data();

      final currentMembers = List<String>.from(ownerData['familyMemberIds'] ?? []);

      // Check if already member
      if (currentMembers.contains(userId)) {
        throw Exception('You are already part of this family plan');
      }

      // Check subscription active / expiry
      final expiryTimestamp = ownerData['subscriptionExpiryDate'] as Timestamp?;
      final expiryDate = expiryTimestamp?.toDate();
      if (expiryDate != null && expiryDate.isBefore(DateTime.now())) {
        throw Exception('This family plan has expired');
      }

      // ✅ Enforce capacity (base 5 + extra slots)
      final maxMembers = _getMaxMembersFromOwnerData(ownerData);
      if (currentMembers.length >= maxMembers) {
        throw Exception('Family is full. Ask the owner to buy an extra member slot.');
      }

      // ✅ Transaction to avoid race conditions
      final ownerRef = _firestore.collection('users').doc(ownerId);
      final memberRef = _firestore.collection('users').doc(userId);

      await _firestore.runTransaction((tx) async {
        final ownerSnap = await tx.get(ownerRef);
        if (!ownerSnap.exists) throw Exception('Owner not found');

        final freshOwnerData = ownerSnap.data() as Map<String, dynamic>;
        final freshMembers = List<String>.from(freshOwnerData['familyMemberIds'] ?? []);
        final freshMax = _getMaxMembersFromOwnerData(freshOwnerData);

        if (freshMembers.contains(userId)) {
          throw Exception('You are already part of this family plan');
        }
        if (freshMembers.length >= freshMax) {
          throw Exception('Family is full. Ask the owner to buy an extra member slot.');
        }

        freshMembers.add(userId);

        final extraSlots = ((freshOwnerData['extraMemberSlots'] ?? 0) as num).toInt();

        tx.update(ownerRef, {
          'familyMemberIds': freshMembers,
          'totalFamilyMembers': freshMembers.length,
          'extraMemberCost': extraSlots * AppConstants.familyExtraMemberPrice,
        });

        tx.update(memberRef, {
          'isFamilyPlanOwner': false,
          'familyCode': codeUpper,
          'familyPlanOwnerId': ownerId,
          // ✅ FIX: isPremium must be true so isSubscriptionActive getter returns true.
          // Previously only 'isSubscriptionActive' was written — but that field is
          // ignored on read. The getter checks isPremium first.
          'isPremium': true,
          'isSubscriptionActive': true,
          // ✅ FIX: store as Timestamp, not raw DateTime (Firestore rejects DateTime)
          'subscriptionExpiryDate': expiryTimestamp,
        });
      });

      // ✅ IMPORTANT: Notification must be AFTER the transaction
      await _notifyOwnerMemberJoined(
        ownerId: ownerId,
        memberId: userId,
        familyCode: codeUpper,
      );

      print('✅ User $userId joined family plan $codeUpper');
      return true;
    } catch (e) {
      print('❌ Error joining family: $e');
      rethrow;
    }
  }

  // Leave family plan
  Future<void> leaveFamilyPlan(String userId, String ownerId) async {
    try {
      final ownerRef = _firestore.collection('users').doc(ownerId);
      final memberRef = _firestore.collection('users').doc(userId);

      await _firestore.runTransaction((tx) async {
        final ownerSnap = await tx.get(ownerRef);
        if (!ownerSnap.exists) throw Exception('Owner not found');

        final ownerData = ownerSnap.data() as Map<String, dynamic>;
        final currentMembers = List<String>.from(ownerData['familyMemberIds'] ?? []);

        currentMembers.remove(userId);

        final extraSlots = ((ownerData['extraMemberSlots'] ?? 0) as num).toInt();

        tx.update(ownerRef, {
          'familyMemberIds': currentMembers,
          'totalFamilyMembers': currentMembers.length,
          'extraMemberCost': extraSlots * AppConstants.familyExtraMemberPrice,
        });

        tx.update(memberRef, {
          'isFamilyPlanOwner': false,
          'familyCode': null,
          'familyPlanOwnerId': null,
          // ✅ FIX: clear isPremium so isSubscriptionActive getter returns false
          'isPremium': false,
          'isSubscriptionActive': false,
          'subscriptionExpiryDate': null,
        });
      });

      print('✅ User $userId left family plan');
    } catch (e) {
      print('❌ Error leaving family: $e');
      throw Exception('Failed to leave family plan: $e');
    }
  }

  // Remove member (only owner can do this)
  Future<void> removeFamilyMember(String ownerId, String memberIdToRemove) async {
    try {
      await leaveFamilyPlan(memberIdToRemove, ownerId);
      print('✅ Member removed from family plan');
    } catch (e) {
      print('❌ Error removing member: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────
  // CASCADE REVOKE
  // Call this whenever the OWNER's subscription is revoked or expires.
  // Strips premium from every member instantly — their real-time
  // Firestore stream (auth_provider.dart) picks up the change within ~1s.
  // ─────────────────────────────────────────────────────────

  /// Revokes premium from the owner AND all family members in one batch write.
  /// Call this from admin_screen when revoking, and from subscription_service
  /// when a subscription lapses.
  Future<void> revokeFamilyPlan(String ownerId) async {
    try {
      final ownerDoc = await _firestore.collection('users').doc(ownerId).get();

      if (!ownerDoc.exists) {
        print('⚠️ revokeFamilyPlan: owner doc not found for $ownerId');
        return;
      }

      final ownerData = ownerDoc.data()!;
      final bool isOwner = ownerData['isFamilyPlanOwner'] == true;

      // If this user isn't a family plan owner, nothing to cascade
      if (!isOwner) {
        print('ℹ️ revokeFamilyPlan: $ownerId is not a family plan owner, skipping cascade');
        return;
      }

      final memberIds = List<String>.from(ownerData['familyMemberIds'] ?? []);

      // Firestore batches support up to 500 writes — more than enough for family plans
      final batch = _firestore.batch();

      final expiryYesterday = Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 1)),
      );

      // Strip premium from every member (excluding the owner — handled separately
      // by updateSubscription in firebase_service)
      for (final memberId in memberIds) {
        if (memberId == ownerId) continue; // Owner handled by updateSubscription

        final memberRef = _firestore.collection('users').doc(memberId);
        batch.update(memberRef, {
          'isPremium': false,
          'isSubscriptionActive': false,
          'subscriptionExpiryDate': expiryYesterday,
          // Keep familyCode/familyPlanOwnerId intact so they know which plan they were on
          // They can rejoin if the owner renews
        });
      }

      await batch.commit();

      print('✅ revokeFamilyPlan: premium revoked from ${memberIds.length - 1} member(s) under owner $ownerId');
    } catch (e) {
      print('❌ revokeFamilyPlan error: $e');
      throw Exception('Failed to revoke family plan: $e');
    }
  }

  /// Re-grants premium to all current family members when owner renews/is granted access.
  /// Mirrors revokeFamilyPlan — call this from admin_screen on Grant and from
  /// subscription_service when a new subscription is activated.
  Future<void> restoreFamilyPlan(String ownerId, DateTime expiryDate) async {
    try {
      final ownerDoc = await _firestore.collection('users').doc(ownerId).get();

      if (!ownerDoc.exists) {
        print('⚠️ restoreFamilyPlan: owner doc not found for $ownerId');
        return;
      }

      final ownerData = ownerDoc.data()!;
      final bool isOwner = ownerData['isFamilyPlanOwner'] == true;

      if (!isOwner) {
        print('ℹ️ restoreFamilyPlan: $ownerId is not a family plan owner, skipping');
        return;
      }

      final memberIds = List<String>.from(ownerData['familyMemberIds'] ?? []);
      final expiryTimestamp = Timestamp.fromDate(expiryDate);

      final batch = _firestore.batch();

      for (final memberId in memberIds) {
        if (memberId == ownerId) continue; // Owner handled by updateSubscription

        final memberRef = _firestore.collection('users').doc(memberId);
        batch.update(memberRef, {
          'isPremium': true,
          'isSubscriptionActive': true,
          'subscriptionExpiryDate': expiryTimestamp,
        });
      }

      await batch.commit();

      print('✅ restoreFamilyPlan: premium restored for ${memberIds.length - 1} member(s) under owner $ownerId');
    } catch (e) {
      print('❌ restoreFamilyPlan error: $e');
      throw Exception('Failed to restore family plan: $e');
    }
  }

  // Get family members list
  Future<List<Map<String, dynamic>>> getFamilyMembers(String ownerId) async {
    try {
      final ownerDoc = await _firestore.collection('users').doc(ownerId).get();
      final memberIds = List<String>.from(ownerDoc.data()?['familyMemberIds'] ?? []);

      final List<Map<String, dynamic>> members = [];

      for (String memberId in memberIds) {
        final memberDoc = await _firestore.collection('users').doc(memberId).get();
        if (memberDoc.exists) {
          members.add({
            'uid': memberId,
            'displayName': memberDoc.data()?['displayName'] ?? 'Unknown',
            'email': memberDoc.data()?['email'] ?? '',
            'isOwner': memberId == ownerId,
          });
        }
      }

      return members;
    } catch (e) {
      print('❌ Error getting family members: $e');
      return [];
    }
  }

  /// ✅ Retrieve an existing family code for a user (owner/member)
  Future<String?> getExistingFamilyCode(String userId) async {
    final uid = userId.trim();
    if (uid.isEmpty) return null;

    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null) return null;

    final code = (data['familyCode'] as String?)?.trim();
    if (code == null || code.isEmpty) return null;

    return code;
  }

  Future<void> _notifyOwnerMemberJoined({
    required String ownerId,
    required String memberId,
    required String familyCode,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(ownerId)
          .collection('notifications')
          .add({
        'type': 'family_member_joined',
        'title': 'New Family Member Added',
        'message': 'A new member joined your family plan.',
        'memberId': memberId,
        'familyCode': familyCode,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      print('✅ Owner notified (Firestore notification doc created)');
    } catch (e) {
      print('⚠️ Failed to write owner notification: $e');
    }
  }

  // Calculate monthly cost including extra slots (NOT based on member count)
  double calculateMonthlyCost(int totalMembers, bool isYearly) {
    final baseCost = isYearly
        ? AppConstants.familyYearlyPrice / 12
        : AppConstants.familyMonthlyPrice;

    return baseCost;
  }
}