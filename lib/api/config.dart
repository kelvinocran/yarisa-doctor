import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthConfig extends ChangeNotifier {
  bool loading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential?> signInWithApple() async {
    try {
      loading = true;
      notifyListeners();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create OAuth credential for Firebase
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(oauthCredential);

      // Update display name if available
      if (credential.givenName != null && credential.familyName != null) {
        final displayName = '${credential.givenName} ${credential.familyName}';
        await userCredential.user?.updateDisplayName(displayName);
      }

      loading = false;
      notifyListeners();
      return userCredential;
    } catch (e) {
      loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      loading = true;
      notifyListeners();

      GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? account = await googleSignIn.signIn();

      if (account == null) {
        loading = false;
        notifyListeners();
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await account.authentication;

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);

      loading = false;
      notifyListeners();
      return userCredential;
    } catch (e) {
      loading = false;
      notifyListeners();
      rethrow;
    }
  }
}

final authConfig = ChangeNotifierProvider<AuthConfig>((ref) {
  return AuthConfig();
});
