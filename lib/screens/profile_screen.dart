import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hush_app/l10n/app_localizations.dart';
import '../config/theme.dart';
import '../core/constants/icons.dart';
import '../providers/auth_provider.dart';
import '../models/secret.dart';
import '../services/secret_service.dart';
import 'package:hush_app/models/hush_user.dart';
import '../services/social_service.dart';
import '../widgets/secret_card.dart';
import '../widgets/hush_icon_widget.dart';
import '../widgets/hush_drawer.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';

/// Profile screen — user info, published/saved secrets, ghost mode, admin, sign out
class ProfileScreen extends StatefulWidget {
  final String? targetUserId;
  const ProfileScreen({super.key, this.targetUserId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SecretService _secretService = SecretService();
  final SocialService _socialService = SocialService();
  
  HushUser? _targetUser;
  List<Secret> _mySecrets = [];
  List<Secret> _savedSecrets = [];
  bool _isLoading = true;
  int _activeTabIndex = 0; // 0 for 'My Secrets', 1 for 'Saved Secrets'
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    final auth = context.read<AuthProvider>();
    final currentUser = auth.hushUser;
    
    final String uidToFetch = widget.targetUserId ?? currentUser?.uid ?? '';
    if (uidToFetch.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Fetch User Data if it's someone else
      HushUser? user;
      if (widget.targetUserId == null || widget.targetUserId == currentUser?.uid) {
        user = currentUser;
      } else {
        user = await _socialService.getUserById(uidToFetch);
      }

      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 2. Fetch Secrets
      final results = await Future.wait([
        _secretService.getUserSecrets(uidToFetch),
        _secretService.getSavedSecrets(user.savedSecretIds),
      ]);
      
      final now = DateTime.now();
      final myActive = results[0].where((s) => Secret.isSurvivor(s, now)).toList();
      final savedActive = results[1].where((s) => Secret.isSurvivor(s, now)).toList();
      
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
            _userPosition = await Geolocator.getCurrentPosition();
          }
        }
      } catch (e) {
        debugPrint('Could not fetch location for profile view: $e');
      }
      
