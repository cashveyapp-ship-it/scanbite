import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/ratings_notice_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/scan_provider.dart';
import 'providers/locale_provider.dart';
import 'utils/constants.dart';
import 'gen_l10n/app_localizations.dart';
import 'services/notification_service.dart';
import 'services/subscription_service.dart';
import 'screens/auth_gate.dart';
import 'firebase_options.dart';

// TODO: uncomment both lines when ready for App Check

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  await NotificationService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ScanProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => RatingsNoticeProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            locale: localeProvider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppConstants.primaryColor,
                primary: AppConstants.primaryColor,
                secondary: AppConstants.secondaryColor,
              ),
              useMaterial3: true,
              textTheme: GoogleFonts.interTextTheme(),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            home: const AppLifecycleHandler(
              child: AuthGate(),
            ),
          );
        },
      ),
    );
  }
}

class AppLifecycleHandler extends StatefulWidget {
  final Widget child;

  const AppLifecycleHandler({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<AppLifecycleHandler> createState() => _AppLifecycleHandlerState();
}

class _AppLifecycleHandlerState extends State<AppLifecycleHandler>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final authProvider = context.read<AuthProvider>();
      authProvider.refreshProfileIfNeeded();

      // Check for expired subscriptions on every foreground ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â cascades
      // revoke to family members if the owner's sub has lapsed
      final userId = authProvider.user?.uid;
      if (userId != null) {
        SubscriptionService().checkAndHandleExpiry(userId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
