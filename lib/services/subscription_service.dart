// subscription_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'family_service.dart';
import 'firebase_service.dart';
import '../utils/constants.dart';

class SubscriptionService {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final FirebaseService _firebaseService = FirebaseService();
  final FamilyService _familyService = FamilyService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Product IDs
  static const String monthlySubscriptionId = 'scanbite_premium_monthly';
  static const String yearlySubscriptionId = 'scanbite_premium_yearly';
  static const String familyMonthlySubscriptionId = 'scanbite_family_monthly';
  static const String familyYearlySubscriptionId = 'scanbite_family_yearly';
  static const String familyExtraMemberId = 'scanbite_family_extra_member';
  static const String singleScanProductId = 'scanbite_single_scan';

  static const Set<String> _productIds = {
    monthlySubscriptionId,
    yearlySubscriptionId,
    familyMonthlySubscriptionId,
    familyYearlySubscriptionId,
    familyExtraMemberId,
    singleScanProductId,
  };

  String? _currentUserId;
  VoidCallback? _onPurchaseSuccess;
  Function(String)? _onPurchaseError;

  Future<void> initialize({
    required String userId,
    VoidCallback? onSuccess,
    Function(String)? onError,
  }) async {
    _currentUserId = userId;
    _onPurchaseSuccess = onSuccess;
    _onPurchaseError = onError;


    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;

    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) {
        print('Purchase stream error: $error');
        _onPurchaseError?.call('Purchase stream error: $error');
      },
    );

    // âœ… Check for expired subscriptions every time the service initializes
    // (i.e. on every app launch and after sign-in)
    await checkAndHandleExpiry(userId);
  }

  Future<bool> isAvailable() async => await _inAppPurchase.isAvailable();

  Future<List<ProductDetails>> getProducts() async {
    try {
      final bool available = await _inAppPurchase.isAvailable();
      if (!available) {
        print('Store not available');
        return [];
      }

      final ProductDetailsResponse response =
      await _inAppPurchase.queryProductDetails(_productIds);

      if (response.notFoundIDs.isNotEmpty) {
        print('Products not found: ${response.notFoundIDs}');
      }
      if (response.error != null) {
        print('Error getting products: ${response.error}');
        return [];
      }

      print('Found ${response.productDetails.length} products');
      return response.productDetails;
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  // âœ… UPDATED: use buyConsumable for one-time products
  Future<bool> purchaseSubscription(ProductDetails product) async {
    try {
      print('Initiating purchase for: ${product.id}');

      final PurchaseParam purchaseParam =
      PurchaseParam(productDetails: product);

      final isConsumable =
          product.id == singleScanProductId || product.id == familyExtraMemberId;

      final bool success = isConsumable
          ? await _inAppPurchase.buyConsumable(
        purchaseParam: purchaseParam,
        autoConsume: true,
      )
          : await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      if (!success) {
        print('Purchase initiation failed');
        _onPurchaseError?.call('Failed to initiate purchase');
      }
      return success;
    } catch (e) {
      print('Error purchasing subscription: $e');
      _onPurchaseError?.call('Error: $e');
      return false;
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      print('Purchase status: ${purchaseDetails.status}');

      if (purchaseDetails.status == PurchaseStatus.pending) {
        print('Purchase pending...');
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        print('Purchase error: ${purchaseDetails.error}');
        _onPurchaseError?.call(
            purchaseDetails.error?.message ?? 'Payment failed');
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        await _verifyAndDeliverProduct(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        print('Purchase canceled by user');
        _onPurchaseError?.call('Payment canceled');
      }

      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  Future<void> _verifyAndDeliverProduct(PurchaseDetails purchaseDetails) async {
    try {
      print('âœ… [PURCHASE] Verifying: ${purchaseDetails.productID}');

      if (_currentUserId == null) {
        print('âŒ [PURCHASE] No user ID set');
        _onPurchaseError?.call('User not logged in');
        return;
      }

      // â”€â”€â”€ Single Scan â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      if (purchaseDetails.productID == singleScanProductId) {
        print('ðŸ’³ [PURCHASE] Single scan purchase');
        await _firestore.collection('users').doc(_currentUserId!).set({
          'scanCredits': FieldValue.increment(1),
        }, SetOptions(merge: true));
        print('âœ… [PURCHASE] 1 scan credit added');
        _onPurchaseSuccess?.call();
        return;
      }

      // â”€â”€â”€ Extra Family Member Slot â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      if (purchaseDetails.productID == familyExtraMemberId) {
        print('ðŸ’³ [PURCHASE] Extra family member slot');
        await _firestore.collection('users').doc(_currentUserId!).set({
          'extraMemberSlots': FieldValue.increment(1),
        }, SetOptions(merge: true));
        print('âœ… [PURCHASE] Extra slot added');
        _onPurchaseSuccess?.call();
        return;
      }

      // â”€â”€â”€ Monthly Individual Subscription â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      if (purchaseDetails.productID == monthlySubscriptionId) {
        print('ðŸ’³ [PURCHASE] Monthly subscription');
        final expiryDate = DateTime.now().add(const Duration(days: 30));
        await _firebaseService.updateSubscription(_currentUserId!, true, expiryDate);
        print('âœ… [PURCHASE] Monthly subscription activated');
        _onPurchaseSuccess?.call();
        return;
      }

      // â”€â”€â”€ Yearly Individual Subscription â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      if (purchaseDetails.productID == yearlySubscriptionId) {
        print('ðŸ’³ [PURCHASE] Yearly subscription');
        final expiryDate = DateTime.now().add(const Duration(days: 365));
        await _firebaseService.updateSubscription(_currentUserId!, true, expiryDate);
        print('âœ… [PURCHASE] Yearly subscription activated');
        _onPurchaseSuccess?.call();
        return;
      }

      // â”€â”€â”€ Family Monthly Subscription â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      if (purchaseDetails.productID == familyMonthlySubscriptionId) {
        print('ðŸ’³ [PURCHASE] Family monthly subscription');
        final expiryDate = DateTime.now().add(const Duration(days: 30));

        final userDoc = await _firestore.collection('users').doc(_currentUserId!).get();
        final userData = userDoc.data();
        final isAlreadyOwner = userData?['isFamilyPlanOwner'] == true;

        if (!isAlreadyOwner) {
          // First time â€” create the family plan
          final familyCode = await _familyService.createFamilyPlan(_currentUserId!);
          print('âœ… [PURCHASE] Family plan created with code: $familyCode');
        }

        // Grant owner premium
        await _firebaseService.updateSubscription(_currentUserId!, true, expiryDate);

        // âœ… FIX: restore premium to all existing members (handles renewals)
        // If first time there are no members yet â€” this is a safe no-op
        await _familyService.restoreFamilyPlan(_currentUserId!, expiryDate);

        print('âœ… [PURCHASE] Family monthly subscription activated');
        _onPurchaseSuccess?.call();
        return;
      }

      // â”€â”€â”€ Family Yearly Subscription â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      if (purchaseDetails.productID == familyYearlySubscriptionId) {
        print('ðŸ’³ [PURCHASE] Family yearly subscription');
        final expiryDate = DateTime.now().add(const Duration(days: 365));

        final userDoc = await _firestore.collection('users').doc(_currentUserId!).get();
        final userData = userDoc.data();
        final isAlreadyOwner = userData?['isFamilyPlanOwner'] == true;

        if (!isAlreadyOwner) {
          // First time â€” create the family plan
          final familyCode = await _familyService.createFamilyPlan(_currentUserId!);
          print('âœ… [PURCHASE] Family plan created with code: $familyCode');
        }

        // Grant owner premium
        await _firebaseService.updateSubscription(_currentUserId!, true, expiryDate);

        // âœ… FIX: restore premium to all existing members (handles renewals)
        await _familyService.restoreFamilyPlan(_currentUserId!, expiryDate);

        print('âœ… [PURCHASE] Family yearly subscription activated');
        _onPurchaseSuccess?.call();
        return;
      }

      print('âš ï¸ [PURCHASE] Unknown product: ${purchaseDetails.productID}');
      _onPurchaseError?.call('Unknown product');
    } catch (e) {
      print('âŒ [PURCHASE] Error: $e');
      _onPurchaseError?.call('Failed to activate: $e');
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // EXPIRY CHECK
  //
  // Google Play does NOT push a "subscription expired" event through the
  // purchase stream. Expiry is only reliably enforced server-side via
  // Real-Time Developer Notifications (Cloud Functions webhook).
  //
  // Until you add that webhook, this client-side check runs on every app
  // launch and every app-resume (called from AppLifecycleHandler in main.dart).
  // It reads the stored subscriptionExpiryDate and, if expired, revokes the
  // owner and cascades the revoke to all family members.
  //
  // Limitation: a user with no network access keeps premium until they come
  // back online. For a food scanner app this is an acceptable trade-off.
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Call this on every app launch and app resume.
  /// Detects lapsed subscriptions and cascades revoke to family members.
  Future<void> checkAndHandleExpiry(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final data = userDoc.data()!;
      final bool isPremium = data['isPremium'] == true;

      // Only act if they are currently flagged as premium
      if (!isPremium) return;

      final expiryTimestamp = data['subscriptionExpiryDate'] as Timestamp?;
      if (expiryTimestamp == null) return;

      final expiryDate = expiryTimestamp.toDate();
      final bool hasExpired = expiryDate.isBefore(DateTime.now());

      if (!hasExpired) return; // Still active â€” nothing to do

      print('âš ï¸ [EXPIRY] Subscription expired for $userId â€” revoking...');

      // Revoke the owner
      await _firebaseService.updateSubscription(
        userId,
        false,
        DateTime.now().subtract(const Duration(days: 1)),
      );

      // âœ… Cascade revoke to all family members if this user is an owner
      await _familyService.revokeFamilyPlan(userId);

      print('âœ… [EXPIRY] Revoke complete for $userId');
    } catch (e) {
      // Never crash the app over an expiry check
      print('âš ï¸ [EXPIRY] checkAndHandleExpiry failed silently: $e');
    }
  }

  Future<void> restorePurchases() async {
    try {
      print('Restoring purchases...');
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      print('Error restoring purchases: $e');
      _onPurchaseError?.call('Failed to restore: $e');
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
