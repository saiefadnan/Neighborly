import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neighborly/appShell.dart';

import 'package:neighborly/pages/signin.dart';
import 'package:neighborly/pages/signup.dart';

final signedInProvider = StateProvider<bool>((ref) => false);

GoRouter createRouter(WidgetRef ref) {
  final signedIn = ref.watch(signedInProvider);
  return GoRouter(
    initialLocation: '/signin',
    redirect: (context, state) {
      final isGoingtoSignin =
          state.uri.path == '/signin' || state.uri.path == '/signup';
      if (!signedIn && !isGoingtoSignin) {
        return '/signin';
      }
      if (signedIn && isGoingtoSignin) {
        return '/appShell';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/signin',
        builder: (context, state) => const SigninPage(title: 'Sign In'),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupPage(title: 'Sign Up'),
      ),
      GoRoute(path: '/appShell', builder: (context, state) => AppShell()),
    ],
  );
}
