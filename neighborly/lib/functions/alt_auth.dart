import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:neighborly/components/snackbar.dart';

Future<UserCredential?> signInWithCredential(
  OAuthCredential credential,
  BuildContext context,
) async {
  try {
    return await FirebaseAuth.instance.signInWithCredential(credential);
  } on FirebaseAuthException catch (e) {
    if (e.code == 'account-exists-with-different-credential') {
      final pendingCredential = e.credential!;

      final googleUserCredential = await signInWithGoogle(context);

      await googleUserCredential!.user!.linkWithCredential(pendingCredential);

      return googleUserCredential;
    }
    if (context.mounted) {
      showSnackBarError(context, e.message ?? 'Firebase auth error');
    }
    return null;
  }
}

Future<UserCredential?> signInWithGoogle(BuildContext context) async {
  try {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final googleAuthcredential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    if (!context.mounted) return null;
    return await signInWithCredential(googleAuthcredential, context);
  } catch (e) {
    if (context.mounted) {
      showSnackBarError(context, e.toString());
    }
    return null;
  }
}

Future<UserCredential?> signInWithFacebook(BuildContext context) async {
  try {
    final LoginResult loginResult = await FacebookAuth.instance.login();
    if (loginResult.status != LoginStatus.success) {
      if (context.mounted) {
        showSnackBarError(
          context,
          'Facebook login failed with status: ${loginResult.status}${loginResult.message != null ? ' (${loginResult.message})' : ''}',
        );
      }
      return null;
    }

    final OAuthCredential facebookAuthCredential =
        FacebookAuthProvider.credential(loginResult.accessToken!.tokenString);
    if (!context.mounted) return null;
    return await signInWithCredential(facebookAuthCredential, context);
  } catch (e) {
    if (context.mounted) {
      showSnackBarError(context, e.toString());
    }
    return null;
  }
}







  // print('Twitter login currently disabled');
  /*
    final twitterLogin = TwitterLogin(
      apiKey: dotenv.env['TWITTER_API_KEY'] ?? '',
      apiSecretKey: dotenv.env['TWITTER_API_SECRET'] ?? '',
      redirectURI: 'https://neighborly-3cb66.firebaseapp.com/__/auth/handler',
    );

    final authResult = await twitterLogin.login();

    if (authResult.status == TwitterLoginStatus.loggedIn) {
      final credential = TwitterAuthProvider.credential(
        accessToken: authResult.authToken!,
        secret: authResult.authTokenSecret!,
      );

      print(credential);
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } else {
      return null; // failed / cancelled
    }
    */
