import 'package:flutter/material.dart';
import 'package:neighborly/pages/home.dart';
import 'package:neighborly/pages/map.dart';
import 'package:neighborly/pages/profile.dart';
import 'package:neighborly/pages/notification.dart';
import 'package:neighborly/pages/forum.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  List<String> appBarHeadings = [
    'Neighborly',
    'Map',
    'Community',
    'Notifications',
  ];
  String appBarTitle = 'Neighborly';
  final _items = [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
    BottomNavigationBarItem(icon: Icon(Icons.map), label: ''),
    BottomNavigationBarItem(icon: Icon(Icons.newspaper_outlined), label: ''),
    BottomNavigationBarItem(icon: Icon(Icons.notifications), label: ''),
  ];
  void _onTap(int index) {
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 0) {
          _pageController.jumpTo(0);
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(appBarTitle),
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
              child: Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: AssetImage('assets/images/dummy.png'),
                ),
              ),
            ),
          ],
        ),
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
              appBarTitle = appBarHeadings[index];
            });
          },
          children: [
            HomePage(title: 'Home Page'),
            MapPage(title: 'Map Page'),
            ForumPage(title: 'Forum Page'),
            NotificationPage(title: 'Notification Page'),
            //ProfilePage(title: 'Profile Page'),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: _onTap,
          items: _items,
        ),
      ),
    );
  }
}
