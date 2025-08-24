import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
// import 'package:twitter_login/twitter_login.dart'; // Temporarily commented out due to namespace issue

Future<UserCredential?> thirdPartyAuth(String logo) async {
  if (logo == 'google') {
    print(logo);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      print(credential);
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      return null;
    }
  } else if (logo == 'facebook') {
    try {
      final LoginResult loginResult = await FacebookAuth.instance.login();
      print('fb login in');
      if (loginResult.status != LoginStatus.success) {
        print('fb login failed');
        return null;
      }
      print('fb login success');
      final OAuthCredential facebookAuthCredential =
          FacebookAuthProvider.credential(loginResult.accessToken!.tokenString);

      final fbAuth = await FirebaseAuth.instance.signInWithCredential(
        facebookAuthCredential,
      );

      print(fbAuth);
      return fbAuth;
    } catch (e) {
      print('firebase issue');
      return null;
    }
  } else {
    // Twitter login temporarily disabled due to package namespace issue
    // TODO: Re-enable once twitter_login package is updated or replaced
    print('Twitter login currently disabled');
    return null;

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
  }
}
