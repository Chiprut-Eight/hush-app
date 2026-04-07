import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

/// Audio recording and upload service — matches web audioService.ts
class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool _isRecording = false;
  String? _currentPath;

  bool get isRecording => _isRecording;

  /// Start recording audio
  Future<void> startRecording() async {
    if (_isRecording) return;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw Exception('Microphone permission denied');
    }

    // Use a temporary file
    final tempDir = Directory.systemTemp;
    _currentPath = '${tempDir.path}/hush_recording_${const Uuid().v4()}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: _currentPath!,
    );

    _isRecording = true;
  }

  /// Stop recording and return the local file path
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    final path = await _recorder.stop();
    _isRecording = false;
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
    if (_isRecording) {
      await _recorder.stop();
    }
    _recorder.dispose();
  }
}
