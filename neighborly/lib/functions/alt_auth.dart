import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:neighborly/components/snackbar.dart';

Future<void> postUserToFirestore({
  required String username,
  required String email,
  required String addressLine1,
  String? addressLine2,
  required String city,
  required String division,
  required String postalCode,
  required String contactNumber,
  required String bloodGroup,
  required List<String> preferredCommunity,
}) async {
  try {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'username': username,
      'email': email,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2 ?? '',
      'city': city,
      'division': division,
      'postalcode': postalCode,
      'contactNumber': contactNumber,
      'bloodGroup': bloodGroup,
      'preferredCommunity': preferredCommunity,
      'profilepicurl': '',
      'isAdmin': false,
      'blocked': false,
      'createdAt': Timestamp.now(),
    });
    print('✅ User data saved to Firestore successfully');
  } catch (e) {
    print('❌ Error saving user data to Firestore: $e');
    rethrow;
  }
}

Future<UserCredential?> signInWithCredential(
  OAuthCredential credential,
  BuildContext context,
) async {
  try {
    final userCred = await FirebaseAuth.instance.signInWithCredential(
      credential,
    );
    final docRef =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCred.user?.uid)
            .get();
    if (!docRef.exists) {
      await postUserToFirestore(
        username: "",
        email: userCred.user?.email ?? "",
        addressLine1: "",
        city: "",
        division: "",
        postalCode: "",
        contactNumber: "",
        bloodGroup: "",
        preferredCommunity: [],
      );
    }
    return userCred;
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
