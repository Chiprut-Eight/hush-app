import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../models/hush_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with Google (native SDK)
  Future<User?> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null; // user cancelled

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final result = await _auth.signInWithCredential(credential);
    if (result.user != null) {
      await _ensureUserProfile(result.user!);
    }
    return result.user;
  }

  /// Sign in with Apple (native SDK)
  Future<User?> signInWithApple() async {
    // Generate nonce for security
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
      accessToken: appleCredential.authorizationCode,
    );

    final result = await _auth.signInWithCredential(oauthCredential);
    if (result.user != null) {
      // Apple only provides name on first sign-in — capture it and update Firebase Auth profile
      final givenName = appleCredential.givenName;
      final familyName = appleCredential.familyName;
      if (givenName != null || familyName != null) {
        final fullName = [givenName, familyName].where((s) => s != null && s.isNotEmpty).join(' ');
        if (fullName.isNotEmpty && (result.user!.displayName == null || result.user!.displayName!.isEmpty)) {
          await result.user!.updateDisplayName(fullName);
          await result.user!.reload();
        }
      }
      await _ensureUserProfile(_auth.currentUser ?? result.user!);
    }
    return result.user;
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  Future<HushUser?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return HushUser.fromFirestore(doc);
  }

  /// Create user profile in Firestore if it doesn't exist
  /// Also updates displayName for existing users if it's missing
  Future<void> _ensureUserProfile(User user) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final userSnap = await userRef.get();

    String? emailPrefix;
    if (user.email != null && !user.email!.endsWith('@privaterelay.appleid.com')) {
      emailPrefix = user.email!.split('@').first;
    }
    
    final displayName = user.displayName
        ?? emailPrefix
        ?? 'HushUser${Random().nextInt(9000) + 1000}';

    if (!userSnap.exists) {
      final newUser = HushUser(
        uid: user.uid,
        displayName: displayName,
        email: user.email,
        photoURL: user.photoURL,
        searchName: displayName.toLowerCase(),
      );
      await userRef.set(newUser.toFirestore());
    } else {
      // Update displayName if it's null/empty in Firestore but available now
      final data = userSnap.data();
      if (data != null) {
        final updates = <String, dynamic>{};
        
        // Recover displayName from firstName and lastName if available
        final firstName = data['firstName'] as String?;
        final lastName = data['lastName'] as String?;
        String finalDisplayName = displayName;
        
        if (firstName != null && firstName.isNotEmpty && lastName != null && lastName.isNotEmpty) {
          finalDisplayName = '$firstName $lastName';
        }
        
        final currentDisplayName = data['displayName'] as String?;
        // If current displayName is missing, empty, or doesn't match the actual first/last name when they are available, update it!
        final shouldUpdateDisplayName = currentDisplayName == null || 
                                        currentDisplayName.isEmpty || 
                                        (firstName != null && currentDisplayName != finalDisplayName);
        
        if (shouldUpdateDisplayName && finalDisplayName.isNotEmpty) {
          updates['displayName'] = finalDisplayName;
          updates['searchName'] = finalDisplayName.toLowerCase();
          
          // Also sync with Firebase Auth
          if (user.displayName == null || user.displayName!.isEmpty || user.displayName != finalDisplayName) {
            await user.updateDisplayName(finalDisplayName);
          }
        }
        if (data['email'] == null && user.email != null) {
          updates['email'] = user.email;
        }
        if (data['photoURL'] == null && user.photoURL != null) {
          updates['photoURL'] = user.photoURL;
        }
        if (updates.isNotEmpty) {
          await userRef.update(updates);
        }
      }
    }
  }

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
