import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neighborly/appShell.dart';
import 'package:neighborly/pages/authPage.dart';
import 'package:neighborly/pages/splash_screen.dart';

final signedInProvider = StateProvider<bool>((ref) => false);

GoRouter createRouter(WidgetRef ref) {
  final signedIn = ref.watch(signedInProvider);
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isGoingToSplash = state.uri.path == '/splash';
      final isGoingToAuth = state.uri.path == '/auth';
      final isGoingToAppShell = state.uri.path == '/appShell';

      // Allow splash screen to show first when app starts
      if (isGoingToSplash && !signedIn) {
        return null;
      }

      // If user is not signed in, redirect to auth (except splash)
      if (!signedIn && !isGoingToAuth && !isGoingToSplash) {
        return '/auth';
      }

      // If user is signed in but trying to go to auth or splash, redirect to appShell
      if (signedIn && (isGoingToAuth || isGoingToSplash)) {
        return '/appShell';
      }

      // If user is signed in and going to appShell, allow it
      if (signedIn && isGoingToAppShell) {
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthPage(title: 'Auth'),
      ),
      GoRoute(path: '/appShell', builder: (context, state) => AppShell()),
    ],
  );
}
