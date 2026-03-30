import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/hush_user.dart';
import '../providers/auth_provider.dart';
import '../services/social_service.dart';
import 'map_screen.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // We can use localizations or fallback to english strings since l10n wasn't updated with these keys yet
    const title = 'Following';
    const searchHint = 'Search users...';

    return Scaffold(
      backgroundColor: HushColors.bgPrimary,
      appBar: AppBar(
        title: const Text(title),
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
                hintText: searchHint,
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: HushColors.textAccent),
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
                    ? _buildSearchResults()
                    : _buildFollowedFeed(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(child: Text('No users found', style: TextStyle(color: Colors.white54)));
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
            child: (user.useGenericPhoto || user.photoURL == null) ? const Icon(Icons.person, color: Colors.white) : null,
          ),
          title: Text('${user.firstName ?? ''} ${user.lastName ?? ''}'.trim().isNotEmpty ? '${user.firstName} ${user.lastName}' : (user.displayName ?? 'Anonymous'), style: const TextStyle(color: Colors.white)),
          subtitle: Text('Tier ${user.tierLevel}', style: const TextStyle(color: HushColors.textAccent)),
          trailing: ElevatedButton(
            onPressed: () => _toggleFollow(user),
            style: ElevatedButton.styleFrom(
              backgroundColor: isFollowing ? Colors.transparent : HushColors.textAccent,
              side: isFollowing ? const BorderSide(color: HushColors.textAccent) : null,
            ),
            child: Text(isFollowing ? 'Unfollow' : 'Follow', style: TextStyle(color: isFollowing ? HushColors.textAccent : Colors.white)),
          ),
        );
      },
    );
  }

  Widget _buildFollowedFeed() {
    if (_followedFeed.isEmpty) {
      return const Center(
        child: Text('You are not following anyone yet.', style: TextStyle(color: Colors.white54)),
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
                          '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim().isNotEmpty ? '${user.firstName} ${user.lastName}' : (user.displayName ?? 'Anonymous'),
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        if (secret != null) ...[
                          Row(
                            children: [
                              Icon(secret.type == 'voice' ? Icons.mic : Icons.text_snippet, size: 14, color: HushColors.textAccent),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Published a secret ${DateTime.now().difference(secret.createdAt).inHours}h ago',
                                  style: const TextStyle(color: HushColors.textSecondary, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text('Tap to view on map', style: TextStyle(color: HushColors.textAccent, fontSize: 12)),
                        ] else ...[
                          const Text('No active secrets', style: TextStyle(color: HushColors.textMuted, fontSize: 12)),
                        ]
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
