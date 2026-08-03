import 'package:flutter/material.dart';
import '../utils/constants.dart';

import '../screens/home_screen.dart';
import '../screens/insights_screen.dart';
import '../screens/history_screen.dart';
import '../screens/subscription_screen.dart';
import '../screens/analytics_screen.dart';

class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F3),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'How ScanBite Works',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _HowItWorksCard(
            icon: Icons.camera_alt,
            title: 'Scan Your Food',
            description:
            'Take a photo of your meal and ScanBite will analyze it instantly.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            },
          ),

          _HowItWorksCard(
            icon: Icons.auto_awesome,
            title: 'AI Nutrition Estimates',
            description:
            'ScanBite provides estimated nutrition information from AI analysis and public food databases.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InsightsScreen()),
              );
            },
          ),

          _HowItWorksCard(
            icon: Icons.favorite,
            title: 'AI Nutrition Score',
            description:
            'View an estimated nutrition score based on ingredient and nutrition information.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              );
            },
          ),

          _HowItWorksCard(
            icon: Icons.history,
            title: 'Meal History',
            description:
            'Review your saved scan history and nutrition activity..',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),

          _HowItWorksCard(
            icon: Icons.star,
            title: 'Unlimited Scans',
            description:
            'Use your 5 free scans, then upgrade for unlimited scans.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SubscriptionScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _HowItWorksCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Icon(
            icon,
            color: const Color(0xFF34C759),
            size: 32,
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Colors.black,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              description,
              style: const TextStyle(
                color: Color(0xFF6E6E73),
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        ),
      ),
    );
  }
}

