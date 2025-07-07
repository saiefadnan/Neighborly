import 'package:flutter/material.dart';
import 'package:neighborly/appshell.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neighborly/pages/login.dart';

final loggedInProvider = StateProvider<bool>((ref) => false);

void main() {
  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn = ref.watch(loggedInProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Neighborly',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF71BB7B)),
        appBarTheme: const AppBarTheme(
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25.0,
          ),
        ),
      ),
      home: loggedIn ? const AppShell() : const LoginPage(title: "login"),
    );
  }
}
