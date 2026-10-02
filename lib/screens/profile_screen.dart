import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hush_app/l10n/app_localizations.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../models/secret.dart';
import '../services/secret_service.dart';
import 'package:hush_app/models/hush_user.dart';
import '../services/social_service.dart';
import '../widgets/secret_card.dart';
import '../config/tiers.dart';

import 'package:hush_app/mocks/geolocator_mock.dart';
import '../services/analytics_service.dart';
import '../widgets/title_setter.dart';
import 'followers_screen.dart';
import 'saved_secrets_screen.dart';

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
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
    AnalyticsService().logScreenView(widget.targetUserId == null ? 'profile' : 'user_profile');
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
      // Saved secrets are always shown — isSurvivor immunity applies at Firestore level,
      // but client-side we trust the user's explicit save action. Never filter them out.
      final savedActive = results[1]; // Don't filter by isSurvivor — saved = immune
      
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
        AnalyticsService().logUnfollow(_targetUser!.uid);
      } else {
        await _socialService.followUser(currentUser.uid, _targetUser!.uid);
        AnalyticsService().logFollow(_targetUser!.uid);
      }
      await auth.refreshProfile();
      await _fetchProfileData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  String _getTierName(BuildContext context, int level) {
    final l10n = AppLocalizations.of(context)!;
    switch (level) {
      case 1: return l10n.tier(1);
      case 2: return "${l10n.tier(2)} (${l10n.tier2Name})";
      case 3: return "${l10n.tier(3)} (${l10n.tier3Name})";
      case 4: return "${l10n.tier(4)} (${l10n.tier4Name})";
      case 5: return "${l10n.tier(5)} (${l10n.tier5Name})";
      case 6: return "${l10n.tier(6)} (${l10n.tier6Name})";
      case 7: return "${l10n.tier(7)} (${l10n.tier7Name})";
      case 8: return "${l10n.tier(8)} (${l10n.tier8Name})";
      case 9: return "${l10n.tier(9)} (${l10n.tier9Name})";
      case 10: return "${l10n.tier(10)} (${l10n.tier10Name})";
      default: return l10n.tier(1);
    }
  }

  void _showNextTierInfo(BuildContext context, HushUser user) {
    if (user.tierLevel >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('הגעת לדרגה הגבוהה ביותר!')),
      );
      return;
    }

    final currentTierDef = HushTiers.tiers.firstWhere((t) => t.level == user.tierLevel);
    final nextTierDef = HushTiers.tiers.firstWhere((t) => t.level == user.tierLevel + 1);
    final requiredTotal = nextTierDef.requiredSuccesses;
    final currentSuccesses = user.groupSuccesses;
    final missingSuccesses = (requiredTotal - currentSuccesses) > 0 ? (requiredTotal - currentSuccesses) : 0;
    
    final nextTierName = _getTierName(context, nextTierDef.level);
    final requiredUsersForSuccess = currentTierDef.maxGroupUsers;
    final isHe = Localizations.localeOf(context).languageCode == 'he';
    
    final message = isHe
      ? 'הדרגה הבאה היא $nextTierName! כדי להגיע אליה ולהיות מזוהים כיוצרי Hushhh מובילים - צריך שיפתחו עוד $missingSuccesses Hushhh קבוצתיים שהשארת - כשכל אחד מהם יפתח על ידי $requiredUsersForSuccess אנשים לפחות.'
      : 'Your next tier is $nextTierName! To reach it and be recognized as a top Hushhh creator, you need $missingSuccesses more of your Group Hushhhs to be opened - with each being opened by at least $requiredUsersForSuccess people.';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HushColors.bgCard,
        title: Row(
          children: [
            Icon(Icons.auto_graph, color: nextTierDef.color),
            const SizedBox(width: 8),
            Text(
              isHe ? 'אתם בדרך הנכונה' : 'You are on the right track',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: HushColors.textSecondary, height: 1.5, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isHe ? 'הבנתי' : 'Got it', style: const TextStyle(color: HushColors.textAccent)),
          ),
        ],
      ),
    );
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
      return Scaffold(
        appBar: AppBar(),
        backgroundColor: HushColors.bgPrimary,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off_outlined, size: 64, color: HushColors.textSecondary.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                l10n.noUsersFound,
                style: const TextStyle(color: HushColors.textSecondary, fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    final bool isMe = widget.targetUserId == null || widget.targetUserId == currentUser?.uid;
    final isFollowing = currentUser?.followingIds.contains(user.uid) ?? false;
    final theyFollowMe = user.followingIds.contains(currentUser?.uid);
    final String titleStr = isMe ? l10n.profileTitle : (user.displayName ?? l10n.anonymousUser);

    Widget content = Scaffold(
      backgroundColor: Colors.transparent,
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
                        : const AssetImage('assets/images/icon_only.png'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.displayName ?? user.firstName ?? user.email?.split('@').first ?? 'Anonymous',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  
                  // Wrap in row to handle Tier + Follow
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => _showNextTierInfo(context, user),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: HushColors.tierColor(user.tierLevel).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: HushColors.tierColor(user.tierLevel).withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            _getTierName(context, user.tierLevel),
                            style: TextStyle(
                              color: HushColors.tierColor(user.tierLevel),
                              fontWeight: FontWeight.w600,
                            ),
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
                        isFollowing 
                            ? l10n.unfollowBtn 
                            : (theyFollowMe ? l10n.followBackBtn : l10n.followBtn),
                        style: TextStyle(color: isFollowing ? HushColors.textAccent : Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Stats row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: HushColors.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: HushColors.borderSubtle),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatBlock(l10n.publishedSecrets, '${_mySecrets.length}'),
                    Container(width: 1, height: 40, color: HushColors.borderSubtle),
                    if (isMe) ...[
                      _buildStatBlock(
                        l10n.savedSecrets, 
                        '${_savedSecrets.length}',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SavedSecretsScreen(
                                savedSecrets: _savedSecrets,
                                onUnsave: () {
                                  _fetchProfileData(); // Refresh if they unsave
                                },
                              ),
                            ),
                          );
                        },
                      ),
                      Container(width: 1, height: 40, color: HushColors.borderSubtle),
                    ],
                    _buildStatBlock(
                      l10n.followers, 
                      '${user.followerIds.length}',
                      onTap: isMe ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FollowersScreen(followerIds: user.followerIds),
                          ),
                        );
                      } : null,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            
            // Secrets List Builder (Always show My Secrets)
            if (_isLoading)
              const Center(child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(color: HushColors.textAccent),
              ))
            else ..._buildActiveTabList(l10n, isMe),

            const SizedBox(height: 80), // Padding for bottom navbar
          ],
        ),
      ),
    );

    final bool isPushed = ModalRoute.of(context)?.isFirst == false;
    if (!isMe || isPushed) {
      content = TitleSetter(title: titleStr, child: content);
    }
    return content;
  }
  
  List<Widget> _buildActiveTabList(AppLocalizations l10n, bool isMe) {
    if (_mySecrets.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.edit_note,
                  size: 48, color: HushColors.textSecondary.withValues(alpha: 0.5)
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.noPlantedSecrets, // or l10n.noActiveSecrets if l10n.noPlantedSecrets is unavailable
                  style: TextStyle(color: HushColors.textSecondary.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        )
      ];
    }
    
    return _mySecrets.map((secret) => SecretCard(
      key: ValueKey(secret.id),
      secret: secret,
      userPosition: _userPosition,
      onDelete: isMe ? () {
        setState(() {
          _mySecrets.removeWhere((s) => s.id == secret.id);
        });
      } : null,
    )).toList();
  }

  Widget _buildStatBlock(String label, String value, {VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: HushColors.textPrimary,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(color: HushColors.textSecondary, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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
              AnalyticsService().logAppealSubmitted();
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
