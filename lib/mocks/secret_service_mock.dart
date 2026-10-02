import 'dart:async';
import '../models/secret.dart';

class SecretService {
  Stream<Secret> getSecretStream(String secretId) => const Stream.empty();
  Stream<int> getUnlockAttemptsStream(String secretId, int windowMinutes) => Stream.value(0);
  
  Future<Map<String, dynamic>> revealSecret({required String secretId, double? lat, double? lng}) async => {'success': true, 'textContent': 'Hello'};
  Future<void> viewSecret(String secretId) async {}
  
  Future<Map<String, dynamic>> verifyGroupUnlock({required String secretId, required double lat, required double lng}) async => {'success': true};
  
  Future<void> reportSecretWithDetails(String secretId, String reason) async {}
  Future<void> reportCommentWithDetails(String secretId, String commentId, String reason) async {}
  
  Future<void> deleteSecret(String secretId) async {}
  Stream<List<Map<String, dynamic>>> getCommentsStream(String secretId) => Stream.value([]);
  Future<void> deleteComment(String secretId, String commentId) async {}
  Future<void> editComment(String secretId, String commentId, String text) async {}
  
  Future<void> addComment(String secretId, String text, {String? replyToUserId, String? replyToUserName, String? replyToCommentId}) async {}
  
  Future<void> likeSecret(String secretId) async {}
  Future<void> unlikeSecret(String secretId) async {}
  Future<void> dislikeSecret(String secretId) async {}
  Future<void> undislikeSecret(String secretId) async {}
  Future<void> toggleSaveSecret(String secretId) async {}
}
