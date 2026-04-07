import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

/// Provider for global UI events and state
class UIProvider with ChangeNotifier {
  final _confettiTrigger = StreamController<void>.broadcast();
  final _audioPlayer = AudioPlayer();

  /// Stream to listen for confetti trigger events
  Stream<void> get confettiStream => _confettiTrigger.stream;

  /// Trigger the confetti animation globally with sound
  void triggerConfetti() async {
    _confettiTrigger.add(null);
    try {
      // Note: Assumes assets/sounds/confetti.mp3 exists. 
      // If not, it will fail silently but the animation will still run.
      await _audioPlayer.setAsset('assets/sounds/confetti.mp3');
      _audioPlayer.play();
    } catch (_) {
      // Fallback or silent fail if asset missing
    }
  }

  @override
  void dispose() {
    _confettiTrigger.close();
    _audioPlayer.dispose();
    super.dispose();
  }
}
