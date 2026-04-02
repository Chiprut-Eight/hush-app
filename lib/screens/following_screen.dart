import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../core/constants/icons.dart';
import '../models/hush_user.dart';
import '../providers/auth_provider.dart';
import '../services/social_service.dart';
import '../widgets/hush_icon_widget.dart';
import 'map_screen.dart';
import 'package:hush_app/l10n/app_localizations.dart';

class FollowingScreen extends StatefulWidget {
  const FollowingScreen({super.key});

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  final SocialService _socialService = SocialService();
  final TextEditingController _searchController = TextEditingController();
  
  List<HushUser> _searchResults = [];
  List<FollowedUserFeedItem> _followedFeed = [];
  
  bool _isSearching = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFollowedFeed();
  }

  Future<void> _fetchFollowedFeed() async {
    setState(() => _isLoading = true);
    final user = context.read<AuthProvider>().hushUser;
    if (user != null) {
      _followedFeed = await _socialService.getFollowedUsersFeed(user.followingIds);
    }
    if (mounted) setState(() => _isLoading = false);
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
    if (mounted) {
      setState(() {
        _searchResults = results;
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
      } else {
        await _socialService.followUser(currentUserFirebase.uid, targetUser.uid);
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
      appBar: AppBar(
        title: Text(l10n.followingTabTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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
          leading: CircleAvatar(
            backgroundColor: HushColors.bgCard,
            backgroundImage: user.photoURL != null && !user.useGenericPhoto ? NetworkImage(user.photoURL!) : null,
            child: (user.useGenericPhoto || user.photoURL == null) ? const HushIcon(HushIcons.person, size: 18, color: Colors.white) : null,
          ),
          title: Text('${user.firstName ?? ''} ${user.lastName ?? ''}'.trim().isNotEmpty ? '${user.firstName} ${user.lastName}' : (user.displayName ?? l10n.anonymousUser), style: const TextStyle(color: Colors.white)),
          subtitle: Text(l10n.tier(user.tierLevel), style: const TextStyle(color: HushColors.textAccent)),
          trailing: ElevatedButton(
            onPressed: () => _toggleFollow(user),
            style: ElevatedButton.styleFrom(
              backgroundColor: isFollowing ? Colors.transparent : HushColors.textAccent,
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
              if (secret != null) {
                // Navigate to MapScreen targeting the secret's coordinates
                Navigator.push(context, MaterialPageRoute(builder: (_) => MapScreen(targetLat: secret.lat, targetLng: secret.lng)));
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: HushColors.bgPrimary,
                    backgroundImage: user.photoURL != null && !user.useGenericPhoto ? NetworkImage(user.photoURL!) : null,
                    child: (user.useGenericPhoto || user.photoURL == null) ? const Icon(Icons.person, color: Colors.white, size: 24) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim().isNotEmpty ? '${user.firstName} ${user.lastName}' : (user.displayName ?? l10n.anonymousUser),
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        if (secret != null) ...[
                          Row(
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
                          const SizedBox(height: 4),
                          Text(l10n.tapToViewMap, style: const TextStyle(color: HushColors.textAccent, fontSize: 12)),
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
