import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class PresenceService with WidgetsBindingObserver {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;

  PresenceService._internal();

  FirebaseDatabase get _db => FirebaseDatabase.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;
  
  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    _initialized = true;

    WidgetsBinding.instance.addObserver(this);

    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _setUserOnline(user.uid);
      }
    });
  }

  void _setUserOnline(String uid) {
    final userStatusRef = _db.ref('status/$uid');
    
    // Create a reference to the special '.info/connected' path in Realtime Database
    final connectedRef = _db.ref('.info/connected');

    connectedRef.onValue.listen((event) {
      final isConnected = event.snapshot.value as bool? ?? false;
      if (isConnected) {
        // When we disconnect, update the status to offline
        userStatusRef.onDisconnect().set({
          'state': 'offline',
          'lastChanged': ServerValue.timestamp,
        }).then((_) {
          // Once the onDisconnect is queued up, set the status to online
          userStatusRef.set({
            'state': 'online',
            'lastChanged': ServerValue.timestamp,
          });
        });
      }
    });
  }

  void _setUserOffline() {
    final user = _auth.currentUser;
    if (user != null) {
      _db.ref('status/${user.uid}').set({
        'state': 'offline',
        'lastChanged': ServerValue.timestamp,
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final user = _auth.currentUser;
    if (user == null) return;

    if (state == AppLifecycleState.resumed) {
      _db.ref('status/${user.uid}').set({
        'state': 'online',
        'lastChanged': ServerValue.timestamp,
      });
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _setUserOffline();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}
