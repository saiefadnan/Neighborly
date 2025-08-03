import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neighborly/appShell.dart';
import 'package:neighborly/pages/add_post.dart';
import 'package:neighborly/pages/authPage.dart';
import 'package:neighborly/pages/splash_screen.dart';

final authStateChanges = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.authStateChanges(),
);
final hasSeenSplashProvider = StateProvider<bool>((ref) => false);

final goRouterProvider = Provider<GoRouter>((ref) {
  //final authAsync = ref.watch(authStateChanges);
  final hasSeenSplash = ref.watch(hasSeenSplashProvider);
  final verified = ref.watch(authUserProvider);
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isGoingToSplash = state.uri.path == '/splash';
      final isGoingToAuth = state.uri.path == '/auth';
      final isGoingToAppShell = state.uri.path == '/appShell';
      final signedIn = verified is AsyncData && verified.value == true;
      // If user is signed in but trying to go to auth or splash, redirect to appShell
      if (signedIn && (isGoingToAuth || isGoingToSplash)) {
        return '/appShell';
      }
      // If user is signed in and going to appShell, allow it
      if (signedIn && isGoingToAppShell) {
        return null;
      }
      // First time app launch - show splash
      if (!hasSeenSplash && isGoingToSplash) {
        return null;
      }

      // If user has seen splash and is not signed in, allow direct auth access
      if (!signedIn && hasSeenSplash && isGoingToAuth) {
        return null;
      }

      // If user hasn't seen splash yet and trying to go anywhere else, redirect to splash
      if (!hasSeenSplash && !isGoingToSplash) {
        return '/splash';
      }

      // If user is not signed in, has seen splash, and trying to access protected routes, redirect to auth
      if (!signedIn && hasSeenSplash && !isGoingToAuth) {
        return '/auth';
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
      GoRoute(
        path: '/addpost',
        builder:
            (context, state) => const AddPostPage(title: 'Post Submission'),
      ),
    ],
  );
});
