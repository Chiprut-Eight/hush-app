import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

/// Firebase configuration options for the HUSH app.
/// Generated manually since flutterfire_cli failed due to path encoding.
///
/// These values come from the existing Firebase project (hush-7bab0).
/// The Android-specific values (appId) will need to be updated after
/// registering an Android app in the Firebase Console.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  /// Web configuration (existing)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDjWq7tglRokKa6WpPlZgUSNB1KHuMyG00',
    appId: '1:187237532355:web:934514ffdaa37304a2d876',
    messagingSenderId: '187237532355',
    projectId: 'hush-7bab0',
    authDomain: 'hush-7bab0.web.app',
    storageBucket: 'hush-7bab0.firebasestorage.app',
  );

  /// Android configuration
  /// NOTE: The appId below is a PLACEHOLDER.
  /// You must register an Android app in Firebase Console with package name
  /// 'com.hush.hush_app' and replace the appId with the real value.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAAn2gawmN1RUBXkaL61-hKNHznzdXh8as',
    appId: '1:187237532355:android:beae06757656abd0a2d876',
    messagingSenderId: '187237532355',
    projectId: 'hush-7bab0',
    storageBucket: 'hush-7bab0.firebasestorage.app',
  );

  /// iOS configuration
  /// NOTE: The appId below is a PLACEHOLDER.
  /// You must register an iOS app in Firebase Console with bundle ID
  /// 'com.hush.hushApp' and replace the appId with the real value.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDjWq7tglRokKa6WpPlZgUSNB1KHuMyG00',
    appId: '1:187237532355:ios:PLACEHOLDER_REPLACE_ME',
    messagingSenderId: '187237532355',
    projectId: 'hush-7bab0',
    storageBucket: 'hush-7bab0.firebasestorage.app',
    iosBundleId: 'com.hush.hushApp',
  );
}
