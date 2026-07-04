import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../services/analytics_service.dart';

import 'package:hush_app/l10n/app_localizations.dart';
import '../config/theme.dart';
import '../core/constants/icons.dart';
import '../widgets/hush_icon_widget.dart';
import '../providers/auth_provider.dart';
import '../providers/ui_provider.dart';

import '../widgets/tutorial_popup.dart';

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
  int? _lastTier; // Tracks the user's tier to detect level-up events
  bool _tutorialShownThisSession = false; // Prevents tutorial from popping up repeatedly

  /// Separate scaffold keys because IndexedStack builds both screens simultaneously
  final GlobalKey<ScaffoldState> _feedScaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<ScaffoldState> _mapScaffoldKey = GlobalKey<ScaffoldState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      FeedScreen(scaffoldKey: _feedScaffoldKey),
      MapScreen(scaffoldKey: _mapScaffoldKey),
      CreateScreen(onPublished: () => setState(() => _currentIndex = 0)),
      const FollowingScreen(),
      const ProfileScreen(),
    ];
    _startInviteTimer();
  }

  Timer? _inviteTimer;



  @override
  void dispose() {
    _inviteTimer?.cancel();
    super.dispose();
  }

  Future<void> _startInviteTimer() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenInvite = prefs.getBool('hasSeenInvitePopup') ?? false;

    if (!hasSeenInvite) {
      _inviteTimer = Timer(const Duration(minutes: 2), () {
        if (mounted) {
          _showInvitePopup();
        }
      });
    }
  }

  void _showInvitePopup() {
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: HushColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.favorite, color: HushColors.tierRed),
            const SizedBox(width: 8),
            Expanded(
              child: Text(l10n.inviteFriends, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: HushColors.textMuted),
              onPressed: () {
                if (ctx.mounted) Navigator.pop(ctx);
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        content: Text(
          l10n.inviteMessage,
          style: const TextStyle(color: HushColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('hasSeenInvitePopup', true);
              AnalyticsService().logInvitePopupDismissed();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(l10n.dontShowAgain, style: const TextStyle(color: HushColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final box = ctx.findRenderObject() as RenderBox?;
              final shareOrigin = box != null ? box.localToGlobal(Offset.zero) & box.size : null;
              if (ctx.mounted) Navigator.pop(ctx);
              AnalyticsService().logInvitePopupAccepted();
              AnalyticsService().logShareApp('invite_popup');
              Future.delayed(const Duration(milliseconds: 300), () {
                Share.share(l10n.shareAppText, sharePositionOrigin: shareOrigin);
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: HushColors.textAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(l10n.inviteFriends, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final hushUser = auth.hushUser;
        
        // --- TIER-UP CELEBRATION LOGIC ---
        if (hushUser != null) {
          final currentTier = hushUser.tierLevel;
          if (_lastTier != null && currentTier > _lastTier!) {
            // Level up detected! Trigger confetti and sound
            debugPrint('[TIER] Level Up detected: $_lastTier -> $currentTier');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<UIProvider>().triggerConfetti();
              AnalyticsService().logTierUp(oldTier: _lastTier!, newTier: currentTier);
            });
          }
          _lastTier = currentTier;
        }

        // --- TUTORIAL TRIGGER LOGIC ---
        if (hushUser != null && !hushUser.hasSeenTutorial && !_tutorialShownThisSession) {
          _tutorialShownThisSession = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AnalyticsService().logTutorialStarted(source: 'auto');
            showDialog(
              context: context,
              barrierDismissible: true, // Allow dismissal via clicking outside if they want
              builder: (_) => const TutorialPopup(),
            );
          });
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            // 1. If drawer is open on the current tab, close it
            if (_currentIndex == 0 && (_feedScaffoldKey.currentState?.isDrawerOpen ?? false)) {
              _feedScaffoldKey.currentState?.closeDrawer();
              return;
            }
            if (_currentIndex == 1 && (_mapScaffoldKey.currentState?.isDrawerOpen ?? false)) {
              _mapScaffoldKey.currentState?.closeDrawer();
              return;
            }
            // 2. If not on the first tab, go back to it
            if (_currentIndex != 0) {
              setState(() => _currentIndex = 0);
              return;
            }
            // 3. On tab 0, drawer closed — exit the app
            SystemNavigator.pop();
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
                onTap: (index) {
                  setState(() => _currentIndex = index);
                  const tabNames = ['feed', 'map', 'create', 'following', 'profile'];
                  AnalyticsService().logTabChanged(tabNames[index]);
                },
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
                    label: l10n.feedTabTitle,
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: HushIcon(HushIcons.map, size: 22, color: _currentIndex == 1 ? HushColors.textAccent : HushColors.textSecondary),
                    ),
                    label: l10n.mapTabTitle,
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
        );
      },
    );
  }
}
