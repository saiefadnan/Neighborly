import 'package:firebase_auth/firebase_auth.dart';

Future<String?> signUpAndGetIdToken(String name, String email, String pswd) async {
    try {
      final userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pswd);
      await userCred.user?.updateDisplayName(name);

      final idToken = await userCred.user?.getIdToken();
      return idToken;
    } catch (e) {
      return null;
    }
  }