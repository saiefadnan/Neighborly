import 'package:flutter/material.dart';
import 'package:frontend/appShell.dart';
// import 'package:frontend/pages/home.dart';
// import 'package:frontend/pages/map.dart';
// import 'package:frontend/pages/profile.dart';
// import 'package:frontend/pages/notification.dart';
// import 'package:frontend/pages/chat.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Neighborly',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF33A67B)),
        appBarTheme: const AppBarTheme(
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25.0,
          ),
        ),
      ),
      home: const AppShell(),
    );
  }
}
