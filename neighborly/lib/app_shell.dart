import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:neighborly/pages/home.dart';
import 'package:neighborly/pages/mapHomePage.dart';
import 'package:neighborly/pages/notification.dart';
import 'package:neighborly/pages/help_list.dart';
import 'package:neighborly/pages/forum.dart';
import 'package:neighborly/providers/notification_provider.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final PageController _pageController = PageController(
    initialPage: 2,
  ); // Start from home (middle)
  int _currentIndex = 2; // Start from home
  bool _shouldAutoOpenHelpDrawer = false; // Flag for auto-opening help drawer

  final GlobalKey<CurvedNavigationBarState> _navKey = GlobalKey();

  final List<IconData> _navIcons = [
    Icons.list_alt, // Help List at index 0
    Icons.map, // Map at index 1
    Icons.home, // Home in the middle
    Icons.groups,
    Icons.notifications_none,
  ];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    // Listen for auth state changes to reinitialize notifications
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _initializeNotifications();
      }
    });
  }

  Future<void> _initializeNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final notificationProvider = context.read<NotificationProvider>();
        print('🔔 Initializing notifications for user: ${user.uid}');
        await notificationProvider.initializeNotifications();
        print('✅ Notifications initialized successfully');
      } else {
        print('❌ No authenticated user found for notification initialization');
      }
    } catch (e) {
      print('❌ Error initializing notifications: $e');
    }
  }

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
      _shouldAutoOpenHelpDrawer = false; // Reset flag
      _pageController.jumpToPage(index);
    });
  }

  void _navigateToMapWithHelpDrawer() {
    setState(() {
      _currentIndex = 1; // Map page index
      _shouldAutoOpenHelpDrawer = true; // Set flag to auto-open drawer
      _pageController.jumpToPage(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 2, // Home is now at index 2
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 2) {
          _pageController.jumpToPage(2); // Jump to home (index 2)
          setState(() => _currentIndex = 2);
        }
      },
      child: Scaffold(
        /**appBar: AppBar(
          backgroundColor: const Color(0xFF71BB7B),
          title: Text(_appBarTitles[_currentIndex]),
          actions: [
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfilePage(title: 'Profile'),
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.only(right: 12.0),
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: AssetImage('assets/images/dummy.png'),
                ),
              ),
            ),
          ],
        ),**/
        body: PageView(
          controller: _pageController,
          physics: NeverScrollableScrollPhysics(),
          onPageChanged: (index) {
            setState(() => _currentIndex = index);
          },
          children: [
            const HelpListPage(), // Index 0 - Help Requests
            MapHomePage(
              autoOpenHelpDrawer: _shouldAutoOpenHelpDrawer,
            ), // Index 1 - Map
            HomePage(
              title: 'Home Page',
              onNavigate: _onTap,
              onNavigateToMapWithHelp: _navigateToMapWithHelpDrawer,
            ), // Index 2 - Home (middle)
            const ForumPage(title: 'Community Hub'), // Index 3
            NotificationPage(
              title: 'Notification Page',
              onNavigate: _onTap,
            ), // Index 4
          ],
        ),
        bottomNavigationBar: CurvedNavigationBar(
          key: _navKey,
          backgroundColor: Colors.transparent,
          color: const Color(0xFFF7F2E7),
          buttonBackgroundColor: const Color(0xFF71BB7B),
          height: 60,
          animationDuration: const Duration(milliseconds: 300),
          index: _currentIndex,
          items: List.generate(_navIcons.length, (index) {
            return Icon(
              _navIcons[index],
              size: 30,
              color:
                  _currentIndex == index
                      ? const Color(0xFFF7F2E7)
                      : Colors.grey[600]!,
            );
          }),
          onTap: _onTap,
        ),
      ),
    );
  }
}
