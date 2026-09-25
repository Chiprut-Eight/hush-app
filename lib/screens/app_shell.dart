import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../services/analytics_service.dart';
import '../main.dart';

import 'package:hush_app/l10n/app_localizations.dart';
import '../config/theme.dart';
import '../core/constants/icons.dart';
import '../widgets/hush_icon_widget.dart';
import '../providers/auth_provider.dart';
import '../providers/ui_provider.dart';
import '../services/notification_service.dart';

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
  final GlobalKey<FeedScreenState> _feedScreenKey = GlobalKey<FeedScreenState>();

  late final List<Widget> _screens;
  StreamSubscription<void>? _homeSub;

  @override
  void initState() {
    super.initState();
    _screens = [
      FeedScreen(key: _feedScreenKey, scaffoldKey: _feedScaffoldKey),
      MapScreen(scaffoldKey: _mapScaffoldKey),
      CreateScreen(onPublished: () {
        setState(() => _currentIndex = 0);
        _feedScreenKey.currentState?.refreshFeed();
      }),
      const FollowingScreen(),
      const ProfileScreen(),
    ];
    _startInviteTimer();
    _homeSub = context.read<UIProvider>().homeStream.listen((_) {
      // Pop any pushed routes (settings, privacy, etc.) back to AppShell
      rootNavigatorKey.currentState?.popUntil((route) => route.isFirst);
      if (mounted) setState(() => _currentIndex = 0);
    });
  }

  Timer? _inviteTimer;
  bool _didInitNotifications = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitNotifications) {
      final auth = context.read<AuthProvider>();
      if (auth.firebaseUser != null) {
        _didInitNotifications = true;
        // Small delay to let the app finish rendering before asking for notification permissions
        Future.delayed(const Duration(seconds: 2), () {
          NotificationService().init(auth.firebaseUser!.uid).catchError((e) {
            debugPrint('[AppShell] Notification init error: $e');
          });
        });
      }
    }
  }

  @override
  void dispose() {
    _inviteTimer?.cancel();
    _homeSub?.cancel();
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
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        decoration: const BoxDecoration(
          color: HushColors.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: HushColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.favorite, color: HushColors.tierRed, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(l10n.inviteFriends, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: HushColors.textMuted),
                  onPressed: () {
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.inviteMessage,
              style: const TextStyle(color: HushColors.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(l10n.inviteFriends, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
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
              final isMuted = context.read<AuthProvider>().hushUser?.appSoundsMuted ?? false;
              context.read<UIProvider>().triggerConfetti(muteSound: isMuted);
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
                  if (_currentIndex != index) {
                    HapticFeedback.lightImpact();
                  }
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
