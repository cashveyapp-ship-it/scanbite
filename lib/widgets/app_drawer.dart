import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/subscription_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/admin_screen.dart';
import '../utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/animated_how_it_works_tile.dart';
import '../screens/ai_food_question_screen.dart';
import 'dart:io';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  static const _adminEmails = ['an2mouth@yahoo.com', 'alerttmenow@gmail.com'];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userProfile = authProvider.userProfile;

    final String? authEmail = authProvider.user?.email?.toLowerCase().trim();
    final bool isAdmin = _adminEmails.contains(authEmail);

    // 🔴 DEBUG - remove after confirming admin access works
    print('🔑 DRAWER AUTH EMAIL: $authEmail');
    print('🔑 DRAWER IS ADMIN: $isAdmin');

    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Text(
                      userProfile?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userProfile?.displayName ?? 'User',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userProfile?.email ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Premium Status / Upgrade
                if (userProfile?.isSubscriptionActive == true)
                  ListTile(
                    leading: const Icon(Icons.star, color: Colors.amber),
                    title: const Text('Premium Member'),
                    subtitle: const Text('Unlimited Scans'),
                  )
                else
                  ListTile(
                    leading: const Icon(Icons.star_border, color: Colors.amber),
                    title: const Text('Upgrade to Premium'),
                    subtitle: Text('${userProfile?.freeScansRemaining ?? 0} free scans left'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
                      );
                    },
                  ),
                const Divider(),

                // 🔥 NEW: ANIMATED "SEE HOW IT WORKS"
                const AnimatedHowItWorksTile(),

                const Divider(),

                ListTile(
                  leading: const Icon(Icons.play_circle_fill, color: Colors.red),
                  title: const Text('Watch Demo 1'),
                  onTap: () async {
                    Navigator.pop(context);
                    await launchUrl(
                      Uri.parse('https://youtu.be/xWJ3MdgY8xk'),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.play_circle_fill, color: Colors.red),
                  title: const Text('Watch Demo 2'),
                  onTap: () async {
                    Navigator.pop(context);
                    await launchUrl(
                      Uri.parse('https://share.synthesia.io/bec9e754-e7cf-41ab-9176-44f636d29d0b'),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                ),

                const Divider(),

                ListTile(
                  leading: const Icon(Icons.star, color: Colors.amber),
                  title: const Text('Rate ScanBite'),
                  subtitle: const Text('Leave us a review'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    Navigator.pop(context);

                    final Uri url = Platform.isIOS
                        ? Uri.parse(
                      'itms-apps://apps.apple.com/app/id6766014924?action=write-review',
                    )
                        : Uri.parse(
                      'https://play.google.com/store/apps/details?id=com.an2app.scanbite',
                    );

                    final String storeName = Platform.isIOS ? 'App Store' : 'Play Store';

                    try {
                      final opened = await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );

                      if (!opened && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Unable to open $storeName')),
                        );
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Unable to open $storeName')),
                        );
                      }
                    }
                  },
                ),


                const Divider(),

                // 🤖 NEW: Ask AI About Food
                ListTile(
                  leading: const Icon(Icons.smart_toy),
                  title: const Text('Ask AI About Food'),
                  subtitle: const Text('Get answers about food & health'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AiFoodQuestionScreen(),
                      ),
                    );
                  },
                ),


                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                ),

                const Divider(),
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('Invite a Friend'),
                  subtitle: const Text('Share ScanBite with someone'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    Navigator.pop(context);

                    await Share.share(
                      'https://play.google.com/store/apps/details?id=com.an2app.scanbite&pcampaignid=web_share',
                      subject: 'ScanBite',
                    );
                  },
                ),

                // Admin Panel - only visible to admin emails
                if (isAdmin) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings, color: Colors.red),
                    title: const Text(
                      'Admin Panel',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text('Manage users & subscriptions'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminScreen()),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
