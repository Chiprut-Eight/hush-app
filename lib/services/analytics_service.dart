import 'package:firebase_analytics/firebase_analytics.dart';

/// Centralized analytics service — singleton wrapper around FirebaseAnalytics.
/// Every tracked event in the app goes through this class.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService _instance = AnalyticsService._();
  factory AnalyticsService() => _instance;

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Expose the observer for MaterialApp's navigatorObservers
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ─── USER PROPERTIES ──────────────────────────────────────────

  Future<void> setUserProperties({
    required int tierLevel,
    String? gender,
  }) async {
    await _analytics.setUserProperty(name: 'tier_level', value: tierLevel.toString());
    if (gender != null) {
      await _analytics.setUserProperty(name: 'gender', value: gender);
    }
  }

  // ─── SCREEN VIEWS ─────────────────────────────────────────────

  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  // ─── AUTH ──────────────────────────────────────────────────────

  Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  Future<void> logSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  Future<void> logSignOut() async {
    await _analytics.logEvent(name: 'sign_out');
  }

  // ─── ONBOARDING ───────────────────────────────────────────────

  Future<void> logOnboardingCompleted({required String gender, required bool useGenericPhoto}) async {
    await _analytics.logEvent(
      name: 'onboarding_completed',
      parameters: {
        'gender': gender,
        'use_generic_photo': useGenericPhoto.toString(),
      },
    );
  }

  // ─── NAVIGATION ───────────────────────────────────────────────

  Future<void> logTabChanged(String tabName) async {
    await _analytics.logEvent(
      name: 'tab_changed',
      parameters: {'tab_name': tabName},
    );
  }

  // ─── SECRET CREATION ──────────────────────────────────────────

  Future<void> logSecretCreated({required String contentType, required String secretType}) async {
    await _analytics.logEvent(
      name: 'secret_created',
      parameters: {
        'content_type': contentType, // 'text' or 'voice'
        'secret_type': secretType,   // 'regular' or 'group'
      },
    );
  }

  Future<void> logCreateTabChanged(String tab) async {
    await _analytics.logEvent(
      name: 'create_tab_changed',
      parameters: {'tab': tab},
    );
  }

  Future<void> logSecretTypeChanged(String type) async {
    await _analytics.logEvent(
      name: 'secret_type_changed',
      parameters: {'type': type},
    );
  }

  // ─── RECORDING ────────────────────────────────────────────────

  Future<void> logRecordingStarted() async {
    await _analytics.logEvent(name: 'recording_started');
  }

  Future<void> logRecordingStopped({required int durationSeconds}) async {
    await _analytics.logEvent(
      name: 'recording_stopped',
      parameters: {'duration_seconds': durationSeconds},
    );
  }

  Future<void> logRecordingDiscarded() async {
    await _analytics.logEvent(name: 'recording_discarded');
  }

  Future<void> logAudioPreviewPlayed() async {
    await _analytics.logEvent(name: 'audio_preview_played');
  }

  // ─── SECRET INTERACTIONS ──────────────────────────────────────

  Future<void> logSecretRevealed({required String secretId, required String type, required bool isGroup}) async {
    await _analytics.logEvent(
      name: 'secret_revealed',
      parameters: {
        'secret_id': secretId,
        'type': type,
        'is_group': isGroup.toString(),
      },
    );
  }

  Future<void> logSecretLiked(String secretId) async {
    await _analytics.logEvent(name: 'secret_liked', parameters: {'secret_id': secretId});
  }

  Future<void> logSecretUnliked(String secretId) async {
    await _analytics.logEvent(name: 'secret_unliked', parameters: {'secret_id': secretId});
  }

  Future<void> logSecretDisliked(String secretId) async {
    await _analytics.logEvent(name: 'secret_disliked', parameters: {'secret_id': secretId});
  }

  Future<void> logSecretUndisliked(String secretId) async {
    await _analytics.logEvent(name: 'secret_undisliked', parameters: {'secret_id': secretId});
  }

  Future<void> logSecretSaved(String secretId) async {
    await _analytics.logEvent(name: 'secret_saved', parameters: {'secret_id': secretId});
  }

  Future<void> logSecretUnsaved(String secretId) async {
    await _analytics.logEvent(name: 'secret_unsaved', parameters: {'secret_id': secretId});
  }

  Future<void> logSecretDeleted(String secretId) async {
    await _analytics.logEvent(name: 'secret_deleted', parameters: {'secret_id': secretId});
  }

  Future<void> logSecretReported({required String secretId, required String reason}) async {
    await _analytics.logEvent(
      name: 'secret_reported',
      parameters: {
        'secret_id': secretId,
        'reason': reason,
      },
    );
  }

  Future<void> logAudioPlayback(String secretId) async {
    await _analytics.logEvent(name: 'audio_playback', parameters: {'secret_id': secretId});
  }

  Future<void> logCreatorProfileTapped(String creatorId) async {
    await _analytics.logEvent(name: 'creator_profile_tapped', parameters: {'creator_id': creatorId});
  }

  // ─── GROUP SECRETS ────────────────────────────────────────────

  Future<void> logGroupUnlockAttempt({required String secretId, required bool success}) async {
    await _analytics.logEvent(
      name: 'group_unlock_attempt',
      parameters: {
        'secret_id': secretId,
        'success': success.toString(),
      },
    );
  }

  // ─── CONTENT WARNING ──────────────────────────────────────────

  Future<void> logContentWarningDismissed(String secretId) async {
    await _analytics.logEvent(name: 'content_warning_dismissed', parameters: {'secret_id': secretId});
  }

  // ─── COMMENTS ─────────────────────────────────────────────────

  Future<void> logCommentAdded(String secretId) async {
    await _analytics.logEvent(name: 'comment_added', parameters: {'secret_id': secretId});
  }

  Future<void> logCommentEdited(String secretId) async {
    await _analytics.logEvent(name: 'comment_edited', parameters: {'secret_id': secretId});
  }

  Future<void> logCommentDeleted(String secretId) async {
    await _analytics.logEvent(name: 'comment_deleted', parameters: {'secret_id': secretId});
  }

  Future<void> logCommentReplied(String secretId) async {
    await _analytics.logEvent(name: 'comment_replied', parameters: {'secret_id': secretId});
  }

  Future<void> logCommentsOpened(String secretId) async {
    await _analytics.logEvent(name: 'comments_opened', parameters: {'secret_id': secretId});
  }

  // ─── SOCIAL ───────────────────────────────────────────────────

  Future<void> logFollow(String targetUserId) async {
    await _analytics.logEvent(name: 'follow_user', parameters: {'target_user_id': targetUserId});
  }

  Future<void> logUnfollow(String targetUserId) async {
    await _analytics.logEvent(name: 'unfollow_user', parameters: {'target_user_id': targetUserId});
  }

  Future<void> logUserSearch(String query) async {
    await _analytics.logEvent(
      name: 'user_search',
      parameters: {'query': query.length > 100 ? query.substring(0, 100) : query},
    );
  }

  Future<void> logFollowedUserTapped(String userId) async {
    await _analytics.logEvent(name: 'followed_user_tapped', parameters: {'user_id': userId});
  }

  // ─── MAP ──────────────────────────────────────────────────────

  Future<void> logMapMarkerTapped(String secretId) async {
    await _analytics.logEvent(name: 'map_marker_tapped', parameters: {'secret_id': secretId});
  }

  Future<void> logMapCenterOnUser() async {
    await _analytics.logEvent(name: 'map_center_on_user');
  }

  Future<void> logMapRefresh() async {
    await _analytics.logEvent(name: 'map_refresh');
  }

  // ─── FEED ─────────────────────────────────────────────────────

  Future<void> logFeedRefresh() async {
    await _analytics.logEvent(name: 'feed_refresh');
  }

  // ─── SHARE / INVITE ───────────────────────────────────────────

  Future<void> logShareApp(String source) async {
    await _analytics.logEvent(
      name: 'share_app',
      parameters: {'source': source}, // 'drawer', 'invite_popup'
    );
  }

  Future<void> logInvitePopupShown() async {
    await _analytics.logEvent(name: 'invite_popup_shown');
  }

  Future<void> logInvitePopupAccepted() async {
    await _analytics.logEvent(name: 'invite_popup_accepted');
  }

  Future<void> logInvitePopupDismissed() async {
    await _analytics.logEvent(name: 'invite_popup_dismissed');
  }

  // ─── DRAWER ───────────────────────────────────────────────────

  Future<void> logDrawerAction(String action) async {
    await _analytics.logEvent(
      name: 'drawer_action',
      parameters: {'action': action},
    );
  }

  // ─── LANGUAGE ─────────────────────────────────────────────────

  Future<void> logLanguageChanged(String language) async {
    await _analytics.logEvent(
      name: 'language_changed',
      parameters: {'language': language},
    );
  }

  // ─── NOTIFICATIONS ────────────────────────────────────────────

  Future<void> logNotificationsPanelOpened() async {
    await _analytics.logEvent(name: 'notifications_panel_opened');
  }

  Future<void> logNotificationTapped({String? secretId}) async {
    await _analytics.logEvent(
      name: 'notification_tapped',
      parameters: secretId != null ? {'secret_id': secretId} : null,
    );
  }

  // ─── TUTORIAL ─────────────────────────────────────────────────

  Future<void> logTutorialStarted({required String source}) async {
    await _analytics.logEvent(
      name: 'tutorial_started',
      parameters: {'source': source}, // 'auto', 'drawer'
    );
  }

  Future<void> logTutorialPageViewed(int pageIndex) async {
    await _analytics.logEvent(
      name: 'tutorial_page_viewed',
      parameters: {'page_index': pageIndex},
    );
  }

  Future<void> logTutorialCompleted() async {
    await _analytics.logEvent(name: 'tutorial_completed');
  }

  Future<void> logTutorialSkipped(int lastPageViewed) async {
    await _analytics.logEvent(
      name: 'tutorial_skipped',
      parameters: {'last_page_viewed': lastPageViewed},
    );
  }

  // ─── TIER ─────────────────────────────────────────────────────

  Future<void> logTierUp({required int oldTier, required int newTier}) async {
    await _analytics.logEvent(
      name: 'tier_up',
      parameters: {
        'old_tier': oldTier,
        'new_tier': newTier,
      },
    );
  }

  // ─── PROFILE ──────────────────────────────────────────────────

  Future<void> logProfileTabChanged(String tab) async {
    await _analytics.logEvent(
      name: 'profile_tab_changed',
      parameters: {'tab': tab},
    );
  }

  Future<void> logAppealSubmitted() async {
    await _analytics.logEvent(name: 'appeal_submitted');
  }

  // ─── ADMIN ────────────────────────────────────────────────────

  Future<void> logAdminAppealDecision({required String appealId, required bool approved}) async {
    await _analytics.logEvent(
      name: 'admin_appeal_decision',
      parameters: {
        'appeal_id': appealId,
        'decision': approved ? 'approved' : 'rejected',
      },
    );
  }

  Future<void> logAdminReportDecision({required String reportId, required String secretId, required bool deleted}) async {
    await _analytics.logEvent(
      name: 'admin_report_decision',
      parameters: {
        'report_id': reportId,
        'secret_id': secretId,
        'action': deleted ? 'delete_secret' : 'dismiss_report',
      },
    );
  }

  Future<void> logAdminMaintenanceAction(String action, {String? details}) async {
    final Map<String, Object> params = {'action': action};
    if (details != null) {
      params['details'] = details;
    }
    
    await _analytics.logEvent(
      name: 'admin_maintenance_action',
      parameters: params,
    );
  }
}
