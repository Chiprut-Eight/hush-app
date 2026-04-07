import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:hush_app/l10n/app_localizations.dart';
import 'config/firebase_options.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/ui_provider.dart';
import 'screens/login_screen.dart';
import 'screens/app_shell.dart';
import 'screens/onboarding_screen.dart';

/// Admin UID — same constant used in profile_screen.dart
const String _adminUid = String.fromEnvironment('ADMIN_UID', defaultValue: 'A30Br3OakdXF5BnfQFu5pryOsgy2');

/// MethodChannel for screenshot prevention (Android native FLAG_SECURE)
const _screenshotChannel = MethodChannel('com.hush.app/screenshot');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const HushApp());
}

class HushApp extends StatelessWidget {
  const HushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => UIProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
            title: 'HUSH',
            debugShowCheckedModeBanner: false,
            theme: hushTheme(),
            locale: localeProvider.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            builder: (context, child) {
              return Material(
                color: Colors.transparent, // Background removal for top area
                child: Column(
                  children: [
                    SafeArea(
                      bottom: false,
                      child: Container(
                        padding: const EdgeInsets.only(left: 20.0, top: 4.0, bottom: 4.0),
                        alignment: Alignment.centerLeft, // Always physical left regardless of RTL
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Image.asset(
                            'assets/images/top_banner.png',
                            width: MediaQuery.of(context).size.width * 0.38, // Shrunk from 0.45
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: HushColors.bgPrimary, // Apply global background to screens
                        child: MediaQuery.removePadding(
                          context: context,
                          removeTop: true,
                          child: child ?? const SizedBox.shrink(),
                        ),
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

  /// Apply screenshot prevention policy based on admin status
  void _applyScreenshotPolicy(AuthProvider auth) {
    if (auth.isAuthenticated && auth.firebaseUser != null) {
      final isAdmin = auth.firebaseUser!.uid == _adminUid;
      if (isAdmin) {
        _screenshotChannel.invokeMethod('disableScreenshotPrevention');
      } else {
        _screenshotChannel.invokeMethod('enableScreenshotPrevention');
      }
    }
  }
}
