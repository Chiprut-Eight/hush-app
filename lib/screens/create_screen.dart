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

/// Web-aligned Create Screen
class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> with SingleTickerProviderStateMixin {
  final AudioService _audioService = AudioService();
  final SecretService _secretService = SecretService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  int _activeTab = 0; // 0 = text, 1 = voice
  String _secretType = 'regular'; // 'regular' or 'group'
  double _requiredUsers = 3;

  TextEditingController _textController = TextEditingController();

  bool _isRecording = false;
  bool _isPublishing = false;
  String? _recordedFilePath;
  int _recordingDurationSeconds = 0;
  bool _isPlayingPreview = false;
  Timer? _recordTimer;

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
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
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
    setState(() {
      _recordedFilePath = null;
      _recordingDurationSeconds = 0;
    });
  }

  Future<void> _togglePreview() async {
    if (_isPlayingPreview) {
      await _audioPlayer.pause();
    } else {
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
    if (!_canSubmit()) return;

    setState(() => _isPublishing = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services disabled.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception('Permissions denied');
      }
      Position position = await Geolocator.getCurrentPosition();

      bool isGroup = _secretType == 'group';
      int? requiredU = isGroup ? _requiredUsers.toInt() : null;
      int? timeWindow;
      if (isGroup) {
        final currentTier = HushTiers.getTier(context.read<AuthProvider>().hushUser?.tierLevel ?? 1);
        timeWindow = currentTier.timeWindowMinutes;
      }

      if (_activeTab == 0) {
        // Text Secret
        await _secretService.createTextSecret(
          content: _textController.text.trim(),
          lat: position.latitude,
          lng: position.longitude,
          isGroup: isGroup,
          requiredUsers: requiredU,
          timeWindowMinutes: timeWindow,
        );
      } else {
        // Voice Secret
        final secretId = const Uuid().v4();
        final downloadUrl = await _audioService.uploadAudio(_recordedFilePath!, secretId);
        await _secretService.createVoiceSecret(
          audioURL: downloadUrl,
          audioDuration: _audioPlayer.duration?.inSeconds ?? _recordingDurationSeconds,
          lat: position.latitude,
          lng: position.longitude,
          isGroup: isGroup,
          requiredUsers: requiredU,
          timeWindowMinutes: timeWindow,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.secretReady)));
        _discardRecording();
        _textController.clear();
        setState(() => _secretType = 'regular');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.cancel}: $e')));
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final user = auth.hushUser;
    
    if (user?.isGhostMode == true) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.createTitle), centerTitle: true),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('👻', style: TextStyle(fontSize: 48)),
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                onValueChanged: (int? value) => setState(() => _activeTab = value!),
              ),
              
              const SizedBox(height: 32),

              // Content Area
              if (_activeTab == 0) _buildTextTab(l10n) else _buildVoiceTab(l10n),

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

              const SizedBox(height: 40),

              // Submit
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _canSubmit() ? _publishSecret : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HushColors.textAccent,
                    disabledBackgroundColor: HushColors.textAccent.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isPublishing 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(l10n.hideSecretAction, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),

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
                        child: Icon(
                          _isRecording ? Icons.stop_rounded : Icons.mic_none,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(_isPlayingPreview ? Icons.pause_circle_filled : Icons.play_circle_fill, color: HushColors.textAccent, size: 48),
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
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _discardRecording,
                    icon: const Icon(Icons.delete, color: HushColors.tierRed),
                    label: Text(l10n.delete, style: const TextStyle(color: HushColors.tierRed)),
                  )
                ],
              ),
      ),
    );
  }

  Widget _buildTypeOption(String value, String title, String desc) {
    bool selected = _secretType == value;
    return GestureDetector(
      onTap: () => setState(() => _secretType = value),
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
