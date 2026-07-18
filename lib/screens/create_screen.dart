import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hush_app/l10n/app_localizations.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import '../services/secret_service.dart';
import '../config/theme.dart';
import '../config/tiers.dart';
import '../providers/auth_provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import '../core/constants/icons.dart';
import '../widgets/hush_icon_widget.dart';
import '../widgets/hush_drawer.dart';
import '../widgets/notifications_button.dart';
import '../services/analytics_service.dart';

/// Web-aligned Create Screen
class CreateScreen extends StatefulWidget {
  final VoidCallback? onPublished;

  const CreateScreen({super.key, this.onPublished});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> with SingleTickerProviderStateMixin {
  final AudioService _audioService = AudioService();
  final SecretService _secretService = SecretService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  int _activeTab = 1; // 0 = text, 1 = voice
  String _secretType = 'regular'; // 'regular' or 'group'
  double _requiredUsers = 3;

  final TextEditingController _textController = TextEditingController();

  bool _isRecording = false;
  String? _recordedFilePath;
  int _recordingDurationSeconds = 0;
  bool _isPlayingPreview = false;
  Timer? _recordTimer;

  // GPS accuracy tracking
  StreamSubscription<Position>? _positionSubscription;
  double? _gpsAccuracy;
  Position? _lastPosition;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlayingPreview = state.playing && state.processingState != ProcessingState.completed;
        });
        if (state.processingState == ProcessingState.completed) {
          _audioPlayer.seek(Duration.zero);
          _audioPlayer.pause();
        }
      }
    });

    _textController.addListener(() => setState(() {}));

    // Start GPS accuracy stream
    _startGpsStream();
  }

  void _startGpsStream() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;

      // Get initial position
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) setState(() { _gpsAccuracy = pos.accuracy; _lastPosition = pos; });

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      ).listen((Position position) {
        if (mounted) {
          setState(() {
            _gpsAccuracy = position.accuracy;
            _lastPosition = position;
          });
        }
      });
    } catch (e) {
      debugPrint('GPS stream error: $e');
    }
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _positionSubscription?.cancel();
    _pulseController.dispose();
    _audioService.dispose();
    _audioPlayer.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    HapticFeedback.mediumImpact();
    
    if (_isRecording) {
      _recordTimer?.cancel();
      final path = await _audioService.stopRecording();
      _pulseController.stop();
      _pulseController.reset();
      
      setState(() {
        _isRecording = false;
        _recordedFilePath = path;
      });

      AnalyticsService().logRecordingStopped(durationSeconds: _recordingDurationSeconds);

      if (path != null) {
        await _audioPlayer.setFilePath(path);
      }
    } else {
      try {
        await _audioService.startRecording();
        _pulseController.repeat(reverse: true);
        setState(() {
          _isRecording = true;
          _recordedFilePath = null;
          _recordingDurationSeconds = 0;
        });

        AnalyticsService().logRecordingStarted();
        
        // Auto-stop at 60 seconds
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() => _recordingDurationSeconds++);
          if (_recordingDurationSeconds >= 60) {
            _toggleRecording();
          }
        });
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Recording failed: $e')));
      }
    }
  }

  void _discardRecording() {
    AnalyticsService().logRecordingDiscarded();
    setState(() {
      _recordedFilePath = null;
      _recordingDurationSeconds = 0;
    });
  }

  Future<void> _togglePreview() async {
    if (_isPlayingPreview) {
      await _audioPlayer.pause();
    } else {
      AnalyticsService().logAudioPreviewPlayed();
      await _audioPlayer.play();
    }
  }

  bool _canSubmit() {
    if (_activeTab == 0) return _textController.text.trim().isNotEmpty && _textController.text.length <= 140;
    if (_activeTab == 1) return _recordedFilePath != null;
    return false;
  }

  Future<void> _publishSecret() async {
    if (!_canSubmit()) return;

    final tierLevel = context.read<AuthProvider>().hushUser?.tierLevel ?? 1;

    // Capture all needed data BEFORE navigating away
    final contentType = _activeTab == 0 ? 'text' : 'voice';
    final secretType = _secretType;
    final textContent = _textController.text.trim();
    final recordedPath = _recordedFilePath;
    final audioDuration = _audioPlayer.duration?.inSeconds ?? _recordingDurationSeconds;
    final isGroup = _secretType == 'group';
    final requiredU = isGroup ? _requiredUsers.toInt() : null;
    int? timeWindow;
    if (isGroup) {
      final currentTier = HushTiers.getTier(tierLevel);
      timeWindow = currentTier.timeWindowMinutes;
    }

    // Use the last known GPS position or get a fresh one
    Position? position = _lastPosition;
    if (position == null) {
      try {
        position = await Geolocator.getCurrentPosition();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.cancel}: $e')));
        return;
      }
    }

    // Immediately navigate to feed and show snackbar
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    _discardRecording();
    _textController.clear();
    setState(() => _secretType = 'regular');
    if (widget.onPublished != null) widget.onPublished!();

    // Show "on the way" snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.secretOnTheWay),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // Publish in background (fire-and-forget)
    _publishInBackground(
      contentType: contentType,
      secretType: secretType,
      textContent: textContent,
      recordedPath: recordedPath,
      audioDuration: audioDuration,
      lat: position.latitude,
      lng: position.longitude,
      isGroup: isGroup,
      requiredUsers: requiredU,
      timeWindowMinutes: timeWindow,
    );
  }

  Future<void> _publishInBackground({
    required String contentType,
    required String secretType,
    required String textContent,
    required String? recordedPath,
    required int audioDuration,
    required double lat,
    required double lng,
    required bool isGroup,
    required int? requiredUsers,
    required int? timeWindowMinutes,
  }) async {
    try {
      if (contentType == 'text') {
        await _secretService.createTextSecret(
          content: textContent,
          lat: lat,
          lng: lng,
          isGroup: isGroup,
          requiredUsers: requiredUsers,
          timeWindowMinutes: timeWindowMinutes,
        );
      } else {
        final secretId = const Uuid().v4();
        final downloadUrl = await _audioService.uploadAudio(recordedPath!, secretId);
        await _secretService.createVoiceSecret(
          audioURL: downloadUrl,
          audioDuration: audioDuration,
          lat: lat,
          lng: lng,
          isGroup: isGroup,
          requiredUsers: requiredUsers,
          timeWindowMinutes: timeWindowMinutes,
        );
      }
      AnalyticsService().logSecretCreated(contentType: contentType, secretType: secretType);
      debugPrint('Secret published successfully in background');
    } catch (e) {
      debugPrint('Background publish failed: $e');
      // Show error snackbar if we're still mounted (user might have navigated away)
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final user = auth.hushUser;
    
    if (user?.isGhostMode == true) {
      return Scaffold(
        drawer: const HushDrawer(),
        appBar: AppBar(
          title: Text(l10n.createTitle), 
          centerTitle: true,
          actions: const [NotificationsButton()],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const HushIcon(HushIcons.ghost, size: 48, color: HushColors.tierRed),
              const SizedBox(height: 16),
              Text(l10n.ghostModeActive, style: const TextStyle(fontSize: 22, color: HushColors.tierRed, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(l10n.cannotPlantGhost, style: const TextStyle(color: HushColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: HushColors.bgPrimary,
      appBar: AppBar(
        title: Text(l10n.createTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: const [NotificationsButton()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Content Area (text or voice)
              if (_activeTab == 0) _buildTextTab(l10n) else _buildVoiceTab(l10n),

              const SizedBox(height: 16),

              // GPS Accuracy Indicator
              _buildGpsAccuracyIndicator(l10n),

              const SizedBox(height: 12),

              // Submit button
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _canSubmit() ? _publishSecret : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HushColors.textAccent,
                    disabledBackgroundColor: HushColors.textAccent.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.place, color: Colors.white, size: 22),
                  label: Text(l10n.hideSecretAction, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 24),

              // Tabs
              CupertinoSlidingSegmentedControl<int>(
                backgroundColor: HushColors.bgCard,
                thumbColor: const Color(0xFF1E2638),
                groupValue: _activeTab,
                padding: const EdgeInsets.all(4),
                children: {
                  0: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(l10n.textTab)),
                  1: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(l10n.voiceTab)),
                },
                onValueChanged: (int? value) {
                  setState(() => _activeTab = value!);
                  AnalyticsService().logCreateTabChanged(value == 0 ? 'text' : 'voice');
                },
              ),
              
              const SizedBox(height: 32),

              // Secret Type
              Text(l10n.secretType, style: const TextStyle(color: HushColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),

              _buildTypeOption('regular', l10n.regularSecret, l10n.regularSecretDesc),
              const SizedBox(height: 12),
              _buildTypeOption('group', l10n.groupSecret, l10n.groupSecretDesc),

              if (_secretType == 'group') ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: HushColors.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: HushColors.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.peopleRequired, style: const TextStyle(color: HushColors.textPrimary)),
                          Text('${_requiredUsers.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: HushColors.textAccent)),
                        ],
                      ),
                      Builder(
                        builder: (ctx) {
                          final currentTier = HushTiers.getTier(user?.tierLevel ?? 1);
                          final double maxUsers = currentTier.maxGroupUsers.toDouble();
                          
                          // Ensure requiredUsers is within valid range
                          if (_requiredUsers > maxUsers) _requiredUsers = maxUsers;
                          if (_requiredUsers < 3) _requiredUsers = 3;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Slider(
                                value: _requiredUsers,
                                min: 3,
                                max: maxUsers < 3 ? 3 : maxUsers,
                                divisions: maxUsers > 3 ? (maxUsers - 3).toInt() : 1,
                                activeColor: HushColors.textAccent,
                                inactiveColor: HushColors.textSecondary,
                                onChanged: maxUsers > 3 ? (val) => setState(() => _requiredUsers = val) : null,
                              ),
                              Text(
                                l10n.timeWindow(currentTier.timeWindowMinutes),
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: HushColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          );
                        }
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 48), // Bottom nav padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextTab(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _textController,
          maxLength: 140,
          maxLines: 4,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: InputDecoration(
            hintText: l10n.secretPlaceholder,
            hintStyle: const TextStyle(color: HushColors.textMuted),
            filled: true,
            fillColor: HushColors.bgCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            counterText: '',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.maxChars(_textController.text.length),
          textAlign: TextAlign.right,
          style: TextStyle(
            color: _textController.text.length >= 130 ? HushColors.tierRed : HushColors.textMuted,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceTab(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: HushColors.bgCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: _recordedFilePath == null
            ? AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isRecording ? _pulseAnimation.value : 1.0,
                    child: GestureDetector(
                      onTap: _toggleRecording,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: HushColors.tierRed, width: 2),
                          color: _isRecording ? HushColors.tierRed.withValues(alpha: 0.2) : Colors.transparent,
                        ),
                        child: HushIcon(
                          _isRecording ? HushIcons.stop : HushIcons.mic,
                          color: HushColors.tierRed,
                          size: 40,
                        ),
                      ),
                    ),
                  );
                },
              )
            : Column(
                children: [
                  // Task 5: Force LTR for audio playback preview
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: HushIcon(_isPlayingPreview ? HushIcons.pause : HushIcons.play, size: 48, color: HushColors.textAccent),
                          onPressed: _togglePreview,
                        ),
                        const SizedBox(width: 16),
                        // Fake waveform
                        ...List.generate(6, (i) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: 4,
                          height: 12.0 + (i % 3) * 8,
                          color: HushColors.textAccent,
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _discardRecording,
                    icon: const HushIcon(HushIcons.trash, size: 20, color: HushColors.tierRed),
                    label: Text(l10n.delete, style: const TextStyle(color: HushColors.tierRed)),
                  )
                ],
              ),
      ),
    );
  }

  Widget _buildGpsAccuracyIndicator(AppLocalizations l10n) {
    if (_gpsAccuracy == null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: HushColors.textMuted)),
          const SizedBox(width: 8),
          Text(l10n.gpsSearching, style: const TextStyle(color: HushColors.textMuted, fontSize: 13)),
        ],
      );
    }

    final accuracy = _gpsAccuracy!;
    Color indicatorColor;
    String label;

    if (accuracy <= 10) {
      indicatorColor = const Color(0xFF34D399); // green
      label = l10n.gpsHigh(accuracy.toInt());
    } else if (accuracy <= 30) {
      indicatorColor = const Color(0xFFFBBF24); // yellow
      label = l10n.gpsMedium(accuracy.toInt());
    } else {
      indicatorColor = const Color(0xFFEF4444); // red
      label = l10n.gpsLow(accuracy.toInt());
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: indicatorColor,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: indicatorColor.withValues(alpha: 0.5), blurRadius: 6, spreadRadius: 1)],
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: indicatorColor, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildTypeOption(String value, String title, String desc) {
    bool selected = _secretType == value;
    return GestureDetector(
      onTap: () {
        setState(() => _secretType = value);
        AnalyticsService().logSecretTypeChanged(value);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? HushColors.bgCard : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? HushColors.textAccent : HushColors.borderSubtle, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? HushColors.textAccent : HushColors.textSecondary, width: 2),
              ),
              child: selected ? Center(child: Container(width: 12, height: 12, decoration: const BoxDecoration(color: HushColors.textAccent, shape: BoxShape.circle))) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: HushColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(color: HushColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
