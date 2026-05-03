import 'package:flutter/material.dart';
import '../gen_l10n/app_localizations.dart';
import '../utils/constants.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.privacyPolicy),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.privacyTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.lastUpdatedLabel}: ${DateTime.now().toString().substring(0, 10)}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(l10n.privacyIntroTitle, l10n.privacyIntroBody),
            _buildSection(l10n.privacyCollectTitle, l10n.privacyCollectBody),
            _buildSection(l10n.privacyUseTitle, l10n.privacyUseBody),
            _buildSection(l10n.privacySecurityTitle, l10n.privacySecurityBody),
            _buildSection(l10n.privacyThirdPartyTitle, l10n.privacyThirdPartyBody),
            _buildSection(l10n.privacyRightsTitle, l10n.privacyRightsBody),
            _buildSection(l10n.privacyChildrenTitle, l10n.privacyChildrenBody),
            _buildSection(l10n.privacyRetentionTitle, l10n.privacyRetentionBody),
            _buildSection(l10n.privacyTransfersTitle, l10n.privacyTransfersBody),
            _buildSection(l10n.privacyChangesTitle, l10n.privacyChangesBody),
            _buildSection(l10n.privacyContactTitle, l10n.privacyContactBody),

            const SizedBox(height: 32),
            Center(
              child: Text(
                l10n.copyrightLine,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
