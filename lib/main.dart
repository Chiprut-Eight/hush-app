import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:hush_app/l10n/app_localizations.dart';
import 'config/firebase_options.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/onboarding_screen.dart';
import 'package:confetti/confetti.dart';
import 'dart:async';
import 'providers/ui_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';
import 'services/analytics_service.dart';
import 'screens/login_screen.dart';
import 'screens/app_shell.dart';
import 'widgets/hush_drawer.dart';
import 'widgets/animated_app_bar.dart';

/// Global Navigator Key for top-level navigation and back handling
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Admin UID — same constant used in profile_screen.dart
const String _adminUid = String.fromEnvironment('ADMIN_UID', defaultValue: 'A30Br3OakdXF5BnfQFu5pryOsgy2');

/// MethodChannel for screenshot prevention (Android native FLAG_SECURE)
const _screenshotChannel = MethodChannel('com.chiprut.hushhh/screenshot');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register FCM background handler (must be top-level)
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const HushApp());
}

class HushApp extends StatefulWidget {
  const HushApp({super.key});

  @override
  State<HushApp> createState() => _HushAppState();
}

class _HushAppState extends State<HushApp> {
  late ConfettiController _confettiController;
  StreamSubscription? _uiSubscription;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _uiSubscription?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => UIProvider()),
      ],
      child: Consumer2<LocaleProvider, ThemeProvider>(
        builder: (context, localeProvider, themeProvider, _) {
          // Listen for confetti trigger from UIProvider
          _uiSubscription ??= context.read<UIProvider>().confettiStream.listen((_) {
            _confettiController.play();
          });

          final currentTheme = hushDarkTheme();

          return MaterialApp(
            title: 'HUSH',
            debugShowCheckedModeBanner: false,
            navigatorKey: rootNavigatorKey,
            theme: currentTheme,
            locale: localeProvider.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            navigatorObservers: [AnalyticsService().observer],
            builder: (context, child) {
              return Scaffold(
                backgroundColor: Colors.transparent,
                resizeToAvoidBottomInset: false,
                drawer: const HushDrawer(),
                body: Stack(
                  children: [
                    Material(
                    color: Colors.transparent, // Background removal for top area
                    child: Column(
                      children: [
                        // Unified Animated AppBar
                        const AnimatedAppBar(),
                        Expanded(
                          child: Container(
                            color: currentTheme.scaffoldBackgroundColor, // Apply dynamic background
                            child: MediaQuery.removePadding(
                              context: context,
                              removeTop: true,
                              child: child ?? const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Global Celebration Layer
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
                      shouldLoop: false,
                      colors: const [
                        HushColors.textAccent,
                        HushColors.tierRed,
                        Colors.amber,
                        Colors.white,
                      ],
                      gravity: 0.1,
                    ),
                    ),
                  ],
                ),
              );
            },
            home: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                // Task 12: Screenshot prevention — enable FLAG_SECURE for non-admin
                _applyScreenshotPolicy(auth);

                if (auth.loading) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (auth.isAuthenticated) {
                  if (auth.hushUser == null) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (!auth.hushUser!.isOnboarded) {
                    return const OnboardingScreen();
                  }
                  return const AppShell();
                }
                return const LoginScreen();
              },
            ),
          );
        },
      ),
    );
  }

  /// Apply screenshot prevention policy based on admin/tester status
  void _applyScreenshotPolicy(AuthProvider auth) {
    if (auth.isAuthenticated && auth.firebaseUser != null) {
      final isAdmin = auth.firebaseUser!.uid == _adminUid;
      final canScreenshot = auth.hushUser?.canScreenshot == true;
      if (isAdmin || canScreenshot) {
        _screenshotChannel.invokeMethod('disableScreenshotPrevention');
      } else {
        _screenshotChannel.invokeMethod('enableScreenshotPrevention');
      }
    }
  }
}
