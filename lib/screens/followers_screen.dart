import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/hush_user.dart';
import '../providers/auth_provider.dart';
import '../services/social_service.dart';
import 'profile_screen.dart';
import 'package:hush_app/l10n/app_localizations.dart';

class FollowersScreen extends StatefulWidget {
  final List<String> followerIds;

  const FollowersScreen({super.key, required this.followerIds});

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  final SocialService _socialService = SocialService();
  List<HushUser> _followers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFollowers();
  }

  Future<void> _fetchFollowers() async {
    final users = await _socialService.getUsersByIds(widget.followerIds);
    if (mounted) {
      setState(() {
        _followers = users;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = context.watch<AuthProvider>().hushUser;
    final followingIds = currentUser?.followingIds ?? [];

    return Scaffold(
      backgroundColor: HushColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: HushColors.bgPrimary,
        elevation: 0,
        title: Text(l10n.followers, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: HushColors.textAccent))
          : _followers.isEmpty
              ? Center(child: Text(l10n.noUsersFound, style: const TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: _followers.length,
                  itemBuilder: (context, index) {
                    final user = _followers[index];
                    final isFollowing = followingIds.contains(user.uid);

                    return ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ProfileScreen(targetUserId: user.uid)),
                        );
                      },
                      leading: CircleAvatar(
                        backgroundColor: HushColors.bgCard,
                        backgroundImage: (user.useGenericPhoto || user.photoURL == null)
                            ? const AssetImage('assets/images/icon_only.png')
                            : NetworkImage(user.photoURL!),
                      ),
                      title: Text(
                        '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim().isNotEmpty
                            ? '${user.firstName} ${user.lastName}'
                            : (user.displayName ?? l10n.anonymousUser),
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(l10n.tier(user.tierLevel), style: const TextStyle(color: HushColors.textAccent)),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          if (currentUser == null) return;
                          if (isFollowing) {
                            await _socialService.unfollowUser(currentUser.uid, user.uid);
                          } else {
                            await _socialService.followUser(currentUser.uid, user.uid);
                          }
                          if (context.mounted) {
                            await context.read<AuthProvider>().refreshProfile();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFollowing ? Colors.transparent : const Color(0xFF1565C0),
                          side: isFollowing ? const BorderSide(color: HushColors.textAccent) : null,
                        ),
                        child: Text(
                          isFollowing ? l10n.unfollowBtn : l10n.followBtn,
                          style: TextStyle(color: isFollowing ? HushColors.textAccent : Colors.white),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
