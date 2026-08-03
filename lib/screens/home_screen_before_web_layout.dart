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
import 'rate_app_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeTabScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 14),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: AppConstants.shadowColor,
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                active: _currentIndex == 0,
                onTap: () => setState(() => _currentIndex = 0),
              ),
              _NavItem(
                icon: Icons.history_rounded,
                label: 'History',
                active: _currentIndex == 1,
                onTap: () => setState(() => _currentIndex = 1),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                active: _currentIndex == 2,
                onTap: () => setState(() => _currentIndex = 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeTabScreen extends StatelessWidget {
  const HomeTabScreen({Key? key}) : super(key: key);

  void _startScan(BuildContext context, AuthProvider authProvider) {
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
                  MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
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
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final bool isPremium = authProvider.hasPremiumAccess;
    final int freeScansRemaining = authProvider.getScansRemaining();
    final name = authProvider.userProfile?.displayName ?? 'there';

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      drawer: const AppDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Builder(
                builder: (context) => Row(
                  children: [
                    IconButton(
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: const Icon(Icons.menu_rounded),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'ScanBite',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppConstants.primaryTextColor,
                      ),
                    ),
                    const Spacer(),
                    const AverageRatingSummary(),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              Text(
                'Hi $name, ready to scan your food?',
                style: const TextStyle(
                  fontSize: 24,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                  color: AppConstants.primaryTextColor,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                isPremium
                    ? 'Premium active • unlimited scans'
                    : '${freeScansRemaining < 0 ? 0 : freeScansRemaining} free scans remaining',
                style: const TextStyle(
                  fontSize: 15,
                  color: AppConstants.secondaryTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 22),

              _HeroScanCard(
                onTap: () => _startScan(context, authProvider),
              ),

              const SizedBox(height: 18),

              if (!isPremium)
                _PremiumMiniCard(
                  freeScansRemaining: freeScansRemaining,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                    );
                  },
                ),

              const SizedBox(height: 22),

              const Text(
                'Smart tools',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: AppConstants.primaryTextColor,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _SmallFeatureCard(
                      icon: Icons.auto_awesome_rounded,
                      title: 'AI Insights',
                      subtitle: 'Personal tips',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SmallFeatureCard(
                      icon: Icons.favorite_rounded,
                      title: 'Nutrition Score',
                      subtitle: 'Meal rating',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _SmallFeatureCard(
                      icon: Icons.local_fire_department_rounded,
                      title: 'Calories',
                      subtitle: 'Track smarter',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SmallFeatureCard(
                      icon: Icons.question_answer_rounded,
                      title: 'Ask AI',
                      subtitle: 'Food answers',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _InfoCard(
                icon: Icons.verified_rounded,
                title: 'Nutrition estimates',
                text:
                    'ScanBite uses AI analysis and public nutrition databases to estimate calories, macros, and nutrition details.',
              ),

              const SizedBox(height: 12),

              _InfoCard(
                icon: Icons.health_and_safety_rounded,
                title: 'Informational only',
                text:
                    'ScanBite is not medical advice. Use it as a helpful nutrition guide.',
              ),

              const SizedBox(height: 14),

              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Text(
                        'Nutrition estimates sourced from USDA FoodData Central and public nutrition databases.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Informational only — not medical advice.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroScanCard extends StatelessWidget {
  final VoidCallback onTap;

  const _HeroScanCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        boxShadow: const [
          BoxShadow(
            color: AppConstants.shadowColor,
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=1000',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(.55),
                    Colors.black.withOpacity(.10),
                    Colors.black.withOpacity(.65),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              left: 24,
              top: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'AI Food Scanner',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Snap a meal. Get nutrition facts instantly.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            Center(
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppConstants.primaryColor,
                      width: 5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: AppConstants.shadowColor,
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: AppConstants.primaryColor,
                    size: 44,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.95),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: const [
                    CircleAvatar(
                      backgroundColor: Color(0xFFE8F8ED),
                      child: Icon(
                        Icons.restaurant_rounded,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tap the camera to scan your meal',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppConstants.primaryTextColor,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumMiniCard extends StatelessWidget {
  final int freeScansRemaining;
  final VoidCallback onTap;

  const _PremiumMiniCard({
    required this.freeScansRemaining,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scans = freeScansRemaining < 0 ? 0 : freeScansRemaining;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7E6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFFD591)),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFFFE1A8),
              child: Icon(Icons.star_rounded, color: Color(0xFFFF9F0A)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Go Premium • $scans free scans left',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppConstants.primaryTextColor,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}

class _SmallFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SmallFeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 126,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppConstants.borderColor),
        boxShadow: const [
          BoxShadow(
            color: AppConstants.shadowColor,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFE8F8ED),
            child: Icon(icon, color: AppConstants.primaryColor),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: AppConstants.primaryTextColor,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppConstants.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFE8F8ED),
            child: Icon(icon, color: AppConstants.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppConstants.primaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    color: AppConstants.secondaryTextColor,
                    height: 1.35,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE8F8ED) : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: active
                  ? AppConstants.primaryColor
                  : AppConstants.secondaryTextColor,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: active
                    ? AppConstants.primaryColor
                    : AppConstants.secondaryTextColor,
                fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
          return _clickablePill(context: context, text: '—', count: 0);
        }

        final docs = snap.data!.docs;

        if (docs.isEmpty) {
          return _clickablePill(context: context, text: '0.0', count: 0);
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
            MaterialPageRoute(builder: (_) => const RateAppScreen()),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppConstants.borderColor),
            boxShadow: const [
              BoxShadow(
                blurRadius: 10,
                offset: Offset(0, 4),
                color: AppConstants.shadowColor,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, size: 16, color: Colors.amber),
              const SizedBox(width: 5),
              Text(
                text,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 4),
              Text(
                '($count)',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppConstants.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

