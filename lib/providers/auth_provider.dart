import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/hush_user.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

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
          notifyListeners();
        }
      });
      
      // Initial fetch to ensure loading finishes quickly
      _hushUser = await _authService.getUserProfile(user.uid);
      
      // Initialize push notifications
      await NotificationService().init(user.uid);
    } else {
      _hushUser = null;
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
