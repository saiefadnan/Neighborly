import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:neighborly/pages/home.dart';
import 'package:neighborly/pages/mapHomePage.dart';
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

  final GlobalKey<CurvedNavigationBarState> _navKey = GlobalKey();

  final List<IconData> _navIcons = [
    Icons.home,
    Icons.map,
    Icons.add,
    Icons.groups,
    Icons.notifications_none,
  ];

  /**final List<String> _appBarTitles = [
    'Neighborly',
    'Map',
    'Community',
    'Notifications',
    'Notifications',
  ];**/

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
      _pageController.jumpToPage(index);
    });
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
          physics:
              _currentIndex == 1
                  ? NeverScrollableScrollPhysics()
                  : PageScrollPhysics(),
          onPageChanged: (index) {
            setState(() => _currentIndex = index);
          },
          children: [
            HomePage(title: 'Home Page', onNavigate: _onTap),
            MapHomePage(),
            const ProfilePage(title: 'Profile Page'),
            const ForumPage(title: 'Forum Page'),
            const NotificationPage(title: 'Notification Page'),
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
