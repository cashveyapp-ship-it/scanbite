// subscription_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../providers/auth_provider.dart';
import '../services/subscription_service.dart';
import '../services/firebase_service.dart';
import '../services/family_service.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import 'family_management_screen.dart';


class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final FirebaseService _firebaseService = FirebaseService();
  List<ProductDetails> _products = [];
  bool _isLoading = true;
  bool _isPurchasing = false;
  String? _errorMessage;
  bool _useGooglePlay = false;

  // ✅ keep as FIELD (do not shadow it inside methods)
  bool _purchaseDialogOpen = false;

  // ✅ NEW: track which product user tapped (single scan vs subscription)
  String? _pendingProductId;

  // ✅ REVIEWER BYPASS (Google Play review account)
  bool _isReviewerEmail(String? email) {
    if (email == null) return false;
    return email.toLowerCase() == 'review@scanbiteapp.com';
  }

  bool _effectiveIsPremium(dynamic userProfile) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = authProvider.user?.email;

    if (_isReviewerEmail(email)) return true;
    return userProfile?.isSubscriptionActive ?? false;
  }

  @override
  void initState() {
    super.initState();
    _initializeSubscriptions();
  }

  @override
  void dispose() {
    _subscriptionService.dispose();
    super.dispose();
  }

  // ✅ ADDED: safe open/close dialog helpers
  void _openGoogleRedirectDialog() {
    if (_purchaseDialogOpen) return;

    _purchaseDialogOpen = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing purchase......'),
                  SizedBox(height: 8),
                  Text(
                    'Complete your payment in the purchase window',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _closeGoogleRedirectDialog() {
    if (!_purchaseDialogOpen) return;

    _purchaseDialogOpen = false;

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _initializeSubscriptions() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.user == null) {
      setState(() {
        _errorMessage = 'Please login first';
        _isLoading = false;
      });
      return;
    }

    print('💳 [SUBSCRIPTION] Initializing...');

    try {
      await _subscriptionService.initialize(
        userId: authProvider.user!.uid,
        onSuccess: _handlePurchaseSuccess,
        onError: _handlePurchaseError,
      );

      final available = await _subscriptionService.isAvailable();
      print('💳 [SUBSCRIPTION] Available: $available');

      if (available) {
        final products = await _subscriptionService.getProducts();
        print('💳 [SUBSCRIPTION] Products: ${products.length}');

        setState(() {
          _products = products;
          _useGooglePlay = products.isNotEmpty;
          _isLoading = false;
        });
      } else {
        setState(() {
          _useGooglePlay = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ [SUBSCRIPTION] Error: $e');
      setState(() {
        _useGooglePlay = false;
        _isLoading = false;
      });
    }
  }

  // ✅ UPDATED: now handles BOTH subscription and single scan credit purchases
  Future<void> _handlePurchaseSuccess() async {
    // ✅ ALWAYS close redirect dialog first
    _closeGoogleRedirectDialog();

    if (mounted) setState(() => _isPurchasing = false);

    final authProvider = context.read<AuthProvider>();
    final productId = _pendingProductId;

    // ✅ 1) SINGLE SCAN purchase -> subscription_service already did FieldValue.increment(1)
    // DO NOT add another +1 here — that caused the double-credit bug.
    if (productId == SubscriptionService.singleScanProductId) {
      // Just reload from Firestore so UI reflects the server-side increment
      await authProvider.loadUserProfile();

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(width: 12),
              Text('Success!'),
            ],
          ),
          content: const Text(
            'Payment successful! 1 scan credit has been added to your account.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
              ),
              child: const Text('Start Scanning'),
            ),
          ],
        ),
      );

      _pendingProductId = null;
      return;
    }

    // ✅ 2) SUBSCRIPTION purchase -> your existing premium flow
    await authProvider.loadUserProfile();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Success!'),
          ],
        ),
        content: const Text(
          'Payment successful! You are now a Premium member with unlimited scans.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
            ),
            child: const Text('Start Scanning'),
          ),
        ],
      ),
    );

    _pendingProductId = null;
  }

  void _handlePurchaseError(String error) {
    // ✅ ALWAYS close redirect dialog first
    _closeGoogleRedirectDialog();

    setState(() {
      _isPurchasing = false;
      _errorMessage = error;
    });

    // ✅ Handle "Already Owned" error specially
    if (error.contains('itemAlreadyOwned') || error.contains('already owned')) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 32),
              SizedBox(width: 12),
              Text('Already Subscribed'),
            ],
          ),
          content: const Text(
            'You already own this subscription! Your account should already have premium access.\n\nTry "Restore Purchases" to sync your subscription.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                await _subscriptionService.restorePurchases();

                if (!mounted) return;

                final authProvider =
                Provider.of<AuthProvider>(context, listen: false);
                await authProvider.loadUserProfile();

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Purchases restored! Check your subscription status.',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
              ),
              child: const Text('Restore Purchases'),
            ),
          ],
        ),
      );
      return;
    }

    // ✅ Handle other errors
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: $error'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _handlePurchase(ProductDetails product) async {
    setState(() {
      _isPurchasing = true;
      _errorMessage = null;
    });

    // ✅ remember what user is purchasing (single scan vs subscription)
    _pendingProductId = product.id;

    // ✅ OPEN redirect dialog once (field is used, no shadowing)
    _openGoogleRedirectDialog();

    final success = await _subscriptionService.purchaseSubscription(product);

    // ✅ If purchase could not even start, close the dialog immediately
    if (!success) {
      _closeGoogleRedirectDialog();
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  // INDIVIDUAL PLAN SUBSCRIPTION (Monthly/Yearly)
  Future<void> _handleManualSubscription(bool isMonthly) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isPurchasing = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing subscription...'),
                  SizedBox(height: 8),
                  Text(
                    '(Please wait while we process your purchase)',
                    style: TextStyle(fontSize: 12, color: Colors.green),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      await Future.delayed(const Duration(seconds: 2));

      final expiryDate = DateTime.now().add(
        isMonthly ? const Duration(days: 30) : const Duration(days: 365),
      );

      await _firebaseService.updateSubscription(
        authProvider.user!.uid,
        true,
        expiryDate,
      );

      await authProvider.loadUserProfile();

      if (!mounted) return;
      Navigator.pop(context);

      await _handlePurchaseSuccess();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _handlePurchaseError(e.toString());
    } finally {
      setState(() => _isPurchasing = false);
    }
  }

  // FAMILY PLAN SUBSCRIPTION (Monthly/Yearly)
  Future<void> _handleFamilySubscription(bool isMonthly) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isPurchasing = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing Family Plan...'),
                  SizedBox(height: 8),
                  Text(
                    '(Test Mode - No payment required)',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      await Future.delayed(const Duration(seconds: 2));

      final expiryDate = DateTime.now().add(
        isMonthly ? const Duration(days: 30) : const Duration(days: 365),
      );

      // CREATE FAMILY PLAN WITH UNIQUE CODE
      final familyCode =
      await FamilyService().createFamilyPlan(authProvider.user!.uid);

      // Activate subscription
      await _firebaseService.updateSubscription(
        authProvider.user!.uid,
        true,
        expiryDate,
      );

      await authProvider.loadUserProfile();

      if (!mounted) return;
      Navigator.pop(context);

      // Show success dialog with family code
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(width: 12),
              Text('Family Plan Active!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Your family is ready! Share this code with up to 5 family members:',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purpleAccent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple, width: 2),
                ),
                child: Text(
                  familyCode,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'They can enter this code in Settings → Family Plan',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Done'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FamilyManagementScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
              ),
              child: const Text('Manage Family'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _handlePurchaseError(e.toString());
    } finally {
      setState(() => _isPurchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userProfile = authProvider.userProfile;

    final isPremium = _effectiveIsPremium(userProfile);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Plan'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCurrentStatusCard(userProfile, isPremium),
              const SizedBox(height: 24),
              const Text(
                'Choose Your Plan',
                style:
                TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Select the plan that works best for you',
                style:
                TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              _buildFreePlanCard(userProfile, isPremium),
              const SizedBox(height: 12),
              _buildPayPerScanCard(),
              const SizedBox(height: 12),

              if (!_useGooglePlay && _errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Purchases are temporarily unavailable. Please try again later.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

              // Google Play products OR fallback manual plans
              if (_useGooglePlay && _products.isNotEmpty)
                ..._products.map((product) {
                  final isMonthly = product.id ==
                      SubscriptionService.monthlySubscriptionId;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildProductCard(product, isMonthly),
                  );
                }).toList()
              else
                ...[
                  _buildManualPlanCard(true),
                  const SizedBox(height: 12),
                  _buildManualPlanCard(false),
                ],

              // FAMILY PLAN SECTION (test mode)
              if (!_useGooglePlay) ...[
                const SizedBox(height: 24),
                const Divider(thickness: 2),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.family_restroom,
                        color: Colors.purple.shade700, size: 32),
                    const SizedBox(width: 12),
                    const Text(
                      'Family Plan',
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Share ScanBite with your household. Includes up to 5 members.',
                  style: TextStyle(
                      fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border:
                    Border.all(color: Colors.purple.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.purple.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Note: ScanBite provides nutrition information and insights. Adults are responsible for monitoring and guiding minors when using this app.',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildFamilyPlanCard(true),
                const SizedBox(height: 12),
                _buildFamilyPlanCard(false),
                const Divider(thickness: 2),
                const SizedBox(height: 16),
              ],

              if (_useGooglePlay && _products.isNotEmpty)
                Center(
                  child: TextButton(
                    onPressed: _isPurchasing
                        ? null
                        : () async {
                      await _subscriptionService
                          .restorePurchases();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Checking for previous purchases...'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    child: const Text('Restore Purchases'),
                  ),
                ),

              const SizedBox(height: 16),
              const Text(
                'Premium Features',
                style:
                TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildFeature('Unlimited food scans'),
              _buildFeature('Advanced nutrition insights'),
              _buildFeature('Allergen warnings'),
              _buildFeature('Blood sugar awareness insights'),
              _buildFeature('Weekly health reports'),
              _buildFeature('Export scan history'),
              _buildFeature('Priority support'),
              _buildFeature('No advertisements'),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Payment will be charged to your account. Subscription automatically renews unless cancelled at least 24 hours before the end of the current period.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ UPDATED SIGNATURE: accepts isPremium
  Widget _buildCurrentStatusCard(dynamic userProfile, bool isPremium) {
    final scansRemaining = userProfile?.freeScansRemaining ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPremium
              ? [Colors.amber.shade700, Colors.orange.shade600]
              : [AppConstants.primaryColor, AppConstants.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPremium ? Icons.star : Icons.schedule,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPremium ? 'Premium Member' : 'Free Plan',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isPremium
                          ? 'Unlimited Scans'
                          : '$scansRemaining of ${AppConstants.freeScans} free scans remaining',
                      style:
                      const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ UPDATED SIGNATURE: accepts isPremium
  Widget _buildFreePlanCard(dynamic userProfile, bool isPremium) {
    final scansUsed = AppConstants.freeScans -
        (userProfile?.freeScansRemaining ?? AppConstants.freeScans);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Free Plan',
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isPremium
                        ? Colors.grey
                        : AppConstants.successColor)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPremium
                          ? Colors.grey
                          : AppConstants.successColor,
                    ),
                  ),
                  child: Text(
                    isPremium ? 'INACTIVE' : 'ACTIVE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color:
                      isPremium ? Colors.grey : AppConstants.successColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '\$0.00',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppConstants.successColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${AppConstants.freeScans} free scans included',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: scansUsed / AppConstants.freeScans,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                  AppConstants.successColor),
            ),
            const SizedBox(height: 8),
            Text(
              '$scansUsed of ${AppConstants.freeScans} scans used',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayPerScanCard() {
    final ProductDetails? singleScanProduct = _products.isNotEmpty
        ? _products.cast<ProductDetails?>().firstWhere(
          (p) => p != null && p.id == SubscriptionService.singleScanProductId,
      orElse: () => null,
    )
        : null;

    final bool canBuy =
        _useGooglePlay && singleScanProduct != null && !_isPurchasing;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blue.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pay Per Scan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              singleScanProduct?.price ?? '\$0.90',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'per scan • No subscription required',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.check, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text('No commitment'),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.check, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text('Pay as you go'),
              ],
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: _isPurchasing ? 'Processing...' : 'Buy Single Scan',
              onPressed: canBuy
                  ? () => _handlePurchase(singleScanProduct!)
                  : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      !_useGooglePlay
                          ? 'Purchases are temporarily unavailable. Please try again later.'
                          : 'Single-scan product is currently unavailable. Please try again later.',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              backgroundColor: Colors.blue,
              isLoading: _isPurchasing,
            ),
          ],
        ),
      ),
    );
  }

  // ---- below here unchanged helpers ----

  Widget _buildManualPlanCard(bool isMonthly) {
    final price =
    isMonthly ? AppConstants.monthlyPrice : AppConstants.yearlyPrice;
    final totalYearlySavings = isMonthly
        ? 0.0
        : (AppConstants.monthlyPrice * 12 - AppConstants.yearlyPrice);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isMonthly ? AppConstants.primaryColor : Colors.amber,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isMonthly ? 'Monthly Plan' : 'Yearly Plan',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (!isMonthly)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'BEST VALUE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: isMonthly
                        ? AppConstants.primaryColor
                        : Colors.amber.shade700,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0, left: 4),
                  child: Text(
                    isMonthly ? '/month' : '/year',
                    style:
                    TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
            if (!isMonthly && totalYearlySavings > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Text(
                  'Save \$${totalYearlySavings.toStringAsFixed(2)}/year vs monthly plan',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            _buildPlanFeature('Unlimited scans'),
            _buildPlanFeature('Cancel anytime'),
            _buildPlanFeature('All premium features'),
            _buildPlanFeature('Priority support'),
            const SizedBox(height: 16),
            CustomButton(
              text: _isPurchasing ? 'Processing...' : 'Subscribe Now',
              onPressed: () {
                if (!_isPurchasing) {
                  _handleManualSubscription(isMonthly);
                }
              },
              backgroundColor: isMonthly
                  ? AppConstants.primaryColor
                  : Colors.amber.shade700,
              isLoading: _isPurchasing,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyPlanCard(bool isMonthly) {
    final price = isMonthly
        ? AppConstants.familyMonthlyPrice
        : AppConstants.familyYearlyPrice;
    final savings = isMonthly ? 0.0 : AppConstants.familyYearlySavings;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.purple.shade700,
          width: 2,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purple.shade50,
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.family_restroom,
                          color: Colors.purple.shade700, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        isMonthly ? 'Family Monthly' : 'Family Yearly',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (!isMonthly)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade700,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'BEST VALUE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade700,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0, left: 4),
                    child: Text(
                      isMonthly ? '/month' : '/year',
                      style:
                      TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.people,
                            color: Colors.purple.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Includes ${AppConstants.familyMaxMembers} members',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${AppConstants.familyExtraMemberPrice.toStringAsFixed(2)} per additional member',
                      style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              if (!isMonthly && savings > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Text(
                    'Save \$${savings.toStringAsFixed(2)}/year vs monthly',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _buildPlanFeature(
                  'Up to ${AppConstants.familyMaxMembers} family members'),
              _buildPlanFeature('Unlimited scans per member'),
              _buildPlanFeature('All premium features'),
              _buildPlanFeature('Priority support'),
              _buildPlanFeature('Add more members anytime'),
              const SizedBox(height: 16),
              CustomButton(
                text: _isPurchasing ? 'Processing...' : 'Start Family Plan',
                onPressed: () {
                  if (!_isPurchasing) {
                    _handleFamilySubscription(isMonthly);
                  }
                },
                backgroundColor: Colors.purple.shade700,
                isLoading: _isPurchasing,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductDetails product, bool isMonthly) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isMonthly ? AppConstants.primaryColor : Colors.amber,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    product.title.replaceAll('(ScanBite)', '').trim(),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (!isMonthly)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'BEST VALUE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              product.price,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: isMonthly
                    ? AppConstants.primaryColor
                    : Colors.amber.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.description,
              style:
              TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: _isPurchasing ? 'Processing...' : 'Subscribe Now',
              onPressed: () {
                if (!_isPurchasing) {
                  _handlePurchase(product);
                }
              },
              backgroundColor: isMonthly
                  ? AppConstants.primaryColor
                  : Colors.amber.shade700,
              isLoading: _isPurchasing,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanFeature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(Icons.check_circle,
              color: AppConstants.primaryColor, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildFeature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: [
          Icon(Icons.check_circle,
              color: AppConstants.primaryColor, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}