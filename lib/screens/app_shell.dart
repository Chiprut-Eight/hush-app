import 'package:flutter/material.dart';

import 'package:hush_app/l10n/app_localizations.dart';
import '../config/theme.dart';
import '../core/constants/icons.dart';
import '../widgets/hush_icon_widget.dart';

import 'feed_screen.dart';
import 'map_screen.dart';
import 'create_screen.dart';
import 'profile_screen.dart';
import 'following_screen.dart';

/// Main app shell with bottom navigation — matches the web AppShell component
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    FeedScreen(),
    MapScreen(),
    CreateScreen(),
    FollowingScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: HushColors.borderSubtle, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: HushColors.bgPrimary,
          selectedItemColor: HushColors.textAccent,
          unselectedItemColor: HushColors.textSecondary,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: HushIcon(HushIcons.feed, size: 22, color: _currentIndex == 0 ? HushColors.textAccent : HushColors.textSecondary),
              ),
              label: l10n.feedTitle,
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: HushIcon(HushIcons.map, size: 22, color: _currentIndex == 1 ? HushColors.textAccent : HushColors.textSecondary),
              ),
              label: l10n.mapTitle,
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  gradient: HushColors.brandGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: HushColors.tierRed,
                      blurRadius: 12,
                      spreadRadius: -4,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const HushIcon(HushIcons.plusCircle, size: 28, color: Colors.white),
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: HushIcon(HushIcons.users, size: 22, color: _currentIndex == 3 ? HushColors.textAccent : HushColors.textSecondary),
              ),
              label: l10n.followingTabTitle,
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: HushIcon(HushIcons.userCircle, size: 22, color: _currentIndex == 4 ? HushColors.textAccent : HushColors.textSecondary),
              ),
              label: l10n.profileTitle,
            ),
          ],
        ),
      ),
    );
  }
}
