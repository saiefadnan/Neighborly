import 'package:firebase_auth/firebase_auth.dart';

Future<String?> signInAndGetIdToken(String email, String pswd) async {
    try {
      final userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pswd,
      );
      final idToken = await userCred.user?.getIdToken();
      return idToken;
    } catch (e) {
      return null;
    }
  }