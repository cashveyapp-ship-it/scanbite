// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settings => 'Settings';

  @override
  String get notifications => 'Notifications';

  @override
  String get enableNotifications => 'Enable Notifications';

  @override
  String get notificationSubtitle => 'Get meal reminders and health tips';

  @override
  String get notificationsEnabled => 'Notifications enabled';

  @override
  String get notificationsDisabled => 'Notifications disabled';

  @override
  String get language => 'Language';

  @override
  String get legal => 'Legal';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get privacySubtitle => 'How we handle your data';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get termsSubtitle => 'Our terms and conditions';

  @override
  String get about => 'About';

  @override
  String get appVersion => 'App Version';

  @override
  String get lastUpdatedLabel => 'Last Updated';

  @override
  String get copyrightLine => '© 2024 ScanBite. All rights reserved.';

  @override
  String get privacyTitle => 'Privacy Policy for ScanBite';

  @override
  String get privacyIntroTitle => 'Introduction';

  @override
  String get privacyIntroBody =>
      'ScanBite (\"we,\" \"our,\" or \"us\") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.';

  @override
  String get privacyCollectTitle => 'Information We Collect';

  @override
  String get privacyCollectBody =>
      'We collect information that you provide directly to us, including:\n\n- Account Information: Name, email address, password\n- Profile Information: Age, gender, height, weight, dietary preferences\n- Health Information: Food scans, nutrition data, meal history\n- Usage Information: App interactions, features used, scan frequency\n- Device Information: Device type, operating system, unique identifiers';

  @override
  String get privacyUseTitle => 'How We Use Your Information';

  @override
  String get privacyUseBody =>
      'We use the information we collect to:\n\n- Provide and maintain our services\n- Analyze food images and provide nutrition information\n- Personalize your experience and recommendations\n- Send you notifications and updates\n- Improve our app and develop new features\n- Comply with legal obligations\n- Protect against fraud and abuse';

  @override
  String get privacySecurityTitle => 'Data Storage and Security';

  @override
  String get privacySecurityBody =>
      'We implement appropriate technical and organizational measures to protect your personal information:\n\n- Data is encrypted in transit and at rest\n- We use Firebase secure cloud storage\n- Access to personal data is restricted\n- Regular security assessments are performed\n\nHowever, no method of transmission over the internet is 100% secure.';

  @override
  String get privacyThirdPartyTitle => 'Third-Party Services';

  @override
  String get privacyThirdPartyBody =>
      'We use the following third-party services:\n\n- Firebase (Google): Authentication, database, storage\n- OpenAI: Food image analysis\n- Analytics: To understand app usage patterns\n\nThese services have their own privacy policies governing their use of information.';

  @override
  String get privacyRightsTitle => 'Your Data Rights';

  @override
  String get privacyRightsBody =>
      'You have the right to:\n\n- Access your personal information\n- Correct inaccurate data\n- Request deletion of your data\n- Export your data\n- Opt-out of marketing communications\n- Withdraw consent at any time\n\nTo exercise these rights, contact us at alerttmenow@gmail.com';

  @override
  String get privacyChildrenTitle => 'Children\'s Privacy';

  @override
  String get privacyChildrenBody =>
      'Our service is not intended for children under 13. We do not knowingly collect personal information from children under 13.';

  @override
  String get privacyRetentionTitle => 'Data Retention';

  @override
  String get privacyRetentionBody =>
      'We retain your information for as long as your account is active or as needed to provide you services. You may request deletion of your account at any time.';

  @override
  String get privacyTransfersTitle => 'International Data Transfers';

  @override
  String get privacyTransfersBody =>
      'Your information may be transferred to and processed in countries other than your country of residence. We ensure appropriate safeguards are in place.';

  @override
  String get privacyChangesTitle => 'Changes to Privacy Policy';

  @override
  String get privacyChangesBody =>
      'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the \"Last Updated\" date.';

  @override
  String get privacyContactTitle => 'Contact Us';

  @override
  String get privacyContactBody =>
      'If you have questions about this Privacy Policy, please contact us:\n\nEmail: alerttmenow@gmail.com\nWebsite: www.an2app.com/scanbite.com\nAddress: www.an2app.com';

  @override
  String get termsTitle => 'Terms of Service';

  @override
  String get termsAcceptanceTitle => 'Acceptance of Terms';

  @override
  String get termsAcceptanceBody =>
      'By accessing and using ScanBite, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to these Terms of Service, please do not use our app.';

  @override
  String get termsServiceDescTitle => 'Description of Service';

  @override
  String get termsServiceDescBody =>
      'ScanBite provides:\n\n- AI-powered food nutrition analysis\n- Barcode scanning for packaged foods\n- Meal tracking and history\n- Personalized health insights\n- Dietary goal tracking\n- Nutrition recommendations\n\nThe service is provided \"as is\" and \"as available.\"';

  @override
  String get termsAccountsTitle => 'User Accounts';

  @override
  String get termsAccountsBody =>
      'To use certain features, you must:\n\n- Create an account with accurate information\n- Maintain the security of your password\n- Be at least 13 years of age\n- Comply with all applicable laws\n\nYou are responsible for all activities under your account.';

  @override
  String get termsSubscriptionTitle => 'Subscription and Payment';

  @override
  String termsSubscriptionBody(String price, String freeScans) {
    return 'Premium Subscription:\n\n- Monthly subscription: \\\$$price/month\n- Free users: $freeScans scans per month\n- Premium users: Unlimited scans\n- Auto-renewal unless cancelled\n- Refunds subject to app store policies\n\nSubscriptions are managed through your app store account.';
  }

  @override
  String get termsHealthDisclaimerTitle => 'Health Disclaimer';

  @override
  String get termsHealthDisclaimerBody =>
      'IMPORTANT - PLEASE READ:\n\n- ScanBite is NOT a medical device\n- Information provided is for educational purposes only\n- Do NOT use as a substitute for professional medical advice\n- Consult healthcare providers for medical decisions\n- We do not guarantee accuracy of nutritional information\n- Users with medical conditions should seek professional guidance\n- Allergen detection may not be comprehensive\n\nUSE AT YOUR OWN RISK.';

  @override
  String get termsAcceptableUseTitle => 'Acceptable Use';

  @override
  String get termsAcceptableUseBody =>
      'You agree NOT to:\n\n- Violate any laws or regulations\n- Infringe on intellectual property rights\n- Upload malicious code or viruses\n- Attempt to gain unauthorized access\n- Reverse engineer the application\n- Use the app for commercial purposes without permission\n- Harass or harm other users\n- Misrepresent your identity';

  @override
  String get termsIpTitle => 'Intellectual Property';

  @override
  String get termsIpBody =>
      'All content, features, and functionality are owned by ScanBite and protected by copyright, trademark, and other intellectual property laws.';

  @override
  String get termsUserContentTitle => 'User Content';

  @override
  String get termsUserContentBody =>
      'By uploading content to ScanBite, you grant us a license to use, store, and process your content while retaining ownership.';

  @override
  String get termsLiabilityTitle => 'Limitation of Liability';

  @override
  String get termsLiabilityBody =>
      'To the maximum extent permitted by law, we are not liable for indirect, incidental, or consequential damages.';

  @override
  String get termsIndemnificationTitle => 'Indemnification';

  @override
  String get termsIndemnificationBody =>
      'You agree to indemnify and hold ScanBite harmless from any claims arising from your use of the app.';

  @override
  String get termsTerminationTitle => 'Termination';

  @override
  String get termsTerminationBody =>
      'We may terminate or suspend your account for violations of these terms or at our discretion.';

  @override
  String get termsChangesTitle => 'Changes to Terms';

  @override
  String get termsChangesBody =>
      'We reserve the right to modify these terms at any time. Continued use after changes constitutes acceptance.';

  @override
  String get termsGoverningLawTitle => 'Governing Law';

  @override
  String get termsGoverningLawBody =>
      'These terms shall be governed by the laws of your jurisdiction.';

  @override
  String get termsDisputeTitle => 'Dispute Resolution';

  @override
  String get termsDisputeBody =>
      'Disputes should first be resolved informally before mediation or arbitration.';

  @override
  String get termsContactTitle => 'Contact Information';

  @override
  String get termsContactBody =>
      'For questions about these Terms:\n\nEmail: alerttmenow@gmail.com\nWebsite: www.an2app.com/scanbite.com';

  @override
  String get termsSeverabilityTitle => 'Severability';

  @override
  String get termsSeverabilityBody =>
      'If any provision is unenforceable, the remaining provisions remain in effect.';

  @override
  String get aiFoodNutritionScanner => 'AI Food Nutrition Scanner';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get login => 'Login';

  @override
  String get signUp => 'Sign Up';

  @override
  String get dontHaveAnAccount => 'Don\'t have an account?';

  @override
  String get pleaseEnterYourEmail => 'Please enter your email';

  @override
  String get pleaseEnterAValidEmail => 'Please enter a valid email';

  @override
  String get pleaseEnterYourPassword => 'Please enter your password';

  @override
  String get passwordMinChars => 'Password must be at least 6 characters';

  @override
  String get testNotification => 'Test Notification';

  @override
  String get testNotificationSubtitle => 'Tap to send a test notification';

  @override
  String get testNotificationSent =>
      'Test notification sent! Check your notification tray.';

  @override
  String get testButton => 'Test';

  @override
  String get admin => 'Admin';

  @override
  String get adminPanelTitle => 'ADMIN PANEL';

  @override
  String get adminPanelSubtitle => 'Manage all users';

  @override
  String get subscriptionSectionTitle => 'Subscription';

  @override
  String get premiumSubscriptionTitle => 'Premium Subscription';

  @override
  String get unlimitedScans => 'Active - Unlimited Scans';

  @override
  String freeScansRemaining(int count) {
    return '$count free scans remaining';
  }

  @override
  String get familyPlanTileTitle => 'Family Plan';

  @override
  String get familyPlanCodeTitle => 'Family Plan Code';

  @override
  String get refreshCodeTooltip => 'Refresh code';

  @override
  String get familyCodeRefreshed => 'Family code refreshed!';

  @override
  String get familyCodeInstruction =>
      'Share this code with your family members. They enter it in Settings → Family Plan.';

  @override
  String get familyCodeCopied => 'Family code copied!';

  @override
  String get copyButton => 'Copy';

  @override
  String get shareButton => 'Share';

  @override
  String get manageFamilyMembersButton => 'Manage Family Members';

  @override
  String get familyCodeSubtitleOwner =>
      'Tap below to retrieve your family code';

  @override
  String get familyCodeSubtitleMember => 'Connected to a family plan';

  @override
  String get familyCodeSubtitleJoin => 'Join with a 6-character code';

  @override
  String get retrieveFamilyCodeButton => 'Retrieve Family Code';

  @override
  String get loadingText => 'Loading...';

  @override
  String get subscriptionRequired => 'Subscription Required';

  @override
  String get subscriptionRequiredMessage =>
      'You need an active subscription to create or view a Family Plan code. Please subscribe to continue.';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get subscribeNow => 'Subscribe Now';

  @override
  String get familyCodeLoadedSuccess => 'Family code loaded successfully!';

  @override
  String get noFamilyCodeFound =>
      'No family code found. Please contact support if you believe this is an error.';

  @override
  String get errorLoadingFamilyCode => 'Error loading family code';

  @override
  String get shareFamilySubject => 'Join My ScanBite Family Plan';

  @override
  String get shareFamilyMessageTitle => 'Join my ScanBite Family Plan!';

  @override
  String get shareFamilyCodeLabel => 'Family Code';

  @override
  String get shareFamilyInstructions =>
      'Open ScanBite → Settings → Family Plan → Enter Code';

  @override
  String get yourFamilyCode => 'Your Family Code';

  @override
  String get familyMembers => 'Family Members';

  @override
  String get monthlyCostBreakdown => 'Monthly Cost Breakdown';

  @override
  String basePlan(int count) {
    return 'Base Plan ($count members)';
  }

  @override
  String get totalMonthlyCost => 'Total Monthly Cost';

  @override
  String get owner => 'OWNER';

  @override
  String get copyCode => 'Copy Code';

  @override
  String get selectLanguageTitle => 'Select Language';

  @override
  String languageSavedMessage(String language) {
    return 'Language saved: $language';
  }

  @override
  String get rateThisApp => 'Rate this app';

  @override
  String get rateThisAppSubtitle => 'Leave a rating & comment';

  @override
  String get ratingsInboxTitle => 'Ratings Inbox';

  @override
  String get ratingsInboxSubtitle => 'View & reply to user ratings';

  @override
  String get rateAppTitle => 'Rate this App';

  @override
  String get rateAppQuestion => 'How\'s your experience?';

  @override
  String get rateAppHint => 'Write a comment (visible to all users)';

  @override
  String get rateAppSubmitting => 'Submitting...';

  @override
  String get rateAppSubmit => 'Submit';

  @override
  String get rateAppDisclaimer =>
      'Your review will be posted publicly. We\'ll also open an email to support so you can get a response.';

  @override
  String get rateAppRecentReviews => 'Recent reviews';

  @override
  String get rateAppNoReviews => 'No reviews yet.';

  @override
  String get rateAppDeveloperResponse => 'Developer response';

  @override
  String get rateAppSignInFirst => 'Please sign in first.';

  @override
  String get rateAppWriteComment => 'Please write a comment.';

  @override
  String get rateAppCommentTooLong =>
      'Comment is too long (max 500 characters).';

  @override
  String get rateAppThanks => 'Thanks! Your review was posted.';

  @override
  String get rateAppFailed => 'Failed to submit rating. Please try again.';

  @override
  String get rateAppEmailSubject => 'ScanBite App Rating';

  @override
  String get adminRatingsTitle => 'Ratings Inbox';

  @override
  String get adminRatingsNoReviews => 'No reviews yet.';

  @override
  String get adminRatingsReplyTitle => 'Reply to user';

  @override
  String get adminRatingsReplyHint => 'Write your reply...';

  @override
  String get adminRatingsCancel => 'Cancel';

  @override
  String get adminRatingsSaveReply => 'Save Reply';

  @override
  String get adminRatingsReplyPosted => 'Reply posted.';

  @override
  String get adminRatingsYourReply => 'Your reply';

  @override
  String get adminRatingsEditReply => 'Edit Reply';

  @override
  String get adminRatingsAccessDenied => 'You do not have admin access.';

  @override
  String get adminRatingsReply => 'Reply';
}
