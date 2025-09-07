import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neighborly/app_routes.dart';
import 'package:neighborly/firebase_options.dart';
import 'package:neighborly/providers/notification_provider.dart';
import 'package:neighborly/providers/help_request_provider.dart';
import 'package:neighborly/providers/community_provider.dart';
import 'package:neighborly/services/push_notification_service.dart';
import 'package:provider/provider.dart' as provider;
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //dont remove this ever again!!!
  //dont remove this ever again!!!
  //dont remove this ever again!!!
  await dotenv.load(fileName: ".env");//no problems now
  //dont remove this ever again!!!
  //dont remove this ever again!!!
  //dont remove this ever again!!!

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("✅ Firebase initialized!");

  // Initialize push notifications
  await PushNotificationService.initialize(
    onMessageReceived: (data) {
      print("📱 Foreground notification received: $data");
      // Handle foreground notification
    },
    onMessageOpenedApp: (data) {
      print("📱 App opened from notification: $data");
      // Handle notification tap
    },
  );
  print("✅ Push notifications initialized!");

  // Create providers
  final helpRequestProvider = HelpRequestProvider();
  helpRequestProvider.initializeSampleData(); // Initialize with sample data

  final notificationProvider = NotificationProvider();

  runApp(
    provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider.value(value: notificationProvider),
        provider.ChangeNotifierProvider.value(value: helpRequestProvider),
        provider.ChangeNotifierProvider(create: (_) => CommunityProvider()),
      ],
      child: ProviderScope(child: const MyApp()),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    _checkRememberMe();
  }

  Future<void> _checkRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('rememberMe') ?? false;
    if (!rememberMe) {
      await FirebaseAuth.instance.signOut();
      print('signing out...');
    } else {
      //ref.read(authUserProvider.notifier).stateOnRemember();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
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
      routerConfig: router,
    );
  }
}
