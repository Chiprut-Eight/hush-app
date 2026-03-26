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
  String get secretPlaceholder => 'Type your secret... (max 140 chars)';

  @override
  String get recordVoice => 'Record Voice Secret';

  @override
  String get stopRecording => 'Stop Recording';

  @override
  String get publishSecret => 'Drop Secret';

  @override
  String get regularSecret => 'Regular Secret';

  @override
  String get groupSecret => 'Group Secret';

  @override
  String get selectTier => 'Select Minimum Tier';

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
  String get publishedSecrets => 'Published Secrets';

  @override
  String get savedSecrets => 'Saved Secrets';

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
  String get appeals => 'Appeals';

  @override
  String get reports => 'Reports';

  @override
  String get ghostMode => 'Ghost Mode';

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
  String get tapToReveal => 'Tap to reveal when close enough';
}
