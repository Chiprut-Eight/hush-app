import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hush_app/l10n/app_localizations.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/audio_service.dart';
import '../services/secret_service.dart';
import '../services/geo_service.dart';
import '../config/theme.dart';
import '../config/tiers.dart';
import '../providers/auth_provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import '../core/constants/icons.dart';
import '../widgets/hush_icon_widget.dart';
import '../services/analytics_service.dart';

/// Web-aligned Create Screen
class CreateScreen extends StatefulWidget {
  final VoidCallback? onPublishStart;
  final VoidCallback? onPublishComplete;
  final double? targetLat;
  final double? targetLng;
  final bool isActive;

  const CreateScreen({super.key, this.onPublishStart, this.onPublishComplete, this.targetLat, this.targetLng, this.isActive = true});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> with SingleTickerProviderStateMixin {
  final AudioService _audioService = AudioService();
  final SecretService _secretService = SecretService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  TutorialCoachMark? tutorialCoachMark;
  final GlobalKey _typeSelectionKey = GlobalKey();
  final GlobalKey _inputMethodKey = GlobalKey();
  final GlobalKey _textFieldKey = GlobalKey();
  bool _isTutorialActive = false;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  int _activeTab = 0; // 0 = text, 1 = voice
  String _secretType = 'regular'; // 'regular' or 'group'
  double _requiredUsers = 3;

  final TextEditingController _textController = TextEditingController();

  bool _isRecording = false;
  bool _isPublishing = false;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.hushUser?.defaultCreateMode == 'voice') {
        setState(() {
          _activeTab = 1;
        });
      }
      
