import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neighborly/app_shell.dart';
import 'package:neighborly/models/event.dart';
import 'package:neighborly/pages/addEvent.dart';
import 'package:neighborly/pages/add_post.dart';
import 'package:neighborly/pages/authPage.dart';
import 'package:neighborly/pages/event_details.dart';
import 'package:neighborly/pages/event_plan.dart';
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
      final isGoingToAddPost = state.uri.path == '/addPost';
      final isGoingPlanEvent = state.uri.path == '/eventPlan';
      final isGoingtoAddEvent = state.uri.path == '/addEvent';
      final isGoingtoSeeEventDetails = state.uri.path == '/eventDetails';
      final signedIn = verified is AsyncData && verified.value == true;
      // If user is signed in but trying to go to auth or splash, redirect to appShell
      if (signedIn && (isGoingToAuth || isGoingToSplash)) {
        return '/appShell';
      }
      // If user is signed in and going to appShell, allow it
      if (signedIn &&
          (isGoingToAppShell ||
              isGoingToAddPost ||
              isGoingPlanEvent ||
              isGoingtoAddEvent ||
              isGoingtoSeeEventDetails)) {
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
        path: '/addPost',
        builder:
            (context, state) => const AddPostPage(title: 'Post Submission'),
      ),
      GoRoute(
        path: '/eventPlan',
        builder: (context, state) => const EventPlan(title: 'Events'),
      ),
      GoRoute(
        path: '/addEvent',
        builder:
            (context, state) => const CreateEventPage(title: 'Upcoming Events'),
      ),
      GoRoute(
        path: '/eventDetails',
        builder: (context, state) {
          final newEvent = state.extra as EventModel;
          return EventDetailsPage(event: newEvent);
        },
      ),
    ],
  );
});