      if (mounted) {
        setState(() {
          _targetUser = user;
          _mySecrets = myActive;
          _savedSecrets = savedActive;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch profile data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final auth = context.read<AuthProvider>();
    final currentUser = auth.hushUser;
    if (currentUser == null || _targetUser == null) return;

    final isFollowing = currentUser.followingIds.contains(_targetUser!.uid);
    try {
      if (isFollowing) {
        await _socialService.unfollowUser(currentUser.uid, _targetUser!.uid);
      } else {
        await _socialService.followUser(currentUser.uid, _targetUser!.uid);
      }
      await auth.refreshProfile();
      await _fetchProfileData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.hushUser;
    final user = _targetUser;

    if (user == null && _isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (user == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('User not found')));
    }

    final bool isMe = widget.targetUserId == null || widget.targetUserId == currentUser?.uid;
    final isFollowing = currentUser?.followingIds.contains(user.uid) ?? false;

    return Scaffold(
      drawer: isMe ? const HushDrawer() : null,
      appBar: AppBar(
        title: Text(isMe ? l10n.profileTitle : (user.displayName ?? l10n.anonymousUser)),
        leading: !isMe ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)) : null,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (isMe) await auth.refreshProfile();
          await _fetchProfileData();
        },
        color: HushColors.textAccent,
        backgroundColor: HushColors.bgPrimary,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            // Ghost Mode Banner (Only for Me)
            if (isMe && user.isGhostMode)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: HushColors.tierRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: HushColors.tierRed.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      l10n.ghostModeActive,
                      style: const TextStyle(color: HushColors.tierRed, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.ghostModeRestricted,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: HushColors.tierRed),
                      onPressed: () => _showAppealDialog(context, l10n),
                      child: Text(l10n.appeal, style: const TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              ),

            // User avatar and name
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: HushColors.bgCard,
                    backgroundImage: user.photoURL != null && !user.useGenericPhoto
                        ? NetworkImage(user.photoURL!)
                        : null,
                    child: (user.useGenericPhoto || user.photoURL == null)
                        ? const HushIcon(HushIcons.person, size: 48, color: HushColors.textMuted)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.displayName ?? 'Anonymous',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  
                  // Wrap in row to handle Tier + Follow
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: HushColors.tierColor(user.tierLevel).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: HushColors.tierColor(user.tierLevel).withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          l10n.tier(user.tierLevel),
                          style: TextStyle(
                            color: HushColors.tierColor(user.tierLevel),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (!isMe) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _toggleFollow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFollowing ? Colors.transparent : HushColors.textAccent,
                        side: isFollowing ? const BorderSide(color: HushColors.textAccent) : null,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                      ),
                      child: Text(
                        isFollowing ? l10n.unfollowBtn : l10n.followBtn,
                        style: TextStyle(color: isFollowing ? HushColors.textAccent : Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Stats cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildStatRow(l10n.publishedSecrets, '${_mySecrets.length}'),
                  _buildStatRow(l10n.followers, '${user.followerIds.length}'),
                  _buildStatRow(l10n.distinguished, '${user.distinguishedCount}'),
                ],
              ),
            ),

            const SizedBox(height: 32),
            
            // Tab Switcher for Secrets (Only show 'My Secrets' tab for public view)
            if (isMe) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CupertinoSlidingSegmentedControl<int>(
                  backgroundColor: HushColors.bgCard,
                  thumbColor: const Color(0xFF1E2638), // Slightly lighter than bgCard
                  groupValue: _activeTabIndex,
                  padding: const EdgeInsets.all(4),
                  children: {
                    0: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(l10n.mySecretsTab, style: TextStyle(color: _activeTabIndex == 0 ? Colors.white : HushColors.textMuted, fontWeight: FontWeight.w600)),
                    ),
                    1: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('${l10n.savedSecrets} (${_savedSecrets.length})', style: TextStyle(color: _activeTabIndex == 1 ? Colors.white : HushColors.textMuted, fontWeight: FontWeight.w600)),
                    ),
                  },
                  onValueChanged: (int? value) {
                    if (value != null) {
                      setState(() => _activeTabIndex = value);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Secrets List Builder
            if (_isLoading)
              const Center(child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(color: HushColors.textAccent),
              ))
            else ..._buildActiveTabList(l10n, isMe),

            const SizedBox(height: 32),
            
            // Footer Info
            Center(
              child: Text(
                'HUSH v1.0.0',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 12),
              ),
            ),
            
            const SizedBox(height: 80), // Padding for bottom navbar
          ],
        ),
      ),
    );
  }
  
  List<Widget> _buildActiveTabList(AppLocalizations l10n, bool isMe) {
    // For public view, always show published secrets
    final list = (isMe && _activeTabIndex == 1) ? _savedSecrets : _mySecrets;
    
    if (list.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              children: [
                Icon(
                  (isMe && _activeTabIndex == 1) ? Icons.bookmark_border : Icons.edit_note,
                  size: 48, color: HushColors.textSecondary.withValues(alpha: 0.5)
                ),
                const SizedBox(height: 16),
                Text(
                  (isMe && _activeTabIndex == 1) ? l10n.noSavedSecrets : l10n.noPlantedSecrets,
                  style: TextStyle(color: HushColors.textSecondary.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        )
      ];
    }
    
    return list.map((secret) => SecretCard(
      secret: secret,
      userPosition: _userPosition,
      onDelete: isMe ? _fetchProfileData : null,
    )).toList();
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: HushColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: HushColors.borderSubtle),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: HushColors.textSecondary)),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: HushColors.textPrimary,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAppealDialog(BuildContext context, AppLocalizations l10n) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HushColors.bgCard,
        title: Text(l10n.appealTitle, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.appealReason, style: const TextStyle(color: HushColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: HushColors.bgPrimary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel, style: const TextStyle(color: HushColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              final messenger = ScaffoldMessenger.of(context);
              await _secretService.submitAppeal(reason);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.appealSuccess)),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: HushColors.textAccent),
            child: Text(l10n.appealSubmit, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
