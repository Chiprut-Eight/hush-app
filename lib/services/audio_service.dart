import 'dart:io';
import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import 'package:audio_session/audio_session.dart';

/// Audio recording and upload service — matches web audioService.ts
class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  FirebaseStorage get _storage => FirebaseStorage.instance;
  bool _isRecording = false;
  String? _currentPath;
  
  List<double> recordedAmplitudes = [];
  StreamSubscription<Amplitude>? _amplitudeSub;
  StreamSubscription<AudioInterruptionEvent>? _interruptionSub;
  Function(String)? onRecordingInterrupted;

  bool get isRecording => _isRecording;

  /// Start recording audio
  Future<void> startRecording() async {
    if (_isRecording) return;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw Exception('Microphone permission denied');
    }

    // Try to acquire audio focus (will fail if in a call)
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.defaultToSpeaker | AVAudioSessionCategoryOptions.allowBluetooth,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientExclusive,
      androidWillPauseWhenDucked: true,
    ));

    // Force deactivate before trying to acquire to reset the internal state and ensure a clean focus request
    await session.setActive(false);
    
    final success = await session.setActive(true);
    if (!success) {
      throw Exception('Could not acquire audio focus. Are you in a call?');
    }

    // Use a temporary file
    final tempDir = Directory.systemTemp;
    _currentPath = '${tempDir.path}/hush_recording_${const Uuid().v4()}.m4a';

    recordedAmplitudes.clear();
    await _amplitudeSub?.cancel();
    
    await _interruptionSub?.cancel();
    _interruptionSub = session.interruptionEventStream.listen((event) {
      // Disabled because of false positives (triggers when no call is present)
      // if (event.begin && _isRecording) {
      //   onRecordingInterrupted?.call('ההקלטה הופסקה עקב שיחה נכנסת');
      // }
    });

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: _currentPath!,
    );

    _isRecording = true;
    _amplitudeSub = _recorder.onAmplitudeChanged(const Duration(milliseconds: 100)).listen((amp) {
      // Normalize from dB (-50 to 0 typically) to a 0.0 - 1.0 scale
      double normalized = (amp.current + 50) / 50;
      if (normalized < 0.05) normalized = 0.05; // Minimum bar height
      if (normalized > 1.0) normalized = 1.0;
      recordedAmplitudes.add(normalized);
    });
  }

  /// Stop recording and return the local file path
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    await _amplitudeSub?.cancel();
    await _interruptionSub?.cancel();
    final path = await _recorder.stop();
    _isRecording = false;
    
    // Deactivate session to release focus completely
    final session = await AudioSession.instance;
    await session.setActive(false);
    
    return path;
  }

  /// Upload a recorded audio file to Firebase Storage
  /// Returns the download URL
  Future<String> uploadAudio(String localPath, String secretId) async {
    final file = File(localPath);
    final ref = _storage.ref().child('audio/$secretId.m4a');

    await ref.putFile(file, SettableMetadata(contentType: 'audio/mp4'));
    final downloadUrl = await ref.getDownloadURL();

    // Clean up local file
    try {
      await file.delete();
    } catch (_) {}

    return downloadUrl;
  }

  /// Get cached audio file from URL
  /// Returns a File object once downloaded or retrieved from cache
  Future<File> getCachedAudioFile(String url) async {
    return await DefaultCacheManager().getSingleFile(url);
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _interruptionSub?.cancel();
    if (_isRecording) {
      await stopRecording();
    }
    _recorder.dispose();
  }
}
