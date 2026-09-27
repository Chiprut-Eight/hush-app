import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../core/constants/icons.dart';
import '../models/hush_user.dart';
import '../providers/auth_provider.dart';
import '../services/social_service.dart';
import '../widgets/hush_icon_widget.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:hush_app/l10n/app_localizations.dart';
import '../services/analytics_service.dart';

class FollowingScreen extends StatefulWidget {
  final bool isActive;
  const FollowingScreen({super.key, this.isActive = false});

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  final SocialService _socialService = SocialService();
  final TextEditingController _searchController = TextEditingController();
  
  final GlobalKey _profileTargetKey = GlobalKey();
  final GlobalKey _mapTargetKey = GlobalKey();
  bool _tutorialShown = false;
  TutorialCoachMark? _tutorial;
  bool _isNavigatingAway = false;

  List<HushUser> _searchResults = [];
  List<FollowedUserFeedItem> _followedFeed = [];
  
  bool _isSearching = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    AnalyticsService().logScreenView('following');
    _fetchFollowedFeed();
  }

  @override
  void didUpdateWidget(FollowingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _isNavigatingAway = false;
      final user = context.read<AuthProvider>().hushUser;
      if (user != null && !user.hasSeenFollowingTutorialV6 && _followedFeed.isNotEmpty) {
        _showTutorial();
      }
    } else if (!widget.isActive && oldWidget.isActive) {
      // If user navigates away while tutorial is showing
      _isNavigatingAway = true;
      _tutorial?.finish();
      _tutorial = null;
    }
  }

  Future<void> _fetchFollowedFeed() async {
    setState(() => _isLoading = true);
    final user = context.read<AuthProvider>().hushUser;
    if (user != null) {
      _followedFeed = await _socialService.getFollowedUsersFeed(user.followingIds);
      
      if (widget.isActive && !user.hasSeenFollowingTutorialV6 && _followedFeed.isNotEmpty) {
        // Wait a frame for UI to render
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showTutorial();
        });
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _showTutorial() {
    if (_tutorialShown) return;
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      
      final l10n = AppLocalizations.of(context)!;
      final targets = <TargetFocus>[];
      
      if (_profileTargetKey.currentContext != null) {
        targets.add(
          TargetFocus(
            identify: "ProfileTarget",
            keyTarget: _profileTargetKey,
            alignSkip: Alignment.topRight,
            contents: [
              TargetContent(
                align: ContentAlign.bottom,
                builder: (context, controller) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.clickAvatarToProfile, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () => _tutorial?.next(),
                            style: ElevatedButton.styleFrom(backgroundColor: HushColors.gradientBlue, foregroundColor: Colors.white),
                            child: Text(l10n.tutorialContinue),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => _tutorial?.skip(),
                            style: TextButton.styleFrom(foregroundColor: Colors.white54),
                            child: Text(l10n.tutorialGotIt),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          )
        );
      }
      
      if (_mapTargetKey.currentContext != null) {
        targets.add(
          TargetFocus(
            identify: "MapTarget",
            keyTarget: _mapTargetKey,
            alignSkip: Alignment.topRight,
            shape: ShapeLightFocus.RRect,
            radius: 8,
            contents: [
              TargetContent(
                align: ContentAlign.top,
                builder: (context, controller) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.clickHereToViewMap, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _tutorial?.skip(),
                        style: ElevatedButton.styleFrom(backgroundColor: HushColors.gradientBlue, foregroundColor: Colors.white),
                        child: Text(l10n.tutorialGotIt),
                      ),
                    ],
                  );
                },
              ),
            ],
          )
        );
      }

      if (targets.isEmpty) return;
      _tutorialShown = true;

      _tutorial = TutorialCoachMark(
        targets: targets,
        colorShadow: HushColors.bgPrimary,
        hideSkip: true,
        paddingFocus: 10,
        opacityShadow: 0.8,
        onFinish: () async {
          _tutorial = null;
          if (_isNavigatingAway) return;
          final auth = context.read<AuthProvider>();
          if (auth.firebaseUser != null) {
            await FirebaseFirestore.instance.collection('users').doc(auth.firebaseUser!.uid).update({'hasSeenFollowingTutorialV6': true});
          }
        },
        onSkip: () {
          _tutorial = null;
          if (_isNavigatingAway) return true;
          final auth = context.read<AuthProvider>();
          if (auth.firebaseUser != null) {
            FirebaseFirestore.instance.collection('users').doc(auth.firebaseUser!.uid).update({'hasSeenFollowingTutorialV6': true});
          }
          return true;
        },
      )..show(context: context);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
    });

    final results = await _socialService.searchUsers(query);
    final currentUserUid = context.read<AuthProvider>().firebaseUser?.uid;
    final filteredResults = results.where((u) => u.uid != currentUserUid).toList();
    
    AnalyticsService().logUserSearch(query);
    if (mounted) {
      setState(() {
        _searchResults = filteredResults;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow(HushUser targetUser) async {
    final auth = context.read<AuthProvider>();
    final currentUserRef = auth.hushUser;
    final currentUserFirebase = auth.firebaseUser;
    
    if (currentUserRef == null || currentUserFirebase == null) return;

    final isFollowing = currentUserRef.followingIds.contains(targetUser.uid);

    try {
      if (isFollowing) {
        await _socialService.unfollowUser(currentUserFirebase.uid, targetUser.uid);
        AnalyticsService().logUnfollow(targetUser.uid);
      } else {
        await _socialService.followUser(currentUserFirebase.uid, targetUser.uid);
        AnalyticsService().logFollow(targetUser.uid);
      }
      
      // Update local provider state to reflect UI changes instantly
      await auth.refreshProfile();
      await _fetchFollowedFeed(); // Re-fetch feed to order the secrets
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: HushColors.bgPrimary,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _performSearch,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: l10n.searchUsersHint,
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const HushIcon(HushIcons.search, size: 20, color: HushColors.textAccent),
                filled: true,
                fillColor: HushColors.bgCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: HushColors.textAccent))
                : _isSearching
                    ? _buildSearchResults(l10n)
                    : _buildFollowedFeed(l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(AppLocalizations l10n) {
    if (_searchResults.isEmpty) {
      return Center(child: Text(l10n.noUsersFound, style: const TextStyle(color: Colors.white54)));
    }

    final currentUserFollowing = context.watch<AuthProvider>().hushUser?.followingIds ?? [];

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        final isFollowing = currentUserFollowing.contains(user.uid);

        return ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfileScreen(targetUserId: user.uid)),
            );
          },
          leading: CircleAvatar(
            backgroundColor: HushColors.bgCard,
            backgroundImage: (user.useGenericPhoto || user.photoURL == null) ? const AssetImage('assets/images/icon_only.png') : NetworkImage(user.photoURL!),
          ),
          title: Text('${user.firstName ?? ''} ${user.lastName ?? ''}'.trim().isNotEmpty ? '${user.firstName} ${user.lastName}' : (user.displayName ?? l10n.anonymousUser), style: const TextStyle(color: Colors.white)),
          subtitle: Text(l10n.tier(user.tierLevel), style: const TextStyle(color: HushColors.textAccent)),
          trailing: ElevatedButton(
            onPressed: () => _toggleFollow(user),
            style: ElevatedButton.styleFrom(
              backgroundColor: isFollowing ? Colors.transparent : const Color(0xFF1565C0),
              side: isFollowing ? const BorderSide(color: HushColors.textAccent) : null,
            ),
            child: Text(isFollowing ? l10n.unfollowBtn : l10n.followBtn, style: TextStyle(color: isFollowing ? HushColors.textAccent : Colors.white)),
          ),
        );
      },
    );
  }

  Widget _buildFollowedFeed(AppLocalizations l10n) {
    if (_followedFeed.isEmpty) {
      return Center(
        child: Text(l10n.notFollowingAnyone, style: const TextStyle(color: Colors.white54)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _followedFeed.length,
      itemBuilder: (context, index) {
        final item = _followedFeed[index];
        final user = item.user;
        final secret = item.latestSecret;

        return Card(
          color: HushColors.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              AnalyticsService().logFollowedUserTapped(user.uid);
              if (secret != null) {
                final firstName = user.firstName?.trim();
                final displayName = (firstName != null && firstName.isNotEmpty) ? firstName : (user.displayName ?? l10n.anonymousUser);
                final shortName = displayName.split(' ').first; // Take only the first word/name
                
                // Navigate to MapScreen targeting the secret's coordinates
                Navigator.push(context, MaterialPageRoute(builder: (_) => MapScreen(
                  targetLat: secret.lat, 
                  targetLng: secret.lng,
                  targetTitle: shortName,
                  targetUserId: user.uid,
                )));
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  GestureDetector(
                    key: index == 0 ? _profileTargetKey : null,
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: HushColors.bgPrimary,
                      backgroundImage: user.photoURL != null && !user.useGenericPhoto ? NetworkImage(user.photoURL!) : const AssetImage('assets/images/icon_only.png'),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfileScreen(targetUserId: user.uid)),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          child: Text(
                            '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim().isNotEmpty ? '${user.firstName} ${user.lastName}' : (user.displayName ?? l10n.anonymousUser),
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ProfileScreen(targetUserId: user.uid)),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        if (secret != null) ...[
                          Row(
                            key: index == 0 ? _mapTargetKey : null,
                            children: [
                              HushIcon(secret.type == 'voice' ? HushIcons.mic : HushIcons.textSnippet, size: 14, color: HushColors.textAccent),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  l10n.publishedSecretAgo(DateTime.now().difference(secret.createdAt).inHours),
                                  style: const TextStyle(color: HushColors.textSecondary, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Text(l10n.noActiveSecrets, style: const TextStyle(color: HushColors.textMuted, fontSize: 12)),
                        ]
                      ],
                    ),
                  ),
                  const HushIcon(HushIcons.chevronRight, size: 20, color: Colors.white24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
