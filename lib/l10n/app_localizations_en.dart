// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'HUSH';

  @override
  String get loginTitle => 'Welcome to HUSH';

  @override
  String get loginSubtitle => 'The geo-acoustic social network';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get signInWithApple => 'Sign in with Apple';

  @override
  String get feedTitle => 'Nearby Secrets';

  @override
  String get feedEmpty =>
      'No secrets nearby... Walk around to discover hidden whispers';

  @override
  String get feedLoading => 'Listening for secrets...';

  @override
  String get mapTitle => 'Echo Map';

  @override
  String get createTitle => 'Drop a Secret';

  @override
  String get profileTitle => 'Profile';

  @override
  String get adminTitle => 'Admin Panel';

  @override
  String get secretPlaceholder =>
      'What\'s on your mind? Keep it secret... (max 140 chars)';

  @override
  String get recordVoice => 'Record Voice Secret';

  @override
  String get stopRecording => 'Stop Recording';

  @override
  String get publishSecret => 'Drop Secret';

  @override
  String get hideSecretAction => 'Hide Secret';

  @override
  String get regularSecret => 'Regular Secret';

  @override
  String get regularSecretDesc => 'Visible to everyone nearby immediately.';

  @override
  String get groupSecret => 'Group Secret';

  @override
  String get groupSecretDesc => 'Requires multiple people nearby to unlock.';

  @override
  String get selectTier => 'Select Minimum Tier';

  @override
  String get secretType => 'Secret Type';

  @override
  String get peopleRequired => 'People Required';

  @override
  String timeWindow(int minutes) {
    return 'Time Window: $minutes minutes';
  }

  @override
  String get textTab => 'Text';

  @override
  String get voiceTab => 'Voice';

  @override
  String get secretReady => 'Secret Ready';

  @override
  String get tapToRecord => 'Tap to Record';

  @override
  String get recordingLabel => 'Recording...';

  @override
  String get audioPreview => 'Audio Preview';

  @override
  String get likes => 'Likes';

  @override
  String get dislikes => 'Dislikes';

  @override
  String get listens => 'Listens';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get report => 'Report';

  @override
  String get reveal => 'Get closer to reveal...';

  @override
  String get revealed => 'Secret Revealed!';

  @override
  String metersAway(int distance) {
    return '${distance}m away';
  }

  @override
  String get outOfRange => 'Out of range';

  @override
  String get contentWarning => 'Content Warning';

  @override
  String get downvotedWarning => 'This secret has been heavily downvoted.';

  @override
  String get viewAnyway => 'View Anyway';

  @override
  String get saveLimitWarning => 'You can save up to 50 secrets combined.';

  @override
  String get publishedSecrets => 'Published Secrets';

  @override
  String get savedSecrets => 'Saved Secrets';

  @override
  String get mySecretsTab => 'My Secrets';

  @override
  String get noPlantedSecrets => 'You haven\'t planted any secrets yet.';

  @override
  String get noSavedSecrets => 'No saved secrets found.';

  @override
  String get enableNotifications => 'Enable Notifications';

  @override
  String get distinguished => 'Distinguished';

  @override
  String tier(int level) {
    return 'Tier $level';
  }

  @override
  String get cloutLevel => 'Clout Level';

  @override
  String get signOut => 'Sign Out';

  @override
  String get language => 'Language';

  @override
  String get locationPermissionDenied =>
      'Location permission denied. HUSH needs your location to discover nearby secrets.';

  @override
  String get locationUnavailable => 'Location unavailable';

  @override
  String get enableLocation => 'Enable Location';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get confirm => 'Confirm';

  @override
  String get appeal => 'Appeal';

  @override
  String get appeals => 'Appeals';

  @override
  String get reports => 'Reports';

  @override
  String get ghostMode => 'Ghost Mode';

  @override
  String get ghostModeActive => 'Ghost Mode Active';

  @override
  String get ghostModeRestricted => 'Your account features are restricted.';

  @override
  String get cannotPlantGhost => 'You cannot plant secrets right now.';

  @override
  String get noReports => 'No reports pending';

  @override
  String get noAppeals => 'No appeals pending';

  @override
  String maxChars(int count) {
    return '$count/140';
  }

  @override
  String recordingTime(int seconds) {
    return '${seconds}s / 60s';
  }

  @override
  String get mapboxNotConfigured => 'Map not configured';

  @override
  String get tapToReveal => 'Tap to reveal';

  @override
  String get onboardingTitle => 'Complete Your Profile';

  @override
  String get onboardingWelcome => 'Welcome to HUSH!';

  @override
  String get onboardingSub =>
      'Please provide some basic details before starting your journey.';

  @override
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get dateOfBirth => 'Date of Birth';

  @override
  String get selectDate => 'Select date';

  @override
  String get gender => 'Gender';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderOther => 'Other';

  @override
  String get hidePhoto => 'Hide Profile Photo';

  @override
  String get hidePhotoSub => 'Use generic HUSH logo instead of my photo';

  @override
  String get completeReg => 'Complete Registration';

  @override
  String get firstNameReq => 'First name is required';

  @override
  String get lastNameReq => 'Last name is required';

  @override
  String get dobReq => 'Please select your Date of Birth';

  @override
  String get followingTabTitle => 'Following';

  @override
  String get searchUsersHint => 'Search users...';

  @override
  String get noUsersFound => 'No users found';

  @override
  String get notFollowingAnyone => 'You are not following anyone yet.';

  @override
  String get followBtn => 'Follow';

  @override
  String get unfollowBtn => 'Unfollow';

  @override
  String publishedSecretAgo(int hours) {
    return 'Published a secret ${hours}h ago';
  }

  @override
  String get tapToViewMap => 'Tap to view on map';

  @override
  String get noActiveSecrets => 'No active secrets';

  @override
  String get anonymousUser => 'Anonymous';

  @override
  String get followers => 'Followers';

  @override
  String timeAgoSeconds(int count) {
    return '${count}s ago';
  }

  @override
  String timeAgoMinutes(int count) {
    return '${count}m ago';
  }

  @override
  String timeAgoHours(int count) {
    return '${count}h ago';
  }

  @override
  String timeAgoDays(int count) {
    return '${count}d ago';
  }

  @override
  String timeAgoWeeks(int count) {
    return '${count}w ago';
  }

  @override
  String timeAgoMonths(int count) {
    return '${count}mo ago';
  }

  @override
  String timeAgoYears(int count) {
    return '${count}y ago';
  }

  @override
  String get reportTitle => 'Report Secret';

  @override
  String get reportReason => 'Why are you reporting this?';

  @override
  String get reportReasonHate => 'Hate speech';

  @override
  String get reportReasonSpam => 'Spam';

  @override
  String get reportReasonHarassment => 'Harassment';

  @override
  String get reportReasonViolence => 'Violence';

  @override
  String get reportReasonOther => 'Other';

  @override
  String get reportSuccess => 'Report submitted. Thank you.';

  @override
  String get reportConfirm => 'Report';

  @override
  String get appealTitle => 'Submit Appeal';

  @override
  String get appealReason => 'Explain why you are appealing:';

  @override
  String get appealSuccess => 'Appeal submitted. We\'ll review your case.';

  @override
  String get appealSubmit => 'Submit Appeal';

  @override
  String get deleteSecretTitle => 'Delete Secret';

  @override
  String get deleteSecretConfirm =>
      'Are you sure you want to delete this secret? This cannot be undone.';

  @override
  String get comments => 'Comments';

  @override
  String get addComment => 'Add a comment...';

  @override
  String get noComments => 'No comments yet. Be the first!';

  @override
  String get deleteComment => 'Delete Comment';

  @override
  String get commentPlaceholder => 'Write a comment...';

  @override
  String get directionToSecret => 'Direction to secret';
}
