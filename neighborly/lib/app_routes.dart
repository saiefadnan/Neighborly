import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neighborly/appShell.dart';
import 'package:neighborly/pages/authPage.dart';

final signedInProvider = StateProvider<bool>((ref) => false);

GoRouter createRouter(WidgetRef ref) {
  final signedIn = ref.watch(signedInProvider);
  return GoRouter(
    initialLocation: '/auth',
    redirect: (context, state) {
      final isGoingtoAuth = state.uri.path == '/auth';
      if (!signedIn && !isGoingtoAuth) {
        return '/auth';
      }
      if (signedIn && isGoingtoAuth) {
        return '/appShell';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthPage(title: 'Auth'),
      ),
      GoRoute(path: '/appShell', builder: (context, state) => AppShell()),
    ],
  );
}
