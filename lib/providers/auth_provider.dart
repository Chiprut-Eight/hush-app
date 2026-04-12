import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/hush_user.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

import 'package:screen_protector/screen_protector.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _firebaseUser;
  HushUser? _hushUser;
  bool _loading = true;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  User? get firebaseUser => _firebaseUser;
  HushUser? get hushUser => _hushUser;
  bool get loading => _loading;
  bool get isAuthenticated => _firebaseUser != null;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  static const _screenshotChannel = MethodChannel('com.hush.app/screenshot');

  Future<void> _updateScreenshotPolicy() async {
    final bool enablePrevention = _hushUser?.isAdmin != true;
    
    // 1. Cross-platform plugin (iOS + Android)
    try {
      if (enablePrevention) {
        await ScreenProtector.preventScreenshotOn();
      } else {
        await ScreenProtector.preventScreenshotOff();
      }
    } catch (e) {
      debugPrint('ScreenProtector plugin error: $e');
    }

    // 2. Fallback native Android channel (FLAG_SECURE)
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

  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;
    
    // Cancel existing subscription
    _userSubscription?.cancel();
    
    if (user != null) {
      // Start real-time listener for user profile
      _userSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          _hushUser = HushUser.fromFirestore(snapshot);
          _updateScreenshotPolicy();
          notifyListeners();
        }
      });
      
      // Initial fetch to ensure loading finishes quickly
      _hushUser = await _authService.getUserProfile(user.uid);
      _updateScreenshotPolicy();
      
      // Initialize push notifications
      await NotificationService().init(user.uid);
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
    _userSubscription?.cancel();
    await _authService.signOut();
  }

  Future<void> refreshProfile() async {
    if (_firebaseUser != null) {
      _hushUser = await _authService.getUserProfile(_firebaseUser!.uid);
      notifyListeners();
    }
  }
}
