import 'package:flutter/material.dart';
import '../gen_l10n/app_localizations.dart';
import '../utils/constants.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.termsOfService),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.termsTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              // keep your date behavior (dynamic)
              '${l10n.lastUpdatedLabel}: ${DateTime.now().toString().substring(0, 10)}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(l10n.termsAcceptanceTitle, l10n.termsAcceptanceBody),

            _buildSection(l10n.termsServiceDescTitle, l10n.termsServiceDescBody),

            _buildSection(l10n.termsAccountsTitle, l10n.termsAccountsBody),

            _buildSection(
              l10n.termsSubscriptionTitle,
              // inject prices without breaking localization
              l10n.termsSubscriptionBody(
                AppConstants.monthlyPrice.toStringAsFixed(2),
                AppConstants.freeScansPerMonth.toString(),
              ),
            ),

            _buildSection(l10n.termsHealthDisclaimerTitle, l10n.termsHealthDisclaimerBody),

            _buildSection(l10n.termsAcceptableUseTitle, l10n.termsAcceptableUseBody),

            _buildSection(l10n.termsIpTitle, l10n.termsIpBody),

            _buildSection(l10n.termsUserContentTitle, l10n.termsUserContentBody),

            _buildSection(l10n.termsLiabilityTitle, l10n.termsLiabilityBody),

            _buildSection(l10n.termsIndemnificationTitle, l10n.termsIndemnificationBody),

            _buildSection(l10n.termsTerminationTitle, l10n.termsTerminationBody),

            _buildSection(l10n.termsChangesTitle, l10n.termsChangesBody),

            _buildSection(l10n.termsGoverningLawTitle, l10n.termsGoverningLawBody),

            _buildSection(l10n.termsDisputeTitle, l10n.termsDisputeBody),

            _buildSection(l10n.termsContactTitle, l10n.termsContactBody),

            _buildSection(l10n.termsSeverabilityTitle, l10n.termsSeverabilityBody),

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
