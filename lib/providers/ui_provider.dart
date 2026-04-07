import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

/// Provider for global UI events and state
class UIProvider with ChangeNotifier {
  final _confettiTrigger = StreamController<void>.broadcast();
  final _audioPlayer = AudioPlayer();
  bool _isAudioReady = false;

  UIProvider() {
    _initAudioSession();
  }

  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      // Configure for playAndRecord to ensure it works even if microphone was used
      await session.configure(AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.defaultToSpeaker |
            AVAudioSessionCategoryOptions.allowBluetooth,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      ));
      
      debugPrint('[AUDIO] AudioSession (playAndRecord) configured successfully');

      // Use asset:/// with WAV for maximum compatibility
      await _audioPlayer.setAudioSource(
        AudioSource.uri(Uri.parse('asset:///assets/sounds/confetti_v2.wav')),
        preload: true,
      );
      _isAudioReady = true;
      debugPrint('[AUDIO] Confetti sound (WAV v2) preloaded successfully');
    } catch (e, stackTrace) {
      debugPrint('[AUDIO] Error initializing audio: $e');
      debugPrint('[AUDIO] TIP: If this is a "Source error", try replacing the .mp3 file with a .wav file.');
      debugPrint(stackTrace.toString());
    }
  }

  /// Stream to listen for confetti trigger events
  Stream<void> get confettiStream => _confettiTrigger.stream;

  /// Trigger the confetti animation globally with sound
  void triggerConfetti() async {
    _confettiTrigger.add(null);
    debugPrint('[AUDIO] Triggering confetti sound... (Ready: $_isAudioReady)');
    
    if (!_isAudioReady) {
      debugPrint('[AUDIO] Warning: Player not ready, attempting emergency load');
      await _initAudioSession();
    }

    try {
      // Ensure the player starts from the beginning
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play();
      
      debugPrint('[AUDIO] Confetti playback started');
    } catch (e, stackTrace) {
      debugPrint('[AUDIO] Error during confetti playback: $e');
      debugPrint(stackTrace.toString());
    }
  }

  @override
  void dispose() {
    _confettiTrigger.close();
    _audioPlayer.dispose();
    super.dispose();
  }
}
