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
import 'feed_tutorial_screen.dart';
import 'map_screen.dart';
import 'create_screen.dart';
import 'profile_screen.dart';
import 'following_screen.dart';

/// Main app shell with bottom navigation — matches the web AppShell component
class AppShell extends StatefulWidget {
  final int initialIndex;
  const AppShell({super.key, this.initialIndex = 0});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _currentIndex;
  int? _lastTier; // Tracks the user's tier to detect level-up events
  bool _tutorialShownThisSession = false; // Prevents tutorial from popping up repeatedly

  /// Separate scaffold keys because IndexedStack builds both screens simultaneously
  final GlobalKey<ScaffoldState> _feedScaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<ScaffoldState> _mapScaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FeedScreenState> _feedScreenKey = GlobalKey<FeedScreenState>();
  final GlobalKey<ProfileScreenState> _profileScreenKey = GlobalKey<ProfileScreenState>();

  StreamSubscription<void>? _homeSub;

  void _updateTitle(BuildContext context, int index) {
    final localL10n = AppLocalizations.of(context)!;
    String newTitle = '';
    switch (index) {
      case 0:
        newTitle = _feedScreenKey.currentState?.getCurrentTitle(context) ?? localL10n.feedTitle;
        break;
      case 1: newTitle = localL10n.mapTitle; break;
      case 2: newTitle = localL10n.createTitle; break;
      case 3: newTitle = localL10n.followingTabTitle; break;
      case 4: newTitle = localL10n.profileTitle; break;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<UIProvider>().setCurrentTitle(newTitle);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _startInviteTimer();
    _homeSub = context.read<UIProvider>().homeStream.listen((_) {
      // Pop any pushed routes (settings, privacy, etc.) back to AppShell
      rootNavigatorKey.currentState?.popUntil((route) => route.isFirst);
      if (mounted) {
        setState(() => _currentIndex = 0);
        _updateTitle(context, 0);
      }
    });
  }

  Timer? _inviteTimer;
  bool _didInitNotifications = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateTitle(context, _currentIndex);
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
    
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          decoration: BoxDecoration(
            color: HushColors.bgCard,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              OverflowBar(
                alignment: MainAxisAlignment.spaceBetween,
                overflowAlignment: OverflowBarAlignment.end,
                spacing: 8,
                overflowSpacing: 16,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final hushUser = auth.hushUser;
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          String title = '';
          switch (_currentIndex) {
            case 0: /* handled by FeedScreen */ return;
            case 1: title = l10n.mapTitle; break;
            case 2: title = l10n.createTitle; break;
            case 3: title = l10n.followingTabTitle; break;
            case 4: title = l10n.profileTitle; break;
          }
          context.read<UIProvider>().setCurrentTitle(title);
        });

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
        if (hushUser != null && !_tutorialShownThisSession) {
          if (!hushUser.hasSeenTutorial) {
            _tutorialShownThisSession = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              AnalyticsService().logTutorialStarted(source: 'auto');
              showDialog(
                context: context,
                barrierDismissible: true,
                builder: (_) => const TutorialPopup(),
              ).then((_) {
                if (!hushUser.hasSeenFeedTutorialV1 && context.mounted) {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedTutorialScreen()));
                }
              });
            });
          } else if (!hushUser.hasSeenFeedTutorialV1) {
            _tutorialShownThisSession = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedTutorialScreen()));
            });
          }
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
              _updateTitle(context, 0);
              return;
            }
            // 3. If on the first tab, check if inner feed tabs can pop
            if (_feedScreenKey.currentState?.handleBackPress() == true) {
              return;
            }
            // 4. On tab 0, drawer closed, on nearby feed — exit the app
            SystemNavigator.pop();
          },
          child: Scaffold(
            body: IndexedStack(
              index: _currentIndex,
              children: [
                FeedScreen(key: _feedScreenKey, scaffoldKey: _feedScaffoldKey),
                MapScreen(scaffoldKey: _mapScaffoldKey),
                CreateScreen(
                  isActive: _currentIndex == 2,
                  onPublishStart: () {
                    setState(() => _currentIndex = 0);
                    _updateTitle(context, 0);
                  },
                  onPublishComplete: () {
                    _feedScreenKey.currentState?.refreshFeed();
                    _profileScreenKey.currentState?.fetchProfileData();
                  },
                ),
                FollowingScreen(isActive: _currentIndex == 3),
                ProfileScreen(key: _profileScreenKey),
              ],
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
                  _updateTitle(context, index);
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
                      padding: const EdgeInsets.all(8), // Reduced padding
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
                      child: Image.asset('assets/images/icon_tap_to_drop.png', width: 40, height: 40), // Increased size
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
