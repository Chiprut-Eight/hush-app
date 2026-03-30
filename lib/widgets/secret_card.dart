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
import 'package:hush_app/l10n/app_localizations.dart';

class SecretCard extends StatefulWidget {
  final Secret secret;
  final Position? userPosition;
  final VoidCallback? onReveal;

  const SecretCard({
    super.key, 
    required this.secret,
    this.userPosition,
    this.onReveal,
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
                                      Text(
                                        widget.secret.creatorName ?? 'Anonymous',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
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
                          if (distance != null)
                            Text(
                              '${distance.toInt()}m away',
                              style: const TextStyle(color: HushColors.textSecondary, fontSize: 12),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // --- CONTENT BLUR/REVEAL ---
                      if (_revealed || !isInRange)
                        _buildContent(isInRange, l10n)
                      else if (isInRange && !_revealed)
                        _buildTapToReveal(l10n),

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
                            ],
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {}, // report
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
                            const Text('Content Warning', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            const Text('This secret has been heavily downvoted.', style: TextStyle(color: HushColors.textSecondary, fontSize: 12)),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: () {}, // cancel
                                  child: const Text('Cancel', style: TextStyle(color: HushColors.textSecondary)),
                                ),
                                ElevatedButton(
                                  onPressed: () => setState(() => _showWarning = false),
                                  style: ElevatedButton.styleFrom(backgroundColor: HushColors.tierRed),
                                  child: const Text('View Anyway', style: TextStyle(color: Colors.white)),
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
      // Blurred Fake Text / Waveform (Web parity)
      return ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                if (widget.secret.textContent != null)
                  const Text(
                    '██ ████ ███ ██████ ██ ███ ████ ██', 
                    style: TextStyle(color: HushColors.textMuted, fontSize: 18)
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🎙️', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      ...List.generate(16, (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        width: 3,
                        height: 6.0 + math.Random().nextInt(18),
                        decoration: BoxDecoration(
                          color: HushColors.textMuted.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(2)
                        ),
                      )),
                    ],
                  ),
                const SizedBox(height: 12),
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
      );
    } else {
      // Revealed Content
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: widget.secret.textContent != null
          ? Text(widget.secret.textContent!, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4))
          : Container(
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
      );
    }
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
