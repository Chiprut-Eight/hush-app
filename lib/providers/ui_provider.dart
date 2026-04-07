import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

/// Provider for global UI events and state
class UIProvider with ChangeNotifier {
  final _confettiTrigger = StreamController<void>.broadcast();
  final _audioPlayer = AudioPlayer();

  UIProvider() {
    _initAudioSession();
  }

  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      debugPrint('[AUDIO] AudioSession configured successfully');
    } catch (e) {
      debugPrint('[AUDIO] Error configuring AudioSession: $e');
    }
  }

  /// Stream to listen for confetti trigger events
  Stream<void> get confettiStream => _confettiTrigger.stream;

  /// Trigger the confetti animation globally with sound
  void triggerConfetti() async {
    _confettiTrigger.add(null);
    debugPrint('[AUDIO] Triggering confetti sound...');
    
    try {
      // Ensure the player is fresh and at full volume
      if (_audioPlayer.playing) {
        await _audioPlayer.stop();
      }
      
      // Use explicit asset source
      await _audioPlayer.setAudioSource(
        AudioSource.asset('assets/sounds/confetti.mp3')
      );
      
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play();
      
      debugPrint('[AUDIO] Confetti sound played successfully');
    } catch (e, stackTrace) {
      debugPrint('[AUDIO] Error playing confetti sound: $e');
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
