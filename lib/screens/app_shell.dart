import 'dart:async';
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
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/ui_provider.dart';

/// Main app shell with bottom navigation — matches the web AppShell component
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  late ConfettiController _confettiController;
  int? _previousTier;
  StreamSubscription? _uiSubscription;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    // Listen for manual trigger from UIProvider (e.g. from Admin Screen)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _uiSubscription = context.read<UIProvider>().confettiStream.listen((_) {
        _confettiController.play();
      });
    });
  }

  @override
  void dispose() {
    _uiSubscription?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

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
    final auth = context.watch<AuthProvider>();
    final user = auth.hushUser;

    // Detection of tier increase
    if (user != null) {
      if (_previousTier != null && user.tierLevel > _previousTier!) {
        _confettiController.play();
      }
      _previousTier = user.tierLevel;
    }

    return Stack(
      children: [
        PopScope(
          canPop: _currentIndex == 0,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (_currentIndex != 0) {
              setState(() => _currentIndex = 0);
            }
          },
          child: Scaffold(
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
          ),
        ),
        
        // Celebration Layer
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              HushColors.textAccent,
              HushColors.tierRed,
              Colors.amber,
              Colors.white,
            ],
            gravity: 0.1,
          ),
        ),
        
        // Manual Test Trigger Listener (Global)
        // This allows other children to trigger confetti via a special provider or global event if needed
        // For now, it's just a passive layer.
      ],
    );
  }
}
