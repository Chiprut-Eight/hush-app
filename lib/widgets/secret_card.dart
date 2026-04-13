import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:async';
import '../models/secret.dart';
import '../config/theme.dart';
import '../core/constants/icons.dart';
import '../providers/auth_provider.dart';
import '../services/secret_service.dart';
import '../services/audio_service.dart';
import '../utils/time_ago_util.dart';
import '../widgets/hush_icon_widget.dart';
import '../config/constants.dart';
import '../config/tiers.dart';
import '../screens/profile_screen.dart';
import 'package:hush_app/l10n/app_localizations.dart';

class SecretCard extends StatefulWidget {
  final Secret secret;
  final Position? userPosition;
  final VoidCallback? onReveal;
  final VoidCallback? onDelete;

  const SecretCard({
    super.key, 
    required this.secret,
    this.userPosition,
    this.onReveal,
    this.onDelete,
  });

  @override
  State<SecretCard> createState() => _SecretCardState();
}

class _SecretCardState extends State<SecretCard> {
  final SecretService _secretService = SecretService();
  final AudioService _audioService = AudioService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  late Secret _currentSecret;
  
  bool _revealed = false;
  bool _showWarning = false;
  
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  bool _userLiked = false;
  bool _userDisliked = false;
  
  StreamSubscription<CompassEvent>? _compassSubscription;
  StreamSubscription<int>? _attemptsSubscription;
  StreamSubscription<Secret>? _secretDocSubscription;
  int _activeParticipantsCount = 0;
  double? _deviceHeading;

