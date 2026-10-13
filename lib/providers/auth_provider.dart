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
import '../services/analytics_service.dart';
import '../main.dart' show rootNavigatorKey;
import '../widgets/top_banner_notification.dart';

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

  /// Broadcast stream to notify UI components (e.g., open secrets) when a screenshot is detected on iOS.
  final _screenshotTakenController = StreamController<void>.broadcast();
  Stream<void> get screenshotTakenStream => _screenshotTakenController.stream;

  /// Broadcast stream to notify UI components when screen recording status changes on iOS.
  final _screenRecordingController = StreamController<bool>.broadcast();
  Stream<bool> get screenRecordingStream => _screenRecordingController.stream;
  bool _isScreenRecording = false;
  bool get isScreenRecording => _isScreenRecording;

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
      // Ensure any legacy UITextField overlay is permanently removed on iOS
      ScreenProtector.preventScreenshotOff().catchError((_) {});

      ScreenProtector.addListener(() {
        debugPrint('[AuthProvider] Screenshot detected on iOS');

        // Allow admins and users with explicit permission to screenshot without warnings
        if (_hushUser?.isAdmin == true || _hushUser?.canScreenshot == true) {
          return;
        }

        // Notify open secrets to immediately collapse/re-lock
        _screenshotTakenController.add(null);

        // Immediate tactile warning
        HapticFeedback.heavyImpact();

        // Log analytics event
        AnalyticsService().logScreenshotDetected();

        final ctx = rootNavigatorKey.currentContext;
        if (ctx != null) {
          try {
            final isHe = Localizations.localeOf(ctx).languageCode == 'he';
            TopBannerNotification.show(
              context: ctx,
              message: isHe
                  ? 'התוכן ב-Hushhh מוגן – צילום מסך אינו מורשה'
                  : 'Content in Hushhh is protected – screenshots are not allowed',
              icon: Icons.shield_outlined,
            );
          } catch (_) {}
        }
      }, (isRecording) {
        final bool recording = isRecording == true;
        debugPrint('[AuthProvider] Screen recording status changed on iOS: $recording');
        _isScreenRecording = recording;
        _screenRecordingController.add(recording);

        if (recording) {
          // Immediately re-lock secrets and pause audio
          _screenshotTakenController.add(null);
          HapticFeedback.heavyImpact();
          AnalyticsService().logScreenshotDetected();

          final ctx = rootNavigatorKey.currentContext;
          if (ctx != null) {
            try {
              final isHe = Localizations.localeOf(ctx).languageCode == 'he';
              TopBannerNotification.show(
                context: ctx,
                message: isHe
                    ? 'הקלטת מסך פעילה – הצפייה וההאזנה להאשש חסומות'
                    : 'Screen recording is active – Hushhh viewing and audio disabled',
                icon: Icons.videocam_off_outlined,
              );
            } catch (_) {}
          }
        }
      });
    } catch (e) {
      debugPrint('ScreenProtector addListener error: $e');
    }
  }

  /// Temporarily disables screen protection while on non-sensitive screens
  /// (Settings, Profile, Onboarding) where native modals (photo pickers) run.
  Future<void> disableScreenProtectionForScreen() async {
    _screenProtectionScopedDisabled = true;
    if (Platform.isAndroid) {
      await _updateScreenshotPolicy();
    }
  }

  /// Restores screen protection when returning to sensitive screens (Feed, Map, Profile).
  Future<void> enableScreenProtectionForScreen() async {
    _screenProtectionScopedDisabled = false;
    await _updateScreenshotPolicy();
  }

  /// Deprecated aliases for backwards compatibility.
  Future<void> suspendScreenProtection() => disableScreenProtectionForScreen();
  Future<void> resumeScreenProtection() => enableScreenProtectionForScreen();

  Future<void> _updateScreenshotPolicy() async {
    final bool enablePrevention = _hushUser?.isAdmin != true && _hushUser?.canScreenshot != true;

    if (Platform.isAndroid) {
      final bool shouldEnable = enablePrevention && !_screenProtectionScopedDisabled;
      try {
        if (shouldEnable) {
          await _screenshotChannel.invokeMethod('enableScreenshotPrevention');
        } else {
          await _screenshotChannel.invokeMethod('disableScreenshotPrevention');
        }
      } catch (e) {
        debugPrint('Native screenshot channel error: $e');
      }
    } else if (Platform.isIOS) {
      // In iOS (Option A): We rely on the official screenshot listener (addListener)
      // and do NOT call preventScreenshotOn() which breaks the UIKit layer causing black screen.
      try {
        await ScreenProtector.preventScreenshotOff();
      } catch (_) {}
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

  @override
  void dispose() {
    _screenRecordingController.close();
    _screenshotTakenController.close();
    _userSubscription?.cancel();
    super.dispose();
  }
}
