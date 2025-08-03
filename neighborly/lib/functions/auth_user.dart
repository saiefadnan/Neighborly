import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neighborly/components/signin_form.dart';
import 'package:neighborly/functions/signin_token.dart';
import 'package:neighborly/functions/signup_token.dart';
import 'package:neighborly/functions/token_verify.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthUser extends AsyncNotifier<bool> {
  @override
  bool build() => false;
  Future<void> userAuthentication({
    String? name,
    required String email,
    required String password,
  }) async {
    try {
      state = const AsyncLoading();
      String? idToken;
      if (name != null && name.isNotEmpty) {
        idToken = await signUpAndGetIdToken(name, email, password);
      } else {
        idToken = await signInAndGetIdToken(email, password);
      }
      if (idToken == null) {
        throw Exception('Authentication failed!');
      }
      bool verified = await verifyToken(idToken);
      if (verified) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('rememberMe', rememberMe);
        state = AsyncData(true);
      } else {
        throw Exception('Invalid user credentials!');
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void initState() {
    state = const AsyncData(false);
  }

  void stateOnRemember() {
    state = const AsyncData(true);
  }
}
