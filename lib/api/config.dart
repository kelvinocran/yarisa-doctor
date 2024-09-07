import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthConfig extends ChangeNotifier {
  bool loading = false;

  Future<AuthorizationCredentialAppleID> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      return (credential);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      GoogleSignIn googleSignIn = GoogleSignIn();
      final account = await googleSignIn.signIn();
      print(account);
    } catch (e) {
      rethrow;
    }
  }
}

final authConfig = ChangeNotifierProvider<AuthConfig>((ref) {
  return AuthConfig();
});
