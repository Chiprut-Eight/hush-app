import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_he.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('he'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'HUSH'**
  String get appTitle;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to HUSH'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The geo-acoustic social network'**
  String get loginSubtitle;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @signInWithApple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get signInWithApple;

  /// No description provided for @feedTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby Secrets'**
  String get feedTitle;

  /// No description provided for @feedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No secrets nearby... Walk around to discover hidden whispers'**
  String get feedEmpty;

  /// No description provided for @feedLoading.
  ///
  /// In en, this message translates to:
  /// **'Listening for secrets...'**
  String get feedLoading;

  /// No description provided for @mapTitle.
  ///
  /// In en, this message translates to:
  /// **'Echo Map'**
  String get mapTitle;

  /// No description provided for @createTitle.
  ///
  /// In en, this message translates to:
  /// **'Drop a Secret'**
  String get createTitle;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @adminTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminTitle;

  /// No description provided for @secretPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'What\'s on your mind? Keep it secret... (max 140 chars)'**
  String get secretPlaceholder;

  /// No description provided for @recordVoice.
  ///
  /// In en, this message translates to:
  /// **'Record Voice Secret'**
  String get recordVoice;

  /// No description provided for @stopRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop Recording'**
  String get stopRecording;

  /// No description provided for @publishSecret.
  ///
  /// In en, this message translates to:
  /// **'Drop Secret'**
  String get publishSecret;

  /// No description provided for @hideSecretAction.
  ///
  /// In en, this message translates to:
  /// **'🤫 Hide Secret'**
  String get hideSecretAction;

  /// No description provided for @regularSecret.
  ///
  /// In en, this message translates to:
  /// **'Regular Secret'**
  String get regularSecret;

  /// No description provided for @regularSecretDesc.
  ///
  /// In en, this message translates to:
  /// **'Visible to everyone nearby immediately.'**
  String get regularSecretDesc;

  /// No description provided for @groupSecret.
  ///
  /// In en, this message translates to:
  /// **'Group Secret'**
  String get groupSecret;

  /// No description provided for @groupSecretDesc.
  ///
  /// In en, this message translates to:
  /// **'Requires multiple people nearby to unlock.'**
  String get groupSecretDesc;

  /// No description provided for @selectTier.
  ///
  /// In en, this message translates to:
  /// **'Select Minimum Tier'**
  String get selectTier;

  /// No description provided for @secretType.
  ///
  /// In en, this message translates to:
  /// **'Secret Type'**
  String get secretType;

  /// No description provided for @peopleRequired.
  ///
  /// In en, this message translates to:
  /// **'People Required'**
  String get peopleRequired;

  /// No description provided for @timeWindow.
  ///
  /// In en, this message translates to:
  /// **'Time Window: {minutes} minutes'**
  String timeWindow(int minutes);

  /// No description provided for @textTab.
  ///
  /// In en, this message translates to:
  /// **'✍️ Text'**
  String get textTab;

  /// No description provided for @voiceTab.
  ///
  /// In en, this message translates to:
  /// **'🎙️ Voice'**
  String get voiceTab;

  /// No description provided for @secretReady.
  ///
  /// In en, this message translates to:
  /// **'Secret Ready'**
  String get secretReady;

  /// No description provided for @tapToRecord.
  ///
  /// In en, this message translates to:
  /// **'Tap to Record'**
  String get tapToRecord;

  /// No description provided for @recordingLabel.
  ///
  /// In en, this message translates to:
  /// **'Recording...'**
  String get recordingLabel;

  /// No description provided for @audioPreview.
  ///
  /// In en, this message translates to:
  /// **'Audio Preview'**
  String get audioPreview;

  /// No description provided for @likes.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get likes;

  /// No description provided for @dislikes.
  ///
  /// In en, this message translates to:
  /// **'Dislikes'**
  String get dislikes;

  /// No description provided for @listens.
  ///
  /// In en, this message translates to:
  /// **'Listens'**
  String get listens;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @reveal.
  ///
  /// In en, this message translates to:
  /// **'Get closer to reveal...'**
  String get reveal;

  /// No description provided for @revealed.
  ///
  /// In en, this message translates to:
  /// **'Secret Revealed!'**
  String get revealed;

  /// No description provided for @metersAway.
  ///
  /// In en, this message translates to:
  /// **'{distance}m away'**
  String metersAway(int distance);

  /// No description provided for @outOfRange.
  ///
  /// In en, this message translates to:
  /// **'Out of range'**
  String get outOfRange;

  /// No description provided for @contentWarning.
  ///
  /// In en, this message translates to:
  /// **'Content Warning'**
  String get contentWarning;

  /// No description provided for @downvotedWarning.
  ///
  /// In en, this message translates to:
  /// **'This secret has been heavily downvoted.'**
  String get downvotedWarning;

  /// No description provided for @viewAnyway.
  ///
  /// In en, this message translates to:
  /// **'View Anyway'**
  String get viewAnyway;

  /// No description provided for @saveLimitWarning.
  ///
  /// In en, this message translates to:
  /// **'You can save up to 50 secrets combined.'**
  String get saveLimitWarning;

  /// No description provided for @publishedSecrets.
  ///
  /// In en, this message translates to:
  /// **'Published Secrets'**
  String get publishedSecrets;

  /// No description provided for @savedSecrets.
  ///
  /// In en, this message translates to:
  /// **'Saved Secrets'**
  String get savedSecrets;

  /// No description provided for @mySecretsTab.
  ///
  /// In en, this message translates to:
  /// **'My Secrets'**
  String get mySecretsTab;

  /// No description provided for @noPlantedSecrets.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t planted any secrets yet.'**
  String get noPlantedSecrets;

  /// No description provided for @noSavedSecrets.
  ///
  /// In en, this message translates to:
  /// **'No saved secrets found.'**
  String get noSavedSecrets;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// No description provided for @distinguished.
  ///
  /// In en, this message translates to:
  /// **'Distinguished'**
  String get distinguished;

  /// No description provided for @tier.
  ///
  /// In en, this message translates to:
  /// **'Tier {level}'**
  String tier(int level);

  /// No description provided for @cloutLevel.
  ///
  /// In en, this message translates to:
  /// **'Clout Level'**
  String get cloutLevel;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied. HUSH needs your location to discover nearby secrets.'**
  String get locationPermissionDenied;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable'**
  String get locationUnavailable;

  /// No description provided for @enableLocation.
  ///
  /// In en, this message translates to:
  /// **'Enable Location'**
  String get enableLocation;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @appeal.
  ///
  /// In en, this message translates to:
  /// **'Appeal'**
  String get appeal;

  /// No description provided for @appeals.
  ///
  /// In en, this message translates to:
  /// **'Appeals'**
  String get appeals;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @ghostMode.
  ///
  /// In en, this message translates to:
  /// **'Ghost Mode'**
  String get ghostMode;

  /// No description provided for @ghostModeActive.
  ///
  /// In en, this message translates to:
  /// **'👻 Ghost Mode Active'**
  String get ghostModeActive;

  /// No description provided for @ghostModeRestricted.
  ///
  /// In en, this message translates to:
  /// **'Your account features are restricted.'**
  String get ghostModeRestricted;

  /// No description provided for @cannotPlantGhost.
  ///
  /// In en, this message translates to:
  /// **'You cannot plant secrets right now.'**
  String get cannotPlantGhost;

  /// No description provided for @noReports.
  ///
  /// In en, this message translates to:
  /// **'No reports pending'**
  String get noReports;

  /// No description provided for @noAppeals.
  ///
  /// In en, this message translates to:
  /// **'No appeals pending'**
  String get noAppeals;

  /// No description provided for @maxChars.
  ///
  /// In en, this message translates to:
  /// **'{count}/140'**
  String maxChars(int count);

  /// No description provided for @recordingTime.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s / 60s'**
  String recordingTime(int seconds);

  /// No description provided for @mapboxNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Map not configured'**
  String get mapboxNotConfigured;

  /// No description provided for @tapToReveal.
  ///
  /// In en, this message translates to:
  /// **'Tap to reveal'**
  String get tapToReveal;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get onboardingTitle;

  /// No description provided for @onboardingWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to HUSH!'**
  String get onboardingWelcome;

  /// No description provided for @onboardingSub.
  ///
  /// In en, this message translates to:
  /// **'Please provide some basic details before starting your journey.'**
  String get onboardingSub;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get genderOther;

  /// No description provided for @hidePhoto.
  ///
  /// In en, this message translates to:
  /// **'Hide Profile Photo'**
  String get hidePhoto;

  /// No description provided for @hidePhotoSub.
  ///
  /// In en, this message translates to:
  /// **'Use generic HUSH logo instead of my photo'**
  String get hidePhotoSub;

  /// No description provided for @completeReg.
  ///
  /// In en, this message translates to:
  /// **'Complete Registration'**
  String get completeReg;

  /// No description provided for @firstNameReq.
  ///
  /// In en, this message translates to:
  /// **'First name is required'**
  String get firstNameReq;

  /// No description provided for @lastNameReq.
  ///
  /// In en, this message translates to:
  /// **'Last name is required'**
  String get lastNameReq;

  /// No description provided for @dobReq.
  ///
  /// In en, this message translates to:
  /// **'Please select your Date of Birth'**
  String get dobReq;

  /// No description provided for @followingTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get followingTabTitle;

  /// No description provided for @searchUsersHint.
  ///
  /// In en, this message translates to:
  /// **'Search users...'**
  String get searchUsersHint;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// No description provided for @notFollowingAnyone.
  ///
  /// In en, this message translates to:
  /// **'You are not following anyone yet.'**
  String get notFollowingAnyone;

  /// No description provided for @followBtn.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get followBtn;

  /// No description provided for @unfollowBtn.
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get unfollowBtn;

  /// No description provided for @publishedSecretAgo.
  ///
  /// In en, this message translates to:
  /// **'Published a secret {hours}h ago'**
  String publishedSecretAgo(int hours);

  /// No description provided for @tapToViewMap.
  ///
  /// In en, this message translates to:
  /// **'Tap to view on map'**
  String get tapToViewMap;

  /// No description provided for @noActiveSecrets.
  ///
  /// In en, this message translates to:
  /// **'No active secrets'**
  String get noActiveSecrets;

  /// No description provided for @anonymousUser.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get anonymousUser;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'he'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'he':
      return AppLocalizationsHe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
