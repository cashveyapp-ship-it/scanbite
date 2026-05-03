// home_screen.dart
// ✅ Average Rating pill is now clickable
// ✅ Tapping ⭐ rating opens RateAppScreen

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/app_drawer.dart';

import 'camera_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'subscription_screen.dart';
import 'rate_app_screen.dart'; // ✅ ADD THIS IMPORT

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeTabScreen(),
    const HistoryScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: AppConstants.primaryColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeTabScreen extends StatelessWidget {
  const HomeTabScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    final bool isPremium = authProvider.hasPremiumAccess;
    final int freeScansRemaining = authProvider.getScansRemaining();

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppConstants.primaryColor,
                        AppConstants.secondaryColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${authProvider.userProfile?.displayName ?? 'User'}!',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            isPremium ? Icons.star : Icons.schedule,
                            color: isPremium ? Colors.amber : Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isPremium
                                ? 'Premium Member'
                                : '${freeScansRemaining < 0 ? 0 : freeScansRemaining} Free Scans',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Subscription banner for non-premium users
              if (!isPremium)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SubscriptionScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber.shade700,
                          Colors.orange.shade600,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.white, size: 40),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Go Premium!',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Unlimited scans • ${freeScansRemaining < 0 ? 0 : freeScansRemaining} free scans left',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Scan Button
              Center(
                child: _PulsingWrapper(
                  child: GestureDetector(
                    onTap: () async {
                      // ✅ YOUR EXISTING SCAN CODE — DO NOT CHANGE
                      if (!authProvider.canScan()) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('No Scans Available'),
                            content: const Text(
                              'You have used all your free scans. Please upgrade to Premium for unlimited scans.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                      const SubscriptionScreen(),
                                    ),
                                  );
                                },
                                child: const Text('Upgrade'),
                              ),
                            ],
                          ),
                        );
                        return;
                      }

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CameraScreen(),
                        ),
                      );
                    },

                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppConstants.primaryColor.withOpacity(0.5),
                            spreadRadius: 6,
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 60,
                            color: Colors.white,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Scan Food',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Features Header + Clickable Average Rating
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Features',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AverageRatingSummary(),
                ],
              ),

              const SizedBox(height: 16),

              _buildFeatureCard(
                icon: Icons.calculate,
                title: 'AI Food Analysis',
                description:
                'Scan food using camera, barcode, or gallery to receive calorie estimates, and AI-powered health insights',
              ),
              _buildFeatureCard(
                icon: Icons.favorite,
                title: 'Food Health Score',
                description: 'Know how healthy your food is',
              ),
              _buildFeatureCard(
                icon: Icons.warning,
                title: 'Allergen Detection',
                description: 'Identify potential allergens',
              ),
              _buildFeatureCard(
                icon: Icons.local_hospital,
                title: 'Blood Sugar Awareness',
                description:
                'Review sugar and carbohydrate content for informational purposes only.',
              ),

              const SizedBox(height: 16),

              const Center(
                child: Text(
                  'Educational information only. Not medical advice.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppConstants.primaryColor,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
      ),
    );
  }
}

/// ✅ Average rating pill that reads from Firestore `app_ratings`
/// ✅ Tapping it opens RateAppScreen
class AverageRatingSummary extends StatelessWidget {
  const AverageRatingSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('app_ratings')
          .orderBy('createdAt', descending: true)
          .limit(200)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return _clickablePill(
            context: context,
            text: '—',
            count: 0,
          );
        }

        final docs = snap.data!.docs;

        if (docs.isEmpty) {
          return _clickablePill(
            context: context,
            text: '0.0',
            count: 0,
          );
        }

        double total = 0;
        int count = 0;

        for (final doc in docs) {
          final d = doc.data() as Map<String, dynamic>;
          final starsRaw = d['stars'];
          final stars =
          starsRaw is int ? starsRaw : int.tryParse('$starsRaw') ?? 0;

          if (stars <= 0) continue;

          total += stars;
          count++;
        }

        final avg = count == 0 ? 0.0 : (total / count);
        final avgText = avg.toStringAsFixed(1);

        return _clickablePill(
          context: context,
          text: avgText,
          count: count,
        );
      },
    );
  }

  Widget _clickablePill({
    required BuildContext context,
    required String text,
    required int count,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RateAppScreen(),
            ),
          );
        },
        child: _pill(text: text, count: count),
      ),
    );
  }

  Widget _pill({
    required String text,
    required int count,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            spreadRadius: 0,
            offset: Offset(0, 2),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 16, color: Colors.amber),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 6),
          Text(
            '($count)',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _PulsingWrapper extends StatefulWidget {
  final Widget child;

  const _PulsingWrapper({required this.child});

  @override
  State<_PulsingWrapper> createState() => _PulsingWrapperState();
}

class _PulsingWrapperState extends State<_PulsingWrapper>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true); // 🔥 LOOP FOREVER

    _scale = Tween<double>(
      begin: 1.0,
      end: 1.06,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}