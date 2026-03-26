import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/hush_user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _firebaseUser;
  HushUser? _hushUser;
  bool _loading = true;

  User? get firebaseUser => _firebaseUser;
  HushUser? get hushUser => _hushUser;
  bool get loading => _loading;
  bool get isAuthenticated => _firebaseUser != null;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;
    if (user != null) {
      _hushUser = await _authService.getUserProfile(user.uid);
    } else {
      _hushUser = null;
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    try {
      final user = await _authService.signInWithGoogle();
      return user != null;
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      return false;
    }
  }

  Future<bool> signInWithApple() async {
    try {
      final user = await _authService.signInWithApple();
      return user != null;
    } catch (e) {
      debugPrint('Apple sign-in error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<void> refreshProfile() async {
    if (_firebaseUser != null) {
      _hushUser = await _authService.getUserProfile(_firebaseUser!.uid);
      notifyListeners();
    }
  }
}
