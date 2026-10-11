import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io' show Platform;
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:screen_protector/screen_protector.dart';

import '../models/hush_user.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../main.dart' show rootNavigatorKey;
import '../config/theme.dart' show HushColors;

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _firebaseUser;
  HushUser? _hushUser;
  bool _loading = true;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  bool _isAuthenticated = false;

  User? get firebaseUser => _firebaseUser;
  HushUser? get hushUser => _hushUser;
  bool get loading => _loading;
  bool get isAuthenticated => _isAuthenticated;

  static const _screenshotChannel = MethodChannel('com.chiprut.hushhh/screenshot');

  /// iOS only: whether ScreenProtector is currently applied (null = unknown).
  bool? _iosProtectionActive;

  /// Whether screenshot protection is temporarily scoped off for non-sensitive
  /// screens (settings, profile, onboarding) where camera/gallery modals run.
  bool _screenProtectionScopedDisabled = false;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
    _setupScreenshotListener();
  }

  void _setupScreenshotListener() {
    if (!Platform.isIOS) return;
    try {
      ScreenProtector.addListener(() {
        debugPrint('Screenshot detected on iOS');
        final ctx = rootNavigatorKey.currentContext;
        if (ctx != null) {
          try {
            final isHe = Localizations.localeOf(ctx).languageCode == 'he';
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(
                  isHe
                      ? 'התוכן ב-Hushhh מוגן – צילום מסך אינו מורשה'
                      : 'Content in Hushhh is protected – screenshots are not allowed',
                ),
                backgroundColor: HushColors.tierRed,
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } catch (_) {}
        }
      }, null);
    } catch (e) {
      debugPrint('ScreenProtector addListener error: $e');
    }
  }

  /// Temporarily disables screen protection while on non-sensitive screens
  /// (Settings, Profile, Onboarding) where native modals (photo pickers) run.
  Future<void> disableScreenProtectionForScreen() async {
    _screenProtectionScopedDisabled = true;
    if (Platform.isIOS) {
      if (_iosProtectionActive == true) {
        try {
          await ScreenProtector.preventScreenshotOff();
          _iosProtectionActive = false;
        } catch (e) {
          debugPrint('ScreenProtector disable error: $e');
        }
      }
    }
  }

  /// Restores screen protection when returning to sensitive screens (Feed, Map).
  Future<void> enableScreenProtectionForScreen() async {
    _screenProtectionScopedDisabled = false;
    await _updateScreenshotPolicy();
  }

  /// Deprecated aliases for backwards compatibility.
  Future<void> suspendScreenProtection() => disableScreenProtectionForScreen();
  Future<void> resumeScreenProtection() => enableScreenProtectionForScreen();

  Future<void> _updateScreenshotPolicy() async {
    final bool enablePrevention = _hushUser?.isAdmin != true && _hushUser?.canScreenshot != true;

    if (Platform.isIOS) {
      final bool shouldEnable = enablePrevention && !_screenProtectionScopedDisabled;
      if (_iosProtectionActive == shouldEnable) return;
      try {
        if (shouldEnable) {
          await ScreenProtector.preventScreenshotOn();
        } else {
          await ScreenProtector.preventScreenshotOff();
        }
        _iosProtectionActive = shouldEnable;
      } catch (e) {
        debugPrint('ScreenProtector plugin error: $e');
      }
    } else if (Platform.isAndroid) {
      try {
        if (enablePrevention) {
          await _screenshotChannel.invokeMethod('enableScreenshotPrevention');
        } else {
          await _screenshotChannel.invokeMethod('disableScreenshotPrevention');
        }
      } catch (e) {
        debugPrint('Native screenshot channel error: $e');
      }
    }
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;
    _isAuthenticated = user != null;
    
    // Notify immediately so the UI can show a spinner if user is non-null
    // rather than getting stuck on the LoginScreen if Firestore hangs
    notifyListeners();
    
    // Cancel existing subscription
    _userSubscription?.cancel();
    
    if (user != null) {
      try {
        await _authService.ensureUserProfile(user).timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint('Failed to ensure user profile on auth change: $e');
        // We continue so the listener can at least try to attach
      }

      // Start real-time listener for user profile
      _userSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          final prevIsAdmin = _hushUser?.isAdmin;
          _hushUser = HushUser.fromFirestore(snapshot);
          // Only update screenshot policy when admin status changes, not on every field update
          // (avoids repeated Toast popups when saving/liking changes the user doc)
          if (_hushUser?.isAdmin != prevIsAdmin) {
            _updateScreenshotPolicy();
          }
          notifyListeners();
        }
      }, onError: (e) {
        debugPrint('Error listening to user profile: $e');
      });
      
      try {
        // Initial fetch to ensure loading finishes quickly
        _hushUser = await _authService.getUserProfile(user.uid).timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint('Failed to fetch user profile: $e');
      }
      
      _updateScreenshotPolicy();
      
      // We removed NotificationService().init() from here.
      // It is now initialized in FeedScreen after location permission is resolved,
      // to prevent iOS permission dialog collision which caused the app to hang.
    } else {
      _hushUser = null;
      _updateScreenshotPolicy();
    }
    _loading = false;
    notifyListeners();
  }

  Future<String?> signInWithGoogle() async {
    try {
      final user = await _authService.signInWithGoogle();
      return user != null ? null : 'User cancelled sign in';
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      return e.toString();
    }
  }

  Future<String?> signInWithApple() async {
    try {
      final user = await _authService.signInWithApple();
      return user != null ? null : 'User cancelled sign in';
    } catch (e) {
      debugPrint('Apple sign-in error: $e');
      return e.toString();
    }
  }

  Future<void> signOut() async {
    if (_firebaseUser != null) {
      await NotificationService().clearToken(_firebaseUser!.uid);
    }
    await _authService.signOut();
    _firebaseUser = null;
    _hushUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    if (_firebaseUser != null) {
      _hushUser = await _authService.getUserProfile(_firebaseUser!.uid);
      notifyListeners();
    }
  }
}
