// settings_screen.dart (FULL UPDATED)
// ✅ Adds:
// 1) "Rate this app" tile (all users) -> RateAppScreen()
// 2) "Ratings Inbox" tile (admin only: an2mouth@yahoo.com) -> AdminRatingsScreen()
// ✅ Does NOT change your other logic

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scanbite/screens/subscription_screen.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';
import 'admin_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_screen.dart';
import '../gen_l10n/app_localizations.dart';
import 'family_management_screen.dart';
import 'package:flutter/services.dart';

// ✅ NEW
import 'rate_app_screen.dart';
import 'admin_ratings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = false; // (kept - even if unused)
  bool _isLoadingFamilyCode = false;
  AppLocalizations get l10n => AppLocalizations.of(context)!;

  bool _isAdminEmail(String? email) {
    const adminEmails = ['an2mouth@yahoo.com', 'alerttmenow@gmail.com'];
    final e = (email ?? '').toLowerCase().trim();
    return adminEmails.contains(e);
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await NotificationService().initialize();
      if (mounted) setState(() {});
    });
  }

  Future<void> _retrieveFamilyCode() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProfile = authProvider.userProfile;

    if (userProfile?.isSubscriptionActive != true) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.subscriptionRequired),
          content: Text(l10n.subscriptionRequiredMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancelButton),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SubscriptionScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
              ),
              child: Text(l10n.subscribeNow),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isLoadingFamilyCode = true);

    try {
      await authProvider.loadUserProfile();

      if (!mounted) return;

      setState(() => _isLoadingFamilyCode = false);

      final updatedProfile = authProvider.userProfile;

      if (updatedProfile?.familyCode != null &&
          updatedProfile!.familyCode!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.familyCodeLoadedSuccess),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.noFamilyCodeFound),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingFamilyCode = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.errorLoadingFamilyCode}: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final userProfile = authProvider.userProfile;
    final l10n = AppLocalizations.of(context)!;

    // ✅ admin flag (single source of truth)
    final bool isAdmin =
        _isAdminEmail(authProvider.user?.email) || _isAdminEmail(userProfile?.email);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          // Language
          _buildSectionHeader(l10n.language),
          _buildLanguageTile(context, localeProvider),

          const Divider(),

          // Notifications
          _buildSectionHeader(l10n.notifications),
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: Text(l10n.enableNotifications),
            subtitle: Text(
              NotificationService().isEnabled
                  ? l10n.notificationsEnabled
                  : l10n.notificationsDisabled,
            ),
            value: NotificationService().isEnabled,
            onChanged: (value) async {
              if (value) {
                await NotificationService().enableNotifications();

                // ✅ If actually enabled (permission granted), show a one-time pop-up reminder
                if (NotificationService().isEnabled) {
                  await NotificationService().showScanReminder(
                    '🔔 Notifications enabled! Reminder: scan your food before you eat 🍽️',
                  );
                }
              } else {
                await NotificationService().disableNotifications();
              }

              if (!mounted) return;

              setState(() {});

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    NotificationService().isEnabled
                        ? l10n.notificationsEnabled
                        : l10n.notificationsDisabled,
                  ),
                  backgroundColor: AppConstants.successColor,
                ),
              );
            },
          ),
          // TEST NOTIFICATION - ✅ LOCALIZED
          ListTile(
            leading: const Icon(Icons.notifications_active,
                color: AppConstants.primaryColor),
            title: Text(l10n.testNotification),
            subtitle: Text(l10n.testNotificationSubtitle),
            trailing: ElevatedButton(
              onPressed: () async {
                await NotificationService().showDailyTipNotification(
                  'Test notification from ScanBite! 🎉 Your notifications are working!',
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.testNotificationSent),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(l10n.testButton),
            ),
          ),

          const Divider(),

          // ✅ ADMIN SECTION (Admin Panel + Ratings Inbox)
          if (isAdmin) ...[
            _buildSectionHeader(l10n.admin),

            // Admin panel
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings,
                    color: Colors.red, size: 32),
                title: Text(
                  l10n.adminPanelTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
                subtitle: Text(l10n.adminPanelSubtitle),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.red),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminScreen()),
                ),
              ),
            ),

            // ✅ Ratings Inbox (admin only)
            _buildTile(
              icon: Icons.rate_review,
              title: l10n.ratingsInboxTitle,
              subtitle: l10n.ratingsInboxSubtitle,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminRatingsScreen()),
                );
              },
            ),

            const Divider(thickness: 2, color: Colors.red),
          ],

          // Legal - ✅ LOCALIZED
          _buildSectionHeader(l10n.legal),
          _buildTile(
            icon: Icons.privacy_tip,
            title: l10n.privacyPolicy,
            subtitle: l10n.privacySubtitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
            ),
          ),
          _buildTile(
            icon: Icons.description,
            title: l10n.termsOfService,
            subtitle: l10n.termsSubtitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TermsScreen()),
            ),
          ),

          const Divider(),

          // SUBSCRIPTION SECTION - ✅ LOCALIZED
          _buildSectionHeader(l10n.subscriptionSectionTitle),
          _buildTile(
            icon: Icons.star,
            title: l10n.premiumSubscriptionTitle,
            subtitle: userProfile?.isSubscriptionActive == true
                ? l10n.unlimitedScans
                : l10n.freeScansRemaining(userProfile?.freeScansRemaining ?? 0),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
              );
            },
          ),

          // FAMILY PLAN SECTION - ✅ FULLY LOCALIZED
          if (userProfile != null) ...[
            if (userProfile.isFamilyPlanOwner == true &&
                (userProfile.familyCode ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.family_restroom,
                                color: Colors.purple.shade700),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l10n.familyPlanTileTitle,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh,
                                  color: Colors.purple),
                              onPressed:
                              _isLoadingFamilyCode ? null : _retrieveFamilyCode,
                              tooltip: l10n.refreshCodeTooltip,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 22, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.purple.shade700, width: 2),
                            ),
                            child: Text(
                              userProfile.familyCode!,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade700,
                                letterSpacing: 4,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.familyCodeInstruction,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: userProfile.familyCode!),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.familyCodeCopied),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.copy),
                                label: Text(l10n.copyButton),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  final code = userProfile.familyCode!;
                                  final box =
                                  context.findRenderObject() as RenderBox?;

                                  Share.share(
                                    '${l10n.shareFamilyMessageTitle}\n\n'
                                        '${l10n.shareFamilyCodeLabel}: $code\n\n'
                                        '${l10n.shareFamilyInstructions}',
                                    subject: l10n.shareFamilySubject,
                                    sharePositionOrigin: box == null
                                        ? null
                                        : box.localToGlobal(Offset.zero) & box.size,
                                  );
                                },
                                icon: const Icon(Icons.share),
                                label: Text(l10n.shareButton),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const FamilyManagementScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.settings),
                            label: Text(l10n.manageFamilyMembersButton),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.shade700,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (userProfile.isFamilyPlanOwner == true)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.family_restroom,
                            size: 48, color: Colors.purple.shade700),
                        const SizedBox(height: 12),
                        Text(
                          l10n.familyPlanTileTitle,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.familyCodeSubtitleOwner,
                          style:
                          const TextStyle(fontSize: 14, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoadingFamilyCode ? null : _retrieveFamilyCode,
                            icon: _isLoadingFamilyCode
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                                : const Icon(Icons.download),
                            label: Text(
                              _isLoadingFamilyCode
                                  ? l10n.loadingText
                                  : l10n.retrieveFamilyCodeButton,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              _buildTile(
                icon: Icons.family_restroom,
                title: l10n.familyPlanTileTitle,
                subtitle: userProfile.familyPlanOwnerId != null
                    ? l10n.familyCodeSubtitleMember
                    : l10n.familyCodeSubtitleJoin,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const FamilyManagementScreen()),
                  );
                },
              ),
          ],

          const Divider(),

          // About - ✅ LOCALIZED
          _buildSectionHeader(l10n.about),

          // ✅ Rate this app (all users)
          _buildTile(
            icon: Icons.rate_review,
            title: l10n.rateThisApp,           // ✅ was hardcoded 'Rate this app'
            subtitle: l10n.rateThisAppSubtitle, // ✅ was hardcoded 'Leave a rating & comment'
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RateAppScreen()),
            ),
          ),

          _buildTile(
            icon: Icons.info,
            title: l10n.appVersion,
            subtitle: AppConstants.appVersion,
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: AppConstants.appName,
                applicationVersion: AppConstants.appVersion,
                applicationIcon: Icon(Icons.restaurant_menu,
                    size: 48, color: AppConstants.primaryColor),
                children: const [
                  Text('AI-powered food nutrition scanner'),
                  SizedBox(height: 8),
                  Text('© 2024 ScanBite. All rights reserved.'),
                ],
              );
            },
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppConstants.primaryColor,
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
        child: Icon(icon, color: AppConstants.primaryColor),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }

  Widget _buildLanguageTile(BuildContext context, LocaleProvider localeProvider) {
    final languages = {
      'en': '🇺🇸 English',
      'es': '🇪🇸 Español',
      'fr': '🇫🇷 Français',
      'de': '🇩🇪 Deutsch',
    };

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
        child: const Icon(Icons.language, color: AppConstants.primaryColor),
      ),
      title: Text(l10n.language),
      subtitle: Text(languages[localeProvider.locale.languageCode] ?? '🇺🇸 English'),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.selectLanguageTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: languages.entries.map((entry) {
                  return RadioListTile<String>(
                    title: Text(entry.value),
                    value: entry.key,
                    groupValue: localeProvider.locale.languageCode,
                    onChanged: (value) {
                      if (value != null) {
                        localeProvider.setLocale(Locale(value));
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.languageSavedMessage(languages[value]!)),
                            backgroundColor: AppConstants.successColor,
                          ),
                        );
                      }
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}
