import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../config/theme.dart';
import '../providers/locale_provider.dart';
import 'feed_screen.dart';
import 'map_screen.dart';
import 'create_screen.dart';
import 'profile_screen.dart';

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
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.watch<LocaleProvider>();

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
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.hearing),
              label: l10n.feedTitle,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.map_outlined),
              label: l10n.mapTitle,
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: HushColors.brandGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: HushColors.bgPrimary, size: 20),
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              label: l10n.profileTitle,
            ),
          ],
        ),
      ),
    );
  }
}