  @override
  void initState() {
    super.initState();
    _currentSecret = widget.secret;

    // Default showWarning if highly downvoted or reported
    if (_currentSecret.dislikes > 3 && _currentSecret.dislikes > _currentSecret.likes) {
      _showWarning = true;
    }
    
    final currentUser = context.read<AuthProvider>().firebaseUser;
    
    // Start live secret data stream
    _secretDocSubscription = _secretService
        .getSecretStream(_currentSecret.id)
        .listen((updatedSecret) {
      if (mounted) {
        setState(() {
          _currentSecret = updatedSecret;
          // Auto-reveal for creators OR if already unlocked
          if (currentUser?.uid == _currentSecret.creatorId || _currentSecret.unlockedBy.contains(currentUser?.uid)) {
            if (!_revealed) {
              _revealed = true;
              if (_currentSecret.type == 'voice') _initAudio();
            }
          }
        });
      }
    });

    // Start participants counter stream for group secrets
    if (_currentSecret.isGroup) {
      final tier = HushTiers.getTier(_currentSecret.creatorTierLevel);
      _attemptsSubscription = _secretService
          .getUnlockAttemptsStream(_currentSecret.id, tier.timeWindowMinutes)
          .listen((count) {
        if (mounted) setState(() => _activeParticipantsCount = count);
      });
    }
    
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (mounted) {
        setState(() {
          _deviceHeading = event.heading;
        });
      }
    });
  }



  void _initAudio() async {
    try {
      if (_currentSecret.audioURL == null) return;
      
      // Use cached audio file for faster playback and lower data usage
      final file = await _audioService.getCachedAudioFile(_currentSecret.audioURL!);
      await _audioPlayer.setFilePath(file.path);
      
      _audioPlayer.durationStream.listen((d) {
        if (mounted && d != null) setState(() => _duration = d);
      });
      _audioPlayer.positionStream.listen((p) {
        if (mounted) setState(() => _position = p);
      });
      _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing && state.processingState != ProcessingState.completed;
          });
          if (state.processingState == ProcessingState.completed) {
            _audioPlayer.seek(Duration.zero);
            _audioPlayer.pause();
          }
        }
      });
    } catch (e) {
      debugPrint('Error loading audio: $e');
    }
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _attemptsSubscription?.cancel();
    _secretDocSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _secretService.viewSecret(_currentSecret.id);
      _audioPlayer.play();
    }
  }

  void _handleReveal() async {
    if (_showWarning) return; // Must accept warning first
    
    final currentUser = context.read<AuthProvider>().firebaseUser;
    if (currentUser == null) return;
    final l10n = AppLocalizations.of(context)!;

    // Check if it's a group secret and needs unlocking
    if (_currentSecret.isGroup && !_currentSecret.unlockedBy.contains(currentUser.uid)) {
      if (widget.userPosition == null) return;
      
      // Show instant feedback using local state to avoid noticeable network delay
      if (mounted) {
        final requiredCountLocal = _currentSecret.requiredUsers ?? 3;
        var remainingLocal = requiredCountLocal - _activeParticipantsCount;
        if (remainingLocal < 1) remainingLocal = 1; // Ensure logical display before server responds
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.groupUnlockProgress(remainingLocal),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            backgroundColor: HushColors.bgCard.withValues(alpha: 0.95),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: HushColors.textAccent, width: 0.5),
            ),
            elevation: 8,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      final result = await _secretService.verifyGroupUnlock(
        secretId: _currentSecret.id,
        lat: widget.userPosition!.latitude,
        lng: widget.userPosition!.longitude,
      );
      
      // Start Live Subscriptions if not already started (Handled by initState now)
      
      if (result['success'] == true) {
        if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
        setState(() => _revealed = true);
        if (_currentSecret.type == 'voice') _initAudio();
        _secretService.viewSecret(_currentSecret.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.groupUnlockSuccess, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: HushColors.textAccent.withValues(alpha: 0.9),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        
        if (widget.onReveal != null) widget.onReveal!();
      } else {
        // Show current progress localized
        if (mounted) {
          final requiredCount = (result['requiredCount'] as int?) ?? _currentSecret.requiredUsers ?? 3;
          final currentCount = (result['currentCount'] as int?) ?? 0;
          final remaining = requiredCount - currentCount;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.groupUnlockProgress(remaining),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              backgroundColor: HushColors.bgCard.withValues(alpha: 0.95),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: HushColors.textAccent, width: 0.5),
              ),
              elevation: 8,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } else {
      // Regular secret or already unlocked group secret
      setState(() => _revealed = true);
      if (_currentSecret.type == 'voice') _initAudio();
      _secretService.viewSecret(_currentSecret.id);
      if (widget.onReveal != null) widget.onReveal!();
    }
  }

  Color _getTierColor() {
    try {
      final hexCode = _currentSecret.creatorTierColor.replaceAll('#', '0xFF');
      return Color(int.parse(hexCode));
    } catch (_) {
      return Colors.grey;
    }
  }

  /// Calculate bearing from user position to secret position (in radians)
  double _getBearing() {
    if (widget.userPosition == null) return 0;
    final lat1 = widget.userPosition!.latitude * math.pi / 180;
    final lat2 = _currentSecret.lat * math.pi / 180;
    final dLng = (_currentSecret.lng - widget.userPosition!.longitude) * math.pi / 180;

    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    
    final bearing = math.atan2(y, x);
    final bearingDegrees = (bearing * 180.0 / math.pi + 360.0) % 360.0;
    
    // Live compass adjustment relative to device heading
    if (_deviceHeading != null) {
      return (bearingDegrees - _deviceHeading!) * (math.pi / 180.0);
    }

    return bearing;
  }

  /// Show report dialog
  void _showReportDialog(BuildContext context, AppLocalizations l10n) {
    String? selectedReason;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          final reasons = [
            l10n.reportReasonHate,
            l10n.reportReasonSpam,
            l10n.reportReasonHarassment,
            l10n.reportReasonViolence,
            l10n.reportReasonOther,
          ];
          return AlertDialog(
            backgroundColor: HushColors.bgCard,
            title: Text(l10n.reportTitle, style: const TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.reportReason, style: const TextStyle(color: HushColors.textSecondary)),
                const SizedBox(height: 12),
                ...reasons.map((reason) => GestureDetector(
                  onTap: () => setDialogState(() => selectedReason = reason),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          selectedReason == reason ? Icons.check_circle : Icons.circle_outlined,
                          color: selectedReason == reason ? HushColors.textAccent : HushColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(reason, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ),
                )),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancel, style: const TextStyle(color: HushColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: selectedReason == null ? null : () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await _secretService.reportSecretWithDetails(
                    _currentSecret.id, 
                    selectedReason!,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(l10n.reportSuccess)),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: HushColors.tierRed),
                child: Text(l10n.reportConfirm, style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        });
      },
    );
  }

  /// Show delete confirmation
  void _showDeleteConfirmation(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HushColors.bgCard,
        title: Text(l10n.deleteSecretTitle, style: const TextStyle(color: Colors.white)),
        content: Text(l10n.deleteSecretConfirm, style: const TextStyle(color: HushColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel, style: const TextStyle(color: HushColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              await _secretService.deleteSecret(_currentSecret.id);
              if (ctx.mounted) Navigator.pop(ctx);
              if (widget.onDelete != null) widget.onDelete!();
            },
            style: ElevatedButton.styleFrom(backgroundColor: HushColors.tierRed),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Show comments bottom sheet
  void _showCommentsSheet(BuildContext context, AppLocalizations l10n) {
    final TextEditingController commentController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: HushColors.bgPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (ctx, setSheetState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: SizedBox(
                  height: MediaQuery.of(ctx).size.height * 0.6,
                  child: Column(
                    children: [
                      // Handle bar
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: HushColors.textMuted,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(l10n.comments, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                      const Divider(color: HushColors.borderSubtle, height: 1),
                      // Comments list
                      Expanded(
                        child: StreamBuilder<List<Map<String, dynamic>>>(
                          stream: _secretService.getCommentsStream(_currentSecret.id),
                          builder: (ctx, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator(color: HushColors.textAccent));
                            }
                            final comments = snapshot.data ?? [];
                            if (comments.isEmpty) {
                              return Center(
                                child: Text(l10n.noComments, style: const TextStyle(color: HushColors.textSecondary)),
                              );
                            }
                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: comments.length,
                              itemBuilder: (ctx, i) {
                                final c = comments[i];
                                final commentTime = (c['createdAt'] as DateTime?) ?? DateTime.now();
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: HushColors.bgCard,
                                        backgroundImage: c['userPhotoURL'] != null && c['userPhotoURL'] != 'generic'
                                            ? NetworkImage(c['userPhotoURL'])
                                            : null,
                                        child: c['userPhotoURL'] == null || c['userPhotoURL'] == 'generic'
                                            ? const HushIcon(HushIcons.person, size: 14, color: Colors.white54)
                                            : null,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(c['userName'] ?? l10n.anonymousUser, 
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                                const SizedBox(width: 8),
                                                Text(getTimeAgo(commentTime, l10n),
                                                  style: const TextStyle(color: HushColors.textMuted, fontSize: 11)),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(c['text'] ?? '', style: const TextStyle(color: HushColors.textSecondary, fontSize: 14)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const Divider(color: HushColors.borderSubtle, height: 1),
                      // Input field
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: commentController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: l10n.commentPlaceholder,
                                  hintStyle: const TextStyle(color: HushColors.textMuted),
                                  filled: true,
                                  fillColor: HushColors.bgCard,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const HushIcon(HushIcons.send, size: 20, color: HushColors.textAccent),
                              onPressed: () async {
                                final text = commentController.text.trim();
                                if (text.isEmpty) return;
                                await _secretService.addComment(_currentSecret.id, text);
                                commentController.clear();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthProvider>().firebaseUser;
    final hushUser = context.read<AuthProvider>().hushUser;
    
    // Check Proximity
    double? distance;
    bool isInRange = true; // For profile or when position not given
    
    if (widget.userPosition != null) {
      distance = Geolocator.distanceBetween(
        widget.userPosition!.latitude, 
        widget.userPosition!.longitude, 
        _currentSecret.lat, 
        _currentSecret.lng
      );
      final tier = HushTiers.getTier(_currentSecret.creatorTierLevel);
      final double effectiveRadius = _currentSecret.isGroup 
          ? tier.revealRadius 
          : AppConstants.revealRadiusMeters;
      
      isInRange = distance <= effectiveRadius;
    }
    
    bool isGroup = _currentSecret.isGroup; // Use model's isGroup instead of type check
    bool userSaved = hushUser?.savedSecretIds.contains(_currentSecret.id) ?? false;
    bool isOwner = currentUser?.uid == _currentSecret.creatorId;
    
    final l10n = AppLocalizations.of(context)!;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: isInRange && !_revealed ? _handleReveal : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2638).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : HushColors.borderLightMode, width: 1),
          boxShadow: [
            // Inner bright glow
            BoxShadow(
              color: _getTierColor().withValues(alpha: 0.25),
              blurRadius: 12,
              spreadRadius: 1,
            ),
            // Outer wide aura
            BoxShadow(
              color: _getTierColor().withValues(alpha: 0.15),
              blurRadius: 25,
              spreadRadius: 4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ColorFilter.mode(Colors.black.withValues(alpha: 0.2), BlendMode.darken),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- TOP HEADER ROW ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProfileScreen(targetUserId: _currentSecret.creatorId),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: _getTierColor(),
                                    child: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: isDark ? HushColors.bgPrimary : HushColors.bgPrimaryLight,
                                      backgroundImage: _currentSecret.creatorPhotoURL != null && _currentSecret.creatorPhotoURL != 'generic'
                                          ? NetworkImage(_currentSecret.creatorPhotoURL!)
                                          : null,
                                      child: _currentSecret.creatorPhotoURL == 'generic' || _currentSecret.creatorPhotoURL == null
                                          ? HushIcon(HushIcons.person, size: 18, color: isDark ? Colors.white54 : HushColors.textSecondaryLight)
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                _currentSecret.creatorName ?? 'Anonymous',
                                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            // --- TIME AGO ---
                                            Text(
                                              getTimeAgo(_currentSecret.createdAt, l10n),
                                              style: const TextStyle(color: HushColors.textMuted, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          isGroup ? l10n.groupSecret : l10n.regularSecret,
                                          style: TextStyle(color: isGroup ? _getTierColor() : HushColors.textSecondary, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Distance + delete button for owner
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (distance != null)
                                Text(
                                  distance > 1000 
                                      ? l10n.distanceAwayKm((distance / 1000).toStringAsFixed(1))
                                      : l10n.distanceAwayMeters(distance.toInt()),
                                  style: const TextStyle(color: HushColors.textSecondary, fontSize: 12),
                                ),
                              if (isOwner) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _showDeleteConfirmation(context, l10n),
                                  child: const HushIcon(HushIcons.trash, size: 20, color: HushColors.tierRed),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // --- CONTENT BLUR/REVEAL ---
                      if (_revealed || !isInRange)
                        _buildContent(isInRange, l10n)
                      else if (isInRange && !_revealed)
                        _buildTapToReveal(l10n),

                      // --- COMPASS for out-of-range secrets ---
                      if (!isInRange && widget.userPosition != null)
                        _buildCompass(l10n),

                      const SizedBox(height: 16),

                      // --- BOTTOM ACTIONS ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _InteractionButton(
                                icon: _userLiked ? HushIcons.heartFilled : HushIcons.heart,
                                count: _currentSecret.likes + (_userLiked ? 1 : 0),
                                isActive: _userLiked,
                                color: _userLiked ? Colors.pink : HushColors.textSecondary,
                                onTap: _revealed ? () {
                                  setState(() {
                                    if (_userDisliked) _userDisliked = false;
                                    _userLiked = !_userLiked;
                                    if (_userLiked) _secretService.likeSecret(_currentSecret.id);
                                  });
                                } : () {},
                              ),
                              const SizedBox(width: 16),
                              _InteractionButton(
                                icon: HushIcons.thumbsDown,
                                count: _currentSecret.dislikes + (_userDisliked ? 1 : 0),
                                isActive: _userDisliked,
                                color: _userDisliked ? Colors.orange : HushColors.textSecondary,
                                onTap: _revealed ? () {
                                  setState(() {
                                    if (_userLiked) _userLiked = false;
                                    _userDisliked = !_userDisliked;
                                    if (_userDisliked) _secretService.dislikeSecret(_currentSecret.id);
                                  });
                                } : null,
                              ),
                              const SizedBox(width: 16),
                              _InteractionButton(
                                icon: HushIcons.comment,
                                count: 0,
                                isActive: false,
                                color: _revealed ? HushColors.textSecondary : HushColors.textSecondary.withValues(alpha: 0.3),
                                onTap: _revealed ? () => _showCommentsSheet(context, l10n) : null,
                              ),
                              const SizedBox(width: 16),
                              Row(
                                children: [
                                  const HushIcon(HushIcons.eye, size: 16, color: HushColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text('${_currentSecret.views}', style: const TextStyle(color: HushColors.textSecondary)),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              // --- REPORT BUTTON ---
                              GestureDetector(
                                onTap: _revealed ? () => _showReportDialog(context, l10n) : null,
                                child: HushIcon(HushIcons.flag, size: 18, color: (_revealed || isOwner) ? HushColors.tierRed : HushColors.tierRed.withValues(alpha: 0.3)),
                              ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap: (_revealed) ? () {
                                  if (currentUser != null) {
                                    if (!userSaved && (hushUser?.savedSecretIds.length ?? 0) >= 50) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(l10n.saveLimitWarning)),
                                      );
                                      return;
                                    }
                                    setState(() {
                                      _secretService.toggleSaveSecret(_currentSecret.id);
                                    });
                                  }
                                } : null,
                                child: Row(
                                  children: [
                                    HushIcon(userSaved ? HushIcons.bookmarkFilled : HushIcons.pin, size: 18, color: userSaved ? HushColors.textAccent : (_revealed ? HushColors.textSecondary : HushColors.textSecondary.withValues(alpha: 0.3))),
                                    const SizedBox(width: 4),
                                    Text(userSaved ? l10n.saved : l10n.save, style: TextStyle(color: userSaved ? HushColors.textAccent : (_revealed ? HushColors.textSecondary : HushColors.textSecondary.withValues(alpha: 0.3)), fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                // --- CONTENT WARNING OVERLAY ---
                if (_showWarning)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            HushIcon(HushIcons.warning, size: 32, color: Colors.amber),
                            const SizedBox(height: 8),
                            Text(l10n.contentWarning, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(l10n.downvotedWarning, style: const TextStyle(color: HushColors.textSecondary, fontSize: 12)),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: () {}, // cancel
                                  child: Text(l10n.cancel, style: const TextStyle(color: HushColors.textSecondary)),
                                ),
                                ElevatedButton(
                                  onPressed: () => setState(() => _showWarning = false),
                                  style: ElevatedButton.styleFrom(backgroundColor: HushColors.tierRed),
                                  child: Text(l10n.viewAnyway, style: const TextStyle(color: Colors.white)),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isInRange, AppLocalizations l10n) {
    if (!isInRange || !_revealed) {
      // --- ENHANCED SMOKY BLUR EFFECT ---
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8), // Dark base
          ),
          child: Stack(
            children: [
              // Dummy content to be blurred
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Column(
                  children: [
                    if (_currentSecret.textContent != null)
                      Container(height: 20, width: double.infinity, color: HushColors.textAccent.withValues(alpha: 0.3))
                    else
                      Container(height: 40, width: double.infinity, color: HushColors.textAccent.withValues(alpha: 0.3)),
                  ],
                ),
              ),
              // The heavy smoky blur overlay
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.5,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.grey.shade900.withValues(alpha: 0.7),
                          Colors.black.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Centered mystical text
              Positioned.fill(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      l10n.secretReady,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: HushColors.textAccent.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(color: HushColors.tierRed.withValues(alpha: 0.5), blurRadius: 10),
                        ]
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Revealed Content
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: _currentSecret.textContent != null
          ? Text(_currentSecret.textContent!, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4))
          : Directionality(
              // Task 5: Force LTR for audio player
              textDirection: TextDirection.ltr,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: HushIcon(_isPlaying ? HushIcons.pause : HushIcons.play, size: 40, color: HushColors.textAccent),
                      onPressed: _togglePlay,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: HushColors.textAccent,
                          inactiveTrackColor: Colors.white24,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        ),
                        child: Slider(
                          value: _position.inMilliseconds.toDouble(),
                          max: _duration.inMilliseconds > 0 ? _duration.inMilliseconds.toDouble() : 100,
                          onChanged: (val) => _audioPlayer.seek(Duration(milliseconds: val.toInt())),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      );
    }
  }

  /// Minimalist compass widget pointing toward the secret (Task 3)
  Widget _buildCompass(AppLocalizations l10n) {
    final bearing = _getBearing();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.rotate(
            angle: bearing,
            child: HushIcon(
              HushIcons.navigation,
              color: HushColors.textAccent.withValues(alpha: 0.7),
              size: 22,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            l10n.directionToSecret,
            style: TextStyle(
              color: HushColors.textAccent.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTapToReveal(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: HushColors.textAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HushColors.textAccent.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Column(
          children: [
            HushIcon(
              _currentSecret.isGroup ? HushIcons.users : HushIcons.touch, 
              size: 32, 
              color: HushColors.textAccent
            ),
            const SizedBox(height: 8),
            Text(
              _currentSecret.isGroup ? l10n.groupSecret : l10n.tapToReveal, 
              style: const TextStyle(color: HushColors.textAccent, fontWeight: FontWeight.bold)
            ),
            if (_currentSecret.isGroup) ...[
              const SizedBox(height: 4),
              Text(
                _activeParticipantsCount > 0 
                    ? '$_activeParticipantsCount / ${_currentSecret.requiredUsers ?? 3} ${l10n.peopleRequired}'
                    : '${l10n.peopleRequired}: ${_currentSecret.requiredUsers ?? 3}',
                style: TextStyle(
                  color: _activeParticipantsCount > 0 ? HushColors.textAccent : HushColors.textSecondary, 
                  fontSize: 12,
                  fontWeight: _activeParticipantsCount > 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InteractionButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final bool isActive;
  final Color color;
  final VoidCallback? onTap;

  const _InteractionButton({
    required this.icon, 
    required this.count, 
    required this.isActive, 
    required this.color,
    this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: [
            HushIcon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text('$count', style: TextStyle(color: isActive ? Colors.white : HushColors.textSecondary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
