import 'dart:async';
import 'package:flutter/material.dart';

/// Provider for global UI events and state
class UIProvider with ChangeNotifier {
  final _confettiTrigger = StreamController<void>.broadcast();

  /// Stream to listen for confetti trigger events
  Stream<void> get confettiStream => _confettiTrigger.stream;

  /// Trigger the confetti animation globally
  void triggerConfetti() {
    _confettiTrigger.add(null);
  }

  @override
  void dispose() {
    _confettiTrigger.close();
    super.dispose();
  }
}
