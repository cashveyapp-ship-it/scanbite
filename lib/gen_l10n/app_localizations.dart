import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr')
  ];

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// No description provided for @notificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get meal reminders and health tips'**
  String get notificationSubtitle;

  /// No description provided for @notificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications enabled'**
  String get notificationsEnabled;

  /// No description provided for @notificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications disabled'**
  String get notificationsDisabled;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @legal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legal;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @privacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'How we handle your data'**
  String get privacySubtitle;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @termsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Our terms and conditions'**
  String get termsSubtitle;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @lastUpdatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get lastUpdatedLabel;

  /// No description provided for @copyrightLine.
  ///
  /// In en, this message translates to:
  /// **'© 2024 ScanBite. All rights reserved.'**
  String get copyrightLine;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy for ScanBite'**
  String get privacyTitle;

  /// No description provided for @privacyIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Introduction'**
  String get privacyIntroTitle;

  /// No description provided for @privacyIntroBody.
  ///
  /// In en, this message translates to:
  /// **'ScanBite (\"we,\" \"our,\" or \"us\") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.'**
  String get privacyIntroBody;

  /// No description provided for @privacyCollectTitle.
  ///
  /// In en, this message translates to:
  /// **'Information We Collect'**
  String get privacyCollectTitle;

  /// No description provided for @privacyCollectBody.
  ///
  /// In en, this message translates to:
  /// **'We collect information that you provide directly to us, including:\n\n- Account Information: Name, email address, password\n- Profile Information: Age, gender, height, weight, dietary preferences\n- Health Information: Food scans, nutrition data, meal history\n- Usage Information: App interactions, features used, scan frequency\n- Device Information: Device type, operating system, unique identifiers'**
  String get privacyCollectBody;

  /// No description provided for @privacyUseTitle.
  ///
  /// In en, this message translates to:
  /// **'How We Use Your Information'**
  String get privacyUseTitle;

  /// No description provided for @privacyUseBody.
  ///
  /// In en, this message translates to:
  /// **'We use the information we collect to:\n\n- Provide and maintain our services\n- Analyze food images and provide nutrition information\n- Personalize your experience and recommendations\n- Send you notifications and updates\n- Improve our app and develop new features\n- Comply with legal obligations\n- Protect against fraud and abuse'**
  String get privacyUseBody;

  /// No description provided for @privacySecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'Data Storage and Security'**
  String get privacySecurityTitle;

  /// No description provided for @privacySecurityBody.
  ///
  /// In en, this message translates to:
  /// **'We implement appropriate technical and organizational measures to protect your personal information:\n\n- Data is encrypted in transit and at rest\n- We use Firebase secure cloud storage\n- Access to personal data is restricted\n- Regular security assessments are performed\n\nHowever, no method of transmission over the internet is 100% secure.'**
  String get privacySecurityBody;

  /// No description provided for @privacyThirdPartyTitle.
  ///
  /// In en, this message translates to:
  /// **'Third-Party Services'**
  String get privacyThirdPartyTitle;

  /// No description provided for @privacyThirdPartyBody.
  ///
  /// In en, this message translates to:
  /// **'We use the following third-party services:\n\n- Firebase (Google): Authentication, database, storage\n- OpenAI: Food image analysis\n- Analytics: To understand app usage patterns\n\nThese services have their own privacy policies governing their use of information.'**
  String get privacyThirdPartyBody;

  /// No description provided for @privacyRightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Data Rights'**
  String get privacyRightsTitle;

  /// No description provided for @privacyRightsBody.
  ///
  /// In en, this message translates to:
  /// **'You have the right to:\n\n- Access your personal information\n- Correct inaccurate data\n- Request deletion of your data\n- Export your data\n- Opt-out of marketing communications\n- Withdraw consent at any time\n\nTo exercise these rights, contact us at alerttmenow@gmail.com'**
  String get privacyRightsBody;

  /// No description provided for @privacyChildrenTitle.
  ///
  /// In en, this message translates to:
  /// **'Children\'s Privacy'**
  String get privacyChildrenTitle;

  /// No description provided for @privacyChildrenBody.
  ///
  /// In en, this message translates to:
  /// **'Our service is not intended for children under 13. We do not knowingly collect personal information from children under 13.'**
  String get privacyChildrenBody;

  /// No description provided for @privacyRetentionTitle.
  ///
  /// In en, this message translates to:
  /// **'Data Retention'**
  String get privacyRetentionTitle;

  /// No description provided for @privacyRetentionBody.
  ///
  /// In en, this message translates to:
  /// **'We retain your information for as long as your account is active or as needed to provide you services. You may request deletion of your account at any time.'**
  String get privacyRetentionBody;

  /// No description provided for @privacyTransfersTitle.
  ///
  /// In en, this message translates to:
  /// **'International Data Transfers'**
  String get privacyTransfersTitle;

  /// No description provided for @privacyTransfersBody.
  ///
  /// In en, this message translates to:
  /// **'Your information may be transferred to and processed in countries other than your country of residence. We ensure appropriate safeguards are in place.'**
  String get privacyTransfersBody;

  /// No description provided for @privacyChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Changes to Privacy Policy'**
  String get privacyChangesTitle;

  /// No description provided for @privacyChangesBody.
  ///
  /// In en, this message translates to:
  /// **'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the \"Last Updated\" date.'**
  String get privacyChangesBody;

  /// No description provided for @privacyContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get privacyContactTitle;

  /// No description provided for @privacyContactBody.
  ///
  /// In en, this message translates to:
  /// **'If you have questions about this Privacy Policy, please contact us:\n\nEmail: alerttmenow@gmail.com\nWebsite: www.an2app.com/scanbite.com\nAddress: www.an2app.com'**
  String get privacyContactBody;

  /// No description provided for @termsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsTitle;

  /// No description provided for @termsAcceptanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Acceptance of Terms'**
  String get termsAcceptanceTitle;

  /// No description provided for @termsAcceptanceBody.
  ///
  /// In en, this message translates to:
  /// **'By accessing and using ScanBite, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to these Terms of Service, please do not use our app.'**
  String get termsAcceptanceBody;

  /// No description provided for @termsServiceDescTitle.
  ///
  /// In en, this message translates to:
  /// **'Description of Service'**
  String get termsServiceDescTitle;

  /// No description provided for @termsServiceDescBody.
  ///
  /// In en, this message translates to:
  /// **'ScanBite provides:\n\n- AI-powered food nutrition analysis\n- Barcode scanning for packaged foods\n- Meal tracking and history\n- Personalized health insights\n- Dietary goal tracking\n- Nutrition recommendations\n\nThe service is provided \"as is\" and \"as available.\"'**
  String get termsServiceDescBody;

  /// No description provided for @termsAccountsTitle.
  ///
  /// In en, this message translates to:
  /// **'User Accounts'**
  String get termsAccountsTitle;

  /// No description provided for @termsAccountsBody.
  ///
  /// In en, this message translates to:
  /// **'To use certain features, you must:\n\n- Create an account with accurate information\n- Maintain the security of your password\n- Be at least 13 years of age\n- Comply with all applicable laws\n\nYou are responsible for all activities under your account.'**
  String get termsAccountsBody;

  /// No description provided for @termsSubscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription and Payment'**
  String get termsSubscriptionTitle;

  /// No description provided for @termsSubscriptionBody.
  ///
  /// In en, this message translates to:
  /// **'Premium Subscription:\n\n- Monthly subscription: \\\${price}/month\n- Free users: {freeScans} scans per month\n- Premium users: Unlimited scans\n- Auto-renewal unless cancelled\n- Refunds subject to app store policies\n\nSubscriptions are managed through your app store account.'**
  String termsSubscriptionBody(String price, String freeScans);

  /// No description provided for @termsHealthDisclaimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Health Disclaimer'**
  String get termsHealthDisclaimerTitle;

  /// No description provided for @termsHealthDisclaimerBody.
  ///
  /// In en, this message translates to:
  /// **'IMPORTANT - PLEASE READ:\n\n- ScanBite is NOT a medical device\n- Information provided is for educational purposes only\n- Do NOT use as a substitute for professional medical advice\n- Consult healthcare providers for medical decisions\n- We do not guarantee accuracy of nutritional information\n- Users with medical conditions should seek professional guidance\n- Allergen detection may not be comprehensive\n\nUSE AT YOUR OWN RISK.'**
  String get termsHealthDisclaimerBody;

  /// No description provided for @termsAcceptableUseTitle.
  ///
  /// In en, this message translates to:
  /// **'Acceptable Use'**
  String get termsAcceptableUseTitle;

  /// No description provided for @termsAcceptableUseBody.
  ///
  /// In en, this message translates to:
  /// **'You agree NOT to:\n\n- Violate any laws or regulations\n- Infringe on intellectual property rights\n- Upload malicious code or viruses\n- Attempt to gain unauthorized access\n- Reverse engineer the application\n- Use the app for commercial purposes without permission\n- Harass or harm other users\n- Misrepresent your identity'**
  String get termsAcceptableUseBody;

  /// No description provided for @termsIpTitle.
  ///
  /// In en, this message translates to:
  /// **'Intellectual Property'**
  String get termsIpTitle;

  /// No description provided for @termsIpBody.
  ///
  /// In en, this message translates to:
  /// **'All content, features, and functionality are owned by ScanBite and protected by copyright, trademark, and other intellectual property laws.'**
  String get termsIpBody;

  /// No description provided for @termsUserContentTitle.
  ///
  /// In en, this message translates to:
  /// **'User Content'**
  String get termsUserContentTitle;

  /// No description provided for @termsUserContentBody.
  ///
  /// In en, this message translates to:
  /// **'By uploading content to ScanBite, you grant us a license to use, store, and process your content while retaining ownership.'**
  String get termsUserContentBody;

  /// No description provided for @termsLiabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Limitation of Liability'**
  String get termsLiabilityTitle;

  /// No description provided for @termsLiabilityBody.
  ///
  /// In en, this message translates to:
  /// **'To the maximum extent permitted by law, we are not liable for indirect, incidental, or consequential damages.'**
  String get termsLiabilityBody;

  /// No description provided for @termsIndemnificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Indemnification'**
  String get termsIndemnificationTitle;

  /// No description provided for @termsIndemnificationBody.
  ///
  /// In en, this message translates to:
  /// **'You agree to indemnify and hold ScanBite harmless from any claims arising from your use of the app.'**
  String get termsIndemnificationBody;

  /// No description provided for @termsTerminationTitle.
  ///
  /// In en, this message translates to:
  /// **'Termination'**
  String get termsTerminationTitle;

  /// No description provided for @termsTerminationBody.
  ///
  /// In en, this message translates to:
  /// **'We may terminate or suspend your account for violations of these terms or at our discretion.'**
  String get termsTerminationBody;

  /// No description provided for @termsChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Changes to Terms'**
  String get termsChangesTitle;

  /// No description provided for @termsChangesBody.
  ///
  /// In en, this message translates to:
  /// **'We reserve the right to modify these terms at any time. Continued use after changes constitutes acceptance.'**
  String get termsChangesBody;

  /// No description provided for @termsGoverningLawTitle.
  ///
  /// In en, this message translates to:
  /// **'Governing Law'**
  String get termsGoverningLawTitle;

  /// No description provided for @termsGoverningLawBody.
  ///
  /// In en, this message translates to:
  /// **'These terms shall be governed by the laws of your jurisdiction.'**
  String get termsGoverningLawBody;

  /// No description provided for @termsDisputeTitle.
  ///
  /// In en, this message translates to:
  /// **'Dispute Resolution'**
  String get termsDisputeTitle;

  /// No description provided for @termsDisputeBody.
  ///
  /// In en, this message translates to:
  /// **'Disputes should first be resolved informally before mediation or arbitration.'**
  String get termsDisputeBody;

  /// No description provided for @termsContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get termsContactTitle;

  /// No description provided for @termsContactBody.
  ///
  /// In en, this message translates to:
  /// **'For questions about these Terms:\n\nEmail: alerttmenow@gmail.com\nWebsite: www.an2app.com/scanbite.com'**
  String get termsContactBody;

  /// No description provided for @termsSeverabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Severability'**
  String get termsSeverabilityTitle;

  /// No description provided for @termsSeverabilityBody.
  ///
  /// In en, this message translates to:
  /// **'If any provision is unenforceable, the remaining provisions remain in effect.'**
  String get termsSeverabilityBody;

  /// No description provided for @aiFoodNutritionScanner.
  ///
  /// In en, this message translates to:
  /// **'AI Food Nutrition Scanner'**
  String get aiFoodNutritionScanner;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @dontHaveAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAnAccount;

  /// No description provided for @pleaseEnterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterYourEmail;

  /// No description provided for @pleaseEnterAValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterAValidEmail;

  /// No description provided for @pleaseEnterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterYourPassword;

  /// No description provided for @passwordMinChars.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinChars;

  /// No description provided for @testNotification.
  ///
  /// In en, this message translates to:
  /// **'Test Notification'**
  String get testNotification;

  /// No description provided for @testNotificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap to send a test notification'**
  String get testNotificationSubtitle;

  /// No description provided for @testNotificationSent.
  ///
  /// In en, this message translates to:
  /// **'Test notification sent! Check your notification tray.'**
  String get testNotificationSent;

  /// No description provided for @testButton.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get testButton;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @adminPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'ADMIN PANEL'**
  String get adminPanelTitle;

  /// No description provided for @adminPanelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage all users'**
  String get adminPanelSubtitle;

  /// No description provided for @subscriptionSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscriptionSectionTitle;

  /// No description provided for @premiumSubscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Premium Subscription'**
  String get premiumSubscriptionTitle;

  /// No description provided for @unlimitedScans.
  ///
  /// In en, this message translates to:
  /// **'Active - Unlimited Scans'**
  String get unlimitedScans;

  /// No description provided for @freeScansRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} free scans remaining'**
  String freeScansRemaining(int count);

  /// No description provided for @familyPlanTileTitle.
  ///
  /// In en, this message translates to:
  /// **'Family Plan'**
  String get familyPlanTileTitle;

  /// No description provided for @familyPlanCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Family Plan Code'**
  String get familyPlanCodeTitle;

  /// No description provided for @refreshCodeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh code'**
  String get refreshCodeTooltip;

  /// No description provided for @familyCodeRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Family code refreshed!'**
  String get familyCodeRefreshed;

  /// No description provided for @familyCodeInstruction.
  ///
  /// In en, this message translates to:
  /// **'Share this code with your family members. They enter it in Settings → Family Plan.'**
  String get familyCodeInstruction;

  /// No description provided for @familyCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Family code copied!'**
  String get familyCodeCopied;

  /// No description provided for @copyButton.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyButton;

  /// No description provided for @shareButton.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareButton;

  /// No description provided for @manageFamilyMembersButton.
  ///
  /// In en, this message translates to:
  /// **'Manage Family Members'**
  String get manageFamilyMembersButton;

  /// No description provided for @familyCodeSubtitleOwner.
  ///
  /// In en, this message translates to:
  /// **'Tap below to retrieve your family code'**
  String get familyCodeSubtitleOwner;

  /// No description provided for @familyCodeSubtitleMember.
  ///
  /// In en, this message translates to:
  /// **'Connected to a family plan'**
  String get familyCodeSubtitleMember;

  /// No description provided for @familyCodeSubtitleJoin.
  ///
  /// In en, this message translates to:
  /// **'Join with a 6-character code'**
  String get familyCodeSubtitleJoin;

  /// No description provided for @retrieveFamilyCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Retrieve Family Code'**
  String get retrieveFamilyCodeButton;

  /// No description provided for @loadingText.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingText;

  /// No description provided for @subscriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Subscription Required'**
  String get subscriptionRequired;

  /// No description provided for @subscriptionRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'You need an active subscription to create or view a Family Plan code. Please subscribe to continue.'**
  String get subscriptionRequiredMessage;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @subscribeNow.
  ///
  /// In en, this message translates to:
  /// **'Subscribe Now'**
  String get subscribeNow;

  /// No description provided for @familyCodeLoadedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Family code loaded successfully!'**
  String get familyCodeLoadedSuccess;

  /// No description provided for @noFamilyCodeFound.
  ///
  /// In en, this message translates to:
  /// **'No family code found. Please contact support if you believe this is an error.'**
  String get noFamilyCodeFound;

  /// No description provided for @errorLoadingFamilyCode.
  ///
  /// In en, this message translates to:
  /// **'Error loading family code'**
  String get errorLoadingFamilyCode;

  /// No description provided for @shareFamilySubject.
  ///
  /// In en, this message translates to:
  /// **'Join My ScanBite Family Plan'**
  String get shareFamilySubject;

  /// No description provided for @shareFamilyMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Join my ScanBite Family Plan!'**
  String get shareFamilyMessageTitle;

  /// No description provided for @shareFamilyCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Family Code'**
  String get shareFamilyCodeLabel;

  /// No description provided for @shareFamilyInstructions.
  ///
  /// In en, this message translates to:
  /// **'Open ScanBite → Settings → Family Plan → Enter Code'**
  String get shareFamilyInstructions;

  /// No description provided for @yourFamilyCode.
  ///
  /// In en, this message translates to:
  /// **'Your Family Code'**
  String get yourFamilyCode;

  /// No description provided for @familyMembers.
  ///
  /// In en, this message translates to:
  /// **'Family Members'**
  String get familyMembers;

  /// No description provided for @monthlyCostBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Monthly Cost Breakdown'**
  String get monthlyCostBreakdown;

  /// No description provided for @basePlan.
  ///
  /// In en, this message translates to:
  /// **'Base Plan ({count} members)'**
  String basePlan(int count);

  /// No description provided for @totalMonthlyCost.
  ///
  /// In en, this message translates to:
  /// **'Total Monthly Cost'**
  String get totalMonthlyCost;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'OWNER'**
  String get owner;

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy Code'**
  String get copyCode;

  /// No description provided for @selectLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguageTitle;

  /// No description provided for @languageSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Language saved: {language}'**
  String languageSavedMessage(String language);

  /// No description provided for @rateThisApp.
  ///
  /// In en, this message translates to:
  /// **'Rate this app'**
  String get rateThisApp;

  /// No description provided for @rateThisAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Leave a rating & comment'**
  String get rateThisAppSubtitle;

  /// No description provided for @ratingsInboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Ratings Inbox'**
  String get ratingsInboxTitle;

  /// No description provided for @ratingsInboxSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View & reply to user ratings'**
  String get ratingsInboxSubtitle;

  /// No description provided for @rateAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate this App'**
  String get rateAppTitle;

  /// No description provided for @rateAppQuestion.
  ///
  /// In en, this message translates to:
  /// **'How\'s your experience?'**
  String get rateAppQuestion;

  /// No description provided for @rateAppHint.
  ///
  /// In en, this message translates to:
  /// **'Write a comment (visible to all users)'**
  String get rateAppHint;

  /// No description provided for @rateAppSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get rateAppSubmitting;

  /// No description provided for @rateAppSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get rateAppSubmit;

  /// No description provided for @rateAppDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Your review will be posted publicly. We\'ll also open an email to support so you can get a response.'**
  String get rateAppDisclaimer;

  /// No description provided for @rateAppRecentReviews.
  ///
  /// In en, this message translates to:
  /// **'Recent reviews'**
  String get rateAppRecentReviews;

  /// No description provided for @rateAppNoReviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet.'**
  String get rateAppNoReviews;

  /// No description provided for @rateAppDeveloperResponse.
  ///
  /// In en, this message translates to:
  /// **'Developer response'**
  String get rateAppDeveloperResponse;

  /// No description provided for @rateAppSignInFirst.
  ///
  /// In en, this message translates to:
  /// **'Please sign in first.'**
  String get rateAppSignInFirst;

  /// No description provided for @rateAppWriteComment.
  ///
  /// In en, this message translates to:
  /// **'Please write a comment.'**
  String get rateAppWriteComment;

  /// No description provided for @rateAppCommentTooLong.
  ///
  /// In en, this message translates to:
  /// **'Comment is too long (max 500 characters).'**
  String get rateAppCommentTooLong;

  /// No description provided for @rateAppThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks! Your review was posted.'**
  String get rateAppThanks;

  /// No description provided for @rateAppFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit rating. Please try again.'**
  String get rateAppFailed;

  /// No description provided for @rateAppEmailSubject.
  ///
  /// In en, this message translates to:
  /// **'ScanBite App Rating'**
  String get rateAppEmailSubject;

  /// No description provided for @adminRatingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Ratings Inbox'**
  String get adminRatingsTitle;

  /// No description provided for @adminRatingsNoReviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet.'**
  String get adminRatingsNoReviews;

  /// No description provided for @adminRatingsReplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Reply to user'**
  String get adminRatingsReplyTitle;

  /// No description provided for @adminRatingsReplyHint.
  ///
  /// In en, this message translates to:
  /// **'Write your reply...'**
  String get adminRatingsReplyHint;

  /// No description provided for @adminRatingsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get adminRatingsCancel;

  /// No description provided for @adminRatingsSaveReply.
  ///
  /// In en, this message translates to:
  /// **'Save Reply'**
  String get adminRatingsSaveReply;

  /// No description provided for @adminRatingsReplyPosted.
  ///
  /// In en, this message translates to:
  /// **'Reply posted.'**
  String get adminRatingsReplyPosted;

  /// No description provided for @adminRatingsYourReply.
  ///
  /// In en, this message translates to:
  /// **'Your reply'**
  String get adminRatingsYourReply;

  /// No description provided for @adminRatingsEditReply.
  ///
  /// In en, this message translates to:
  /// **'Edit Reply'**
  String get adminRatingsEditReply;

  /// No description provided for @adminRatingsAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'You do not have admin access.'**
  String get adminRatingsAccessDenied;

  /// No description provided for @adminRatingsReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get adminRatingsReply;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
