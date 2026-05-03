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
      appBar: AppBar(
        title: const Text('How ScanBite Works'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
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
            title: 'AI Food Analysis',
            description:
            'ScanBite estimates calories, macros, and nutrition details.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InsightsScreen()),
              );
            },
          ),

          _HowItWorksCard(
            icon: Icons.favorite,
            title: 'Health Score',
            description:
            'Get a simple score to help you make smarter food choices.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              );
            },
          ),

          _HowItWorksCard(
            icon: Icons.history,
            title: 'Track Your Meals',
            description:
            'Review your scan history and eating patterns over time.',
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
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Icon(
            icon,
            color: AppConstants.primaryColor,
            size: 32,
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(description),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        ),
      ),
    );
  }
}