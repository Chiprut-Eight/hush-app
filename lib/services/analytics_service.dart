
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService _instance = AnalyticsService._();
  factory AnalyticsService() => _instance;

  dynamic get observer => null; // Use dynamic to avoid import issues if not used strictly

  Future<void> setUserProperties({required int tierLevel, String? gender}) async {}
  Future<void> logScreenView(String screenName) async {}
  Future<void> logLogin(String method) async {}
  Future<void> logSignUp(String method) async {}
  Future<void> logSignOut() async {}
  Future<void> logOnboardingCompleted({required String gender, required bool useGenericPhoto}) async {}
  Future<void> logTabChanged(String tabName) async {}
  Future<void> logSecretCreated({required String contentType, required String secretType, int? requiredUsers}) async {}
  Future<void> logCreateTabChanged(String tab) async {}
  Future<void> logSecretTypeChanged(String type) async {}
  Future<void> logRecordingStarted() async {}
  Future<void> logRecordingStopped({required int durationSeconds}) async {}
  Future<void> logRecordingDiscarded() async {}
  Future<void> logAudioPreviewPlayed() async {}
  Future<void> logSecretRevealed({required String secretId, required String type, required bool isGroup}) async {}
  Future<void> logSecretLiked(String secretId) async {}
  Future<void> logSecretUnliked(String secretId) async {}
  Future<void> logSecretDisliked(String secretId) async {}
  Future<void> logSecretUndisliked(String secretId) async {}
  Future<void> logSecretSaved(String secretId) async {}
  Future<void> logSecretUnsaved(String secretId) async {}
  Future<void> logSecretDeleted(String secretId) async {}
  Future<void> logSecretReported({required String secretId, required String reason}) async {}
  Future<void> logAudioPlayback(String secretId) async {}
  Future<void> logCreatorProfileTapped(String creatorId) async {}
  Future<void> logGroupUnlockAttempt({required String secretId, required bool success}) async {}
  Future<void> logContentWarningDismissed(String secretId) async {}
  Future<void> logCommentAdded(String secretId) async {}
  Future<void> logCommentEdited(String secretId) async {}
  Future<void> logCommentDeleted(String secretId) async {}
  Future<void> logCommentReplied(String secretId) async {}
  Future<void> logCommentsOpened(String secretId) async {}
  Future<void> logFollow(String targetUserId) async {}
  Future<void> logUnfollow(String targetUserId) async {}
  Future<void> logUserSearch(String query) async {}
  Future<void> logFollowedUserTapped(String userId) async {}
  Future<void> logMapMarkerTapped(String secretId) async {}
  Future<void> logMapCenterOnUser() async {}
  Future<void> logMapRefresh() async {}
  Future<void> logFeedRefresh() async {}
  Future<void> logShareApp(String source) async {}
  Future<void> logInvitePopupShown() async {}
  Future<void> logInvitePopupAccepted() async {}
  Future<void> logInvitePopupDismissed() async {}
  Future<void> logDrawerAction(String action) async {}
  Future<void> logLanguageChanged(String language) async {}
  Future<void> logNotificationsPanelOpened() async {}
  Future<void> logNotificationTapped({String? secretId}) async {}
  Future<void> logTutorialStarted({required String source}) async {}
  Future<void> logTutorialPageViewed(int pageIndex) async {}
  Future<void> logTutorialCompleted() async {}
  Future<void> logTutorialSkipped(int lastPageViewed) async {}
  Future<void> logTierUp({required int oldTier, required int newTier}) async {}
  Future<void> logProfileTabChanged(String tab) async {}
  Future<void> logAppealSubmitted() async {}
  Future<void> logAdminAppealDecision({required String appealId, required bool approved}) async {}
  Future<void> logAdminReportDecision({required String reportId, required String secretId, required bool deleted}) async {}
  Future<void> logAdminMaintenanceAction(String action, {String? details}) async {}
}
