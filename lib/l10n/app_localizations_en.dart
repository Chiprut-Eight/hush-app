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
  String get feedTitle => 'Nearby Hushhh';

  @override
  String get feedEmpty =>
      'No Hushhh nearby... Walk around to discover hidden whispers';

  @override
  String get feedLoading => 'Listening for Hushhh...';

  @override
  String get mapTitle => 'Echo Map';

  @override
  String get createTitle => 'Drop a Hushhh';

  @override
  String get profileTitle => 'Profile';

  @override
  String get adminTitle => 'Admin Panel';

  @override
  String get secretPlaceholder =>
      'What\'s on your mind? Keep it Hushhh... (max 140 chars)';

  @override
  String get recordVoice => 'Record Voice Hushhh';

  @override
  String get stopRecording => 'Stop Recording';

  @override
  String get publishSecret => 'Drop Hushhh';

  @override
  String get hideSecretAction => 'Hide Hushhh';

  @override
  String get regularSecret => 'Regular Hushhh';

  @override
  String get regularSecretDesc => 'Visible to everyone nearby immediately.';

  @override
  String get groupSecret => 'Group Hushhh';

  @override
  String get groupSecretDesc => 'Requires multiple people nearby to unlock.';

  @override
  String get selectTier => 'Select Minimum Tier';

  @override
  String get secretType => 'Hushhh Type';

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
  String get secretReady => 'Hushhh Ready';

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
  String get revealed => 'Hushhh Revealed!';

  @override
  String metersAway(int distance) {
    return '${distance}m away';
  }

  @override
  String get outOfRange => 'Out of range';

  @override
  String get contentWarning => 'Content Warning';

  @override
  String get downvotedWarning => 'This Hushhh has been heavily downvoted.';

  @override
  String get viewAnyway => 'View Anyway';

  @override
  String get saveLimitWarning => 'You can save up to 50 Hushhh combined.';

  @override
  String get publishedSecrets => 'Published Hushhh';

  @override
  String get savedSecrets => 'Saved Hushhh';

  @override
  String get mySecretsTab => 'My Hushhh';

  @override
  String get noPlantedSecrets => 'You haven\'t planted any Hushhh yet.';

  @override
  String get noSavedSecrets => 'No saved Hushhh found.';

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
      'Location permission denied. HUSH needs your location to discover nearby Hushhh.';

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
  String get cannotPlantGhost => 'You cannot plant Hushhh right now.';

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
    return 'Published a Hushhh ${hours}h ago';
  }

  @override
  String get tapToViewMap => 'Tap to view on map';

  @override
  String get noActiveSecrets => 'No active Hushhh';

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
  String get reportTitle => 'Report Hushhh';

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
  String get deleteSecretTitle => 'Delete Hushhh';

  @override
  String get deleteSecretConfirm =>
      'Are you sure you want to delete this Hushhh? This cannot be undone.';

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
  String get directionToSecret => 'Direction to Hushhh';

  @override
  String groupUnlockProgress(int count) {
    return 'Wait! $count more people are needed to reveal this Hushhh.';
  }

  @override
  String get groupUnlockSuccess => 'The group has unified. Hushhh revealed!';

  @override
  String get maintenanceTitle => 'Maintenance';

  @override
  String get testConfetti => 'Test Confetti Animation';

  @override
  String get migrateUsers => 'Migrate Users (Batch)';

  @override
  String get settings => 'Settings';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get migrationSearchTitle => 'Search Index Migration';

  @override
  String get migrationSearchDesc =>
      'This tool populates the \"searchName\" field for old users to make them searchable in the new system.';

  @override
  String get migrationReady => 'Ready to migrate users.';

  @override
  String get migrationFetching => 'Fetching users lacking searchName...';

  @override
  String get migrationAllDone => 'All users migrated!';

  @override
  String get migrationBatchDone =>
      'Batch of users migrated! Run again if needed.';

  @override
  String migrationError(String error) {
    return 'Error during migration: $error';
  }

  @override
  String get tutorial_p1_title => 'Welcome to Hushhh';

  @override
  String get tutorial_p1_content =>
      'We are a geographic social network where physical space becomes your Hushhh board.\n• How does it work? Hushhh is like a secret - you \'plant a Hushhh\' (voice or text message) at the exact point where you are.\n• The world is your feed: The feed is dynamic and changes according to your location - it will always show what is happening around you right now.';

  @override
  String get tutorial_p2_title => 'The Reveal of the Hushhh';

  @override
  String get tutorial_p2_content =>
      'Hushhh in the feed appear in a \'blurred\' state as long as you are far away.\n• Hushhh becomes available for opening only when you are physically within 15 meters.\n• Once you reach the range, the blur will disappear and you can read the text or press Play and listen.\n• On the map, you can look for a pulsating frequency to see interesting activity within a 200m radius.';

  @override
  String get tutorial_p3_title => 'Regular or Group Hushhh?';

  @override
  String get tutorial_p3_content =>
      'Not every Hushhh is for one person. You set the rules:\n• Regular Hushhh is open to anyone who arrives at the point.\n• Group Hushhh = Group challenge! It can only be opened if a certain number of users (minimum 3) are at the point simultaneously in a defined time window.\n• Level Up: Success in activating group Hushhh increases your status - the halo color around the Hushhh changes, identifying you as an interesting creator.';

  @override
  String get tutorial_p4_title => 'Where is my content?';

  @override
  String get tutorial_p4_content =>
      'Content in Hushhh is temporary and live, creating urgency and authenticity:\n• Deletion mechanism: Hushhh that haven\'t been viewed or are older than 60 days are deleted to keep the map clean.\n• Save button: Found a Hushhh you must keep? You can save up to 50 Hushhh in your profile, and they will never be deleted.\n• Quality above all: Your profile displays distinguished Hushhh you\'ve published - those that survived the test of time.\nMissed something? Don\'t worry. You can always return to the full explanation through the settings menu.\nReady to plant your first Hushhh?';

  @override
  String get action_understand => 'I Got It';

  @override
  String get drawer_what_is_hush => 'What is Hushhh?';

  @override
  String get testPushNotification => 'Test Push Notification';

  @override
  String get testPushTitle => 'Someone liked your Hushhh ❤️';

  @override
  String get testPushBody => 'Your Hushhh is getting attention!';

  @override
  String get testPushSuccess =>
      'Test notification sent! Check your notification tray.';
}
