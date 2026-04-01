import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:geolocator/geolocator.dart';
import '../models/secret.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/secret_service.dart';
import '../utils/time_ago_util.dart';
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
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _revealed = false;
  bool _showWarning = false;
  
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  bool _userLiked = false;
  bool _userDisliked = false;

  @override
  void initState() {
    super.initState();
    // Default showWarning if highly downvoted or reported
    if (widget.secret.dislikes > 3 && widget.secret.dislikes > widget.secret.likes) {
      _showWarning = true;
    }
  }

  Future<void> _initAudio() async {
    try {
      if (widget.secret.audioURL == null) return;
      await _audioPlayer.setUrl(widget.secret.audioURL!);
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
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _secretService.listenSecret(widget.secret.id);
      _audioPlayer.play();
    }
  }

  void _handleReveal() {
    if (_showWarning) return; // Must accept warning first
    
    setState(() => _revealed = true);
    if (widget.secret.type == 'voice') {
      _initAudio();
    }
    _secretService.listenSecret(widget.secret.id);
    if (widget.onReveal != null) widget.onReveal!();
  }

  Color _getTierColor() {
    try {
      final hexCode = widget.secret.creatorTierColor.replaceAll('#', '0xFF');
      return Color(int.parse(hexCode));
    } catch (_) {
      return Colors.grey;
    }
  }

  /// Calculate bearing from user position to secret position (in radians)
  double _getBearing() {
    if (widget.userPosition == null) return 0;
    final lat1 = widget.userPosition!.latitude * math.pi / 180;
    final lat2 = widget.secret.lat * math.pi / 180;
    final dLng = (widget.secret.lng - widget.userPosition!.longitude) * math.pi / 180;

    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return math.atan2(y, x);
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
                          selectedReason == reason ? Icons.radio_button_checked : Icons.radio_button_unchecked,
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
                    widget.secret.id, 
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
              await _secretService.deleteSecret(widget.secret.id);
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
        return StatefulBuilder(builder: (ctx, setSheetState) {
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
                      stream: _secretService.getCommentsStream(widget.secret.id),
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
                                        ? const Icon(Icons.person, size: 14, color: Colors.white54)
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
                          icon: const Icon(Icons.send, color: HushColors.textAccent),
                          onPressed: () async {
                            final text = commentController.text.trim();
                            if (text.isEmpty) return;
                            await _secretService.addComment(widget.secret.id, text);
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
        });
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
        widget.secret.lat, 
        widget.secret.lng
      );
      isInRange = distance <= 15.0; // 15 meters reveal radius
    }
    
    bool isGroup = widget.secret.type == 'group';
    bool userSaved = hushUser?.savedSecretIds.contains(widget.secret.id) ?? false;
    bool isOwner = currentUser?.uid == widget.secret.creatorId;
    
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: isInRange && !_revealed ? _handleReveal : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2638).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
          boxShadow: [
            BoxShadow(
              color: _getTierColor().withValues(alpha: 0.1),
              blurRadius: 15,
              spreadRadius: 2,
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
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: _getTierColor(),
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: HushColors.bgPrimary,
                                    backgroundImage: widget.secret.creatorPhotoURL != null && widget.secret.creatorPhotoURL != 'generic'
                                        ? NetworkImage(widget.secret.creatorPhotoURL!)
                                        : null,
                                    child: widget.secret.creatorPhotoURL == 'generic' || widget.secret.creatorPhotoURL == null
                                        ? const Icon(Icons.person, size: 18, color: Colors.white54)
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
                                              widget.secret.creatorName ?? 'Anonymous',
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          // --- TIME AGO ---
                                          Text(
                                            getTimeAgo(widget.secret.createdAt, l10n),
                                            style: const TextStyle(color: HushColors.textMuted, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isGroup ? '🔐 Group Secret' : '🤫 Regular Secret',
                                        style: TextStyle(color: isGroup ? _getTierColor() : HushColors.textSecondary, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Distance + delete button for owner
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (distance != null)
                                Text(
                                  '${distance.toInt()}m away',
                                  style: const TextStyle(color: HushColors.textSecondary, fontSize: 12),
                                ),
                              if (isOwner) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _showDeleteConfirmation(context, l10n),
                                  child: const Icon(Icons.delete_outline, color: HushColors.tierRed, size: 20),
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
                                icon: _userLiked ? '❤️' : '🤍',
                                count: widget.secret.likes + (_userLiked ? 1 : 0),
                                isActive: _userLiked,
                                onTap: () {
                                  if (currentUser != null) {
                                    setState(() => _userLiked = true);
                                    _secretService.likeSecret(widget.secret.id);
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              _InteractionButton(
                                icon: '👎',
                                count: widget.secret.dislikes + (_userDisliked ? 1 : 0),
                                isActive: _userDisliked,
                                onTap: () {
                                  if (currentUser != null) {
                                    setState(() => _userDisliked = true);
                                    _secretService.dislikeSecret(widget.secret.id);
                                  }
                                },
                              ),
                              const SizedBox(width: 16),
                              Row(
                                children: [
                                  Text(
                                    widget.secret.textContent != null ? '👁️' : '👂', 
                                    style: const TextStyle(fontSize: 14)
                                  ),
                                  const SizedBox(width: 4),
                                  Text('${widget.secret.listens}', style: const TextStyle(color: HushColors.textSecondary)),
                                ],
                              ),
                              // --- COMMENTS BUTTON (only if revealed) ---
                              if (_revealed) ...[
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () => _showCommentsSheet(context, l10n),
                                  child: const Row(
                                    children: [
                                      Text('💬', style: TextStyle(fontSize: 14)),
                                      SizedBox(width: 4),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Row(
                            children: [
                              // --- REPORT BUTTON ---
                              GestureDetector(
                                onTap: () => _showReportDialog(context, l10n),
                                child: const Text('🚩', style: TextStyle(fontSize: 16)),
                              ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap: () {
                                  if (currentUser != null) {
                                    if (!userSaved && (hushUser?.savedSecretIds.length ?? 0) >= 50) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(l10n.saveLimitWarning)),
                                      );
                                      return;
                                    }
                                    _secretService.saveSecret(widget.secret.id);
                                  }
                                },
                                child: Row(
                                  children: [
                                    Text(userSaved ? '🔖' : '📌', style: const TextStyle(fontSize: 16)),
                                    const SizedBox(width: 4),
                                    Text(userSaved ? l10n.saved : l10n.save, style: TextStyle(color: userSaved ? HushColors.textAccent : HushColors.textSecondary, fontSize: 12)),
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
                            const Text('⚠️', style: TextStyle(fontSize: 32)),
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
      // --- SMOKY BLUR EFFECT for distant secrets (Task 4) ---
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.05),
                HushColors.textMuted.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.03),
              ],
            ),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: ShaderMask(
              shaderCallback: (bounds) => RadialGradient(
                center: Alignment.center,
                radius: 0.8,
                colors: [
                  Colors.white.withValues(alpha: 0.6),
                  Colors.white.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ).createShader(bounds),
              blendMode: BlendMode.dstIn,
              child: Column(
                children: [
                  if (widget.secret.textContent != null)
                    // Smoky text blur
                    Text(
                      'A hidden secret awaits nearby...',
                      style: TextStyle(
                        color: HushColors.textMuted.withValues(alpha: 0.4),
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    )
                  else
                    // Smoky voice blur
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.graphic_eq, color: HushColors.textMuted.withValues(alpha: 0.3), size: 24),
                        const SizedBox(width: 8),
                        ...List.generate(12, (i) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: 3,
                          height: 4.0 + math.Random(i).nextInt(20).toDouble(),
                          decoration: BoxDecoration(
                            color: HushColors.textMuted.withValues(alpha: 0.15 + math.Random(i).nextDouble() * 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )),
                      ],
                    ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      isInRange ? l10n.tapToReveal : l10n.outOfRange,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      // Revealed Content
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: widget.secret.textContent != null
          ? Text(widget.secret.textContent!, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4))
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
                      icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: HushColors.textAccent, size: 40),
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
            child: Icon(
              Icons.navigation,
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
            const Icon(Icons.touch_app, color: HushColors.textAccent, size: 32),
            const SizedBox(height: 8),
            Text(l10n.tapToReveal, style: const TextStyle(color: HushColors.textAccent, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _InteractionButton extends StatelessWidget {
  final String icon;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  const _InteractionButton({required this.icon, required this.count, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text('$count', style: TextStyle(color: isActive ? Colors.white : HushColors.textSecondary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