      _checkAndShowTutorial();
    });
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

    _audioService.onRecordingInterrupted = (message) {
      if (mounted && _isRecording) {
        _toggleRecording();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: HushColors.bgCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.info_outline, color: HushColors.tierRed),
                const SizedBox(width: 8),
                Text(Localizations.localeOf(context).languageCode == 'he' ? 'הקלטה הופסקה' : 'Recording Stopped', style: const TextStyle(color: Colors.white)),
              ],
            ),
            content: Text(
              Localizations.localeOf(context).languageCode == 'he' ? message : 'Recording stopped due to an incoming call',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(Localizations.localeOf(context).languageCode == 'he' ? 'הבנתי' : 'Got it', style: const TextStyle(color: HushColors.textAccent)),
              ),
            ],
          ),
        );
      }
    };

    // Start GPS accuracy stream
    _startGpsStream();
  }

  void _startGpsStream() async {
    if (widget.targetLat != null && widget.targetLng != null) {
      if (mounted) {
        setState(() {
          _gpsAccuracy = 1.0;
          _lastPosition = Position(
            latitude: widget.targetLat!,
            longitude: widget.targetLng!,
            timestamp: DateTime.now(),
            accuracy: 1.0,
            altitude: 0.0,
            heading: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
            altitudeAccuracy: 0.0,
            headingAccuracy: 0.0,
          );
        });
      }
      return;
    }

    try {
      // Use GeoService to safely handle permissions and initial position
      final pos = await GeoService.getCurrentPositionSafe();
      if (mounted) {
        setState(() {
          _gpsAccuracy = pos.accuracy;
          _lastPosition = pos;
        });
      }

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
      debugPrint('GPS stream error in CreateScreen: $e');
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

  @override
  void didUpdateWidget(CreateScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _checkAndShowTutorial();
    }
  }

  void _checkAndShowTutorial() {
    if (!widget.isActive) return;
    
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.hushUser;
    
    if (user != null && !user.hasSeenCreateTutorialV1) {
      // Add a post-frame callback to ensure UI is fully built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTutorial();
      });
    }
  }

  void _showTutorial() {
    if (!mounted) return;
    
    // Switch to text tab if not already to ensure text field is visible
    if (_activeTab != 0) {
      setState(() => _activeTab = 0);
    }
    
    setState(() => _isTutorialActive = true);
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      
      final l10n = AppLocalizations.of(context)!;
      final isHe = l10n.localeName == 'he';
      final continueText = isHe ? 'המשך' : 'Continue';
      final gotItText = isHe ? 'הבנתי' : 'Got it';
      
      final targets = <TargetFocus>[];
      
      if (_typeSelectionKey.currentContext != null) {
        targets.add(
          TargetFocus(
            identify: "Target Type",
            keyTarget: _typeSelectionKey,
            shape: ShapeLightFocus.RRect,
            radius: 12,
            contents: [
              TargetContent(
                align: ContentAlign.top,
                builder: (context, controller) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ביחרו סוג Hushhh',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => tutorialCoachMark?.next(),
                          style: ElevatedButton.styleFrom(backgroundColor: HushColors.gradientBlue, foregroundColor: Colors.white),
                          child: Text(continueText),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => tutorialCoachMark?.skip(),
                          style: TextButton.styleFrom(foregroundColor: Colors.white54),
                          child: Text(gotItText),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          )
        );
      }
      
      if (_inputMethodKey.currentContext != null) {
        targets.add(
          TargetFocus(
            identify: "Target Method",
            keyTarget: _inputMethodKey,
            shape: ShapeLightFocus.RRect,
            radius: 12,
            contents: [
              TargetContent(
                align: ContentAlign.top,
                builder: (context, controller) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ביחרו אם לכתוב או להקליט Hushhh',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => tutorialCoachMark?.next(),
                          style: ElevatedButton.styleFrom(backgroundColor: HushColors.gradientBlue, foregroundColor: Colors.white),
                          child: Text(continueText),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => tutorialCoachMark?.skip(),
                          style: TextButton.styleFrom(foregroundColor: Colors.white54),
                          child: Text(gotItText),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          )
        );
      }
      
      if (_textFieldKey.currentContext != null) {
        targets.add(
          TargetFocus(
            identify: "Target Text",
            keyTarget: _textFieldKey,
            shape: ShapeLightFocus.RRect,
            radius: 12,
            contents: [
              TargetContent(
                align: ContentAlign.bottom,
                builder: (context, controller) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'השאירו Hushhh סביבכם, שימו לב לרמת הדיוק',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => tutorialCoachMark?.skip(),
                      style: ElevatedButton.styleFrom(backgroundColor: HushColors.gradientBlue, foregroundColor: Colors.white),
                      child: Text(gotItText),
                    ),
                  ],
                ),
              ),
            ],
          )
        );
      }
      
      if (targets.isEmpty) return;

      tutorialCoachMark = TutorialCoachMark(
        targets: targets,
        colorShadow: HushColors.bgPrimary,
        hideSkip: true,
        paddingFocus: 10,
        opacityShadow: 0.9,
        onFinish: () async {
          if (mounted) setState(() => _isTutorialActive = false);
          final auth = context.read<AuthProvider>();
          if (auth.firebaseUser != null) {
            await FirebaseFirestore.instance.collection('users').doc(auth.firebaseUser!.uid).update({'hasSeenCreateTutorialV1': true});
          }
        },
        onSkip: () {
          if (mounted) setState(() => _isTutorialActive = false);
          final auth = context.read<AuthProvider>();
          if (auth.firebaseUser != null) {
            FirebaseFirestore.instance.collection('users').doc(auth.firebaseUser!.uid).update({'hasSeenCreateTutorialV1': true});
          }
          return true;
        },
      )..show(context: context);
    });
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
        if (!mounted) return;
        final isHe = Localizations.localeOf(context).languageCode == 'he';
        final message = isHe
            ? 'לא ניתן להקליט בזמן שיחה.'
            : 'Cannot record during a phone call.';
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: HushColors.bgCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.mic_off, color: HushColors.tierRed),
                const SizedBox(width: 8),
                Text(isHe ? 'שגיאת הקלטה' : 'Recording Error', style: const TextStyle(color: Colors.white)),
              ],
            ),
            content: Text(message, style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(isHe ? 'הבנתי' : 'Got it', style: const TextStyle(color: HushColors.textAccent)),
              ),
            ],
          ),
        );
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
    if (_isPublishing) return false;
    if (_activeTab == 0) return _textController.text.trim().isNotEmpty && _textController.text.length <= 140;
    if (_activeTab == 1) return _recordedFilePath != null;
    return false;
  }

  Future<void> _publishSecret() async {
    if (!_canSubmit() || _isPublishing) return;
    HapticFeedback.heavyImpact();

    setState(() => _isPublishing = true);

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
        if (mounted) {
          setState(() => _isPublishing = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.cancel}: $e')));
        }
        return;
      }
    }

    if (widget.onPublishStart != null) widget.onPublishStart!();

    // Publish in the background so the user can transition immediately
    try {
      _publishInBackground(
        contentType: contentType,
        secretType: secretType,
        textContent: textContent,
        recordedPath: recordedPath,
        audioDuration: audioDuration,
        amplitudes: _audioService.recordedAmplitudes,
        lat: position.latitude,
        lng: position.longitude,
        isGroup: isGroup,
        requiredUsers: requiredU,
        timeWindowMinutes: timeWindow,
      ).then((_) {
        // When publish finishes in background, notify to refresh feed
        if (mounted && widget.onPublishComplete != null) widget.onPublishComplete!();
      });
    } catch (e) {
      debugPrint("Publish start error: $e");
    }

    if (!mounted) return;

    setState(() {
      _isPublishing = false;
      _secretType = 'regular';
    });

    FocusScope.of(context).unfocus();
    _discardRecording();
    _textController.clear();

    // Show "on the way" snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.secretOnTheWay),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _publishInBackground({
    required String contentType,
    required String secretType,
    required String textContent,
    required String? recordedPath,
    required int audioDuration,
    required List<double>? amplitudes,
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
          amplitudes: amplitudes,
          lat: lat,
          lng: lng,
          isGroup: isGroup,
          requiredUsers: requiredUsers,
          timeWindowMinutes: timeWindowMinutes,
        );
      }
      AnalyticsService().logSecretCreated(
        contentType: contentType, 
        secretType: secretType,
        requiredUsers: isGroup ? requiredUsers : null,
      );
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
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Content Area (text or voice)
                if (_activeTab == 0) ...[
                  // For text tab: Submit button appears ABOVE the text field so it's not hidden by keyboard
                  _buildSubmitButton(l10n, margin: const EdgeInsets.only(bottom: 12)),
                  Container(
                    key: _textFieldKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTextTab(l10n),
                        const SizedBox(height: 12),
                        _buildGpsAccuracyIndicator(l10n, forceHighAccuracy: _isTutorialActive),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    key: _textFieldKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildVoiceTab(l10n),
                        const SizedBox(height: 16),
                        _buildGpsAccuracyIndicator(l10n, forceHighAccuracy: _isTutorialActive),
                      ],
                    ),
                  ),
                  _buildSubmitButton(l10n, margin: const EdgeInsets.only(top: 12)),
                ],

                const SizedBox(height: 24),

                // Tabs
                Container(
                  key: _inputMethodKey,
                  child: CupertinoSlidingSegmentedControl<int>(
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
                ),
                
                const SizedBox(height: 32),

                // Secret Type
                Container(
                  key: _typeSelectionKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l10n.secretType, style: const TextStyle(color: HushColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      _buildTypeOption('regular', l10n.regularSecret, l10n.regularSecretDesc),
                      const SizedBox(height: 12),
                      _buildTypeOption('group', l10n.groupSecret, l10n.groupSecretDesc),
                    ],
                  ),
                ),

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
      ),
    );
  }

  Widget _buildTextTab(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
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
            if (_textController.text.isNotEmpty)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () {
                    _textController.clear();
                    FocusScope.of(context).unfocus();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: HushColors.textMuted.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 16, color: HushColors.textSecondary),
                  ),
                ),
              ),
          ],
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
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isRecording ? _pulseAnimation.value : 1.0,
                        child: GestureDetector(
                          onTap: _toggleRecording,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: HushColors.tierRed, width: 2),
                              color: _isRecording ? HushColors.tierRed.withValues(alpha: 0.2) : Colors.transparent,
                            ),
                            child: HushIcon(
                              _isRecording ? HushIcons.stop : HushIcons.mic,
                              color: HushColors.tierRed,
                              size: 32,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.voicePlaceholder,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: HushColors.textMuted, fontSize: 14),
                  ),
                ],
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

  Widget _buildGpsAccuracyIndicator(AppLocalizations l10n, {bool forceHighAccuracy = false}) {
    if (_gpsAccuracy == null && !forceHighAccuracy) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: HushColors.textMuted)),
          const SizedBox(width: 8),
          Text(l10n.gpsSearching, style: const TextStyle(color: HushColors.textMuted, fontSize: 13)),
        ],
      );
    }

    final accuracy = forceHighAccuracy ? 5.0 : _gpsAccuracy!;
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

  Widget _buildSubmitButton(AppLocalizations l10n, {EdgeInsetsGeometry? margin}) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: (_canSubmit() || _isPublishing) ? 1.0 : 0.0,
        child: (_canSubmit() || _isPublishing)
            ? Padding(
                padding: margin ?? EdgeInsets.zero,
                child: Container(
                  height: 60, // Let's make it 60 to comfortably fit a 50px icon with padding
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: HushColors.brandGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: HushColors.tierRed.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _publishSecret,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isPublishing)
                          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        else
                          Image.asset(
                            'assets/images/icon_tap_to_drop.png',
                            width: 50,
                            height: 50,
                            fit: BoxFit.contain,
                          ),
                        const SizedBox(width: 8),
                        Text(
                          _isPublishing ? '...' : l10n.hideSecretAction,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
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
