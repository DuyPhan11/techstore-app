import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Performs Google Sign-In and signs into Firebase, returning the ID token
  static Future<String?> signInWithGoogle() async {
    try {
      // 1. Sign out of any previous local session to ensure user picker pops up
      await _googleSignIn.signOut();

      // 2. Open Google Sign-In prompt
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the prompt
        return null;
      }

      // 3. Obtain authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 4. Create credential for Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 5. Sign in with Firebase
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // 6. Get Firebase ID Token
      final String? firebaseIdToken = await userCredential.user?.getIdToken();

      // Return valid ID token (prefer Firebase ID token, fallback to Google ID token)
      return firebaseIdToken ?? googleAuth.idToken;
    } catch (e) {
      debugPrint('GoogleAuthService signInWithGoogle error: $e');
      rethrow;
    }
  }

  /// Sign out from both Google and Firebase
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('GoogleAuthService signOut error: $e');
    }
  }
}
