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
  /// **'Nearby Hushhh'**
  String get feedTitle;

  /// No description provided for @feedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No Hushhh nearby... Walk around to discover hidden whispers'**
  String get feedEmpty;

  /// No description provided for @feedLoading.
  ///
  /// In en, this message translates to:
  /// **'Listening for Hushhh...'**
  String get feedLoading;

  /// No description provided for @mapTitle.
  ///
  /// In en, this message translates to:
  /// **'Echo Map'**
  String get mapTitle;

  /// No description provided for @createTitle.
  ///
  /// In en, this message translates to:
  /// **'Drop a Hushhh'**
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
  /// **'What\'s on your mind? Keep it Hushhh... (max 140 chars)'**
  String get secretPlaceholder;

  /// No description provided for @recordVoice.
  ///
  /// In en, this message translates to:
  /// **'Record Voice Hushhh'**
  String get recordVoice;

  /// No description provided for @stopRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop Recording'**
  String get stopRecording;

  /// No description provided for @publishSecret.
  ///
  /// In en, this message translates to:
  /// **'Drop Hushhh'**
  String get publishSecret;

  /// No description provided for @hideSecretAction.
  ///
  /// In en, this message translates to:
  /// **'Hide Hushhh'**
  String get hideSecretAction;

  /// No description provided for @regularSecret.
  ///
  /// In en, this message translates to:
  /// **'Regular Hushhh'**
  String get regularSecret;

  /// No description provided for @regularSecretDesc.
  ///
  /// In en, this message translates to:
  /// **'Visible to everyone nearby immediately.'**
  String get regularSecretDesc;

  /// No description provided for @groupSecret.
  ///
  /// In en, this message translates to:
  /// **'Group Hushhh'**
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
  /// **'Hushhh Type'**
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
  /// **'Text'**
  String get textTab;

  /// No description provided for @voiceTab.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get voiceTab;

  /// No description provided for @secretReady.
  ///
  /// In en, this message translates to:
  /// **'Hushhh Ready'**
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
  /// **'Hushhh Revealed!'**
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
  /// **'This Hushhh has been heavily downvoted.'**
  String get downvotedWarning;

  /// No description provided for @viewAnyway.
  ///
  /// In en, this message translates to:
  /// **'View Anyway'**
  String get viewAnyway;

  /// No description provided for @saveLimitWarning.
  ///
  /// In en, this message translates to:
  /// **'You can save up to 50 Hushhh combined.'**
  String get saveLimitWarning;

  /// No description provided for @publishedSecrets.
  ///
  /// In en, this message translates to:
  /// **'Published Hushhh'**
  String get publishedSecrets;

  /// No description provided for @savedSecrets.
  ///
  /// In en, this message translates to:
  /// **'Saved Hushhh'**
  String get savedSecrets;

  /// No description provided for @mySecretsTab.
  ///
  /// In en, this message translates to:
  /// **'My Hushhh'**
  String get mySecretsTab;

  /// No description provided for @noPlantedSecrets.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t planted any Hushhh yet.'**
  String get noPlantedSecrets;

  /// No description provided for @noSavedSecrets.
  ///
  /// In en, this message translates to:
  /// **'No saved Hushhh found.'**
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
  /// **'Location permission denied. HUSH needs your location to discover nearby Hushhh.'**
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
  /// **'Ghost Mode Active'**
  String get ghostModeActive;

  /// No description provided for @ghostModeRestricted.
  ///
  /// In en, this message translates to:
  /// **'Your account features are restricted.'**
  String get ghostModeRestricted;

  /// No description provided for @cannotPlantGhost.
  ///
  /// In en, this message translates to:
  /// **'You cannot plant Hushhh right now.'**
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
  /// **'Published a Hushhh {hours}h ago'**
  String publishedSecretAgo(int hours);

  /// No description provided for @tapToViewMap.
  ///
  /// In en, this message translates to:
  /// **'Tap to view on map'**
  String get tapToViewMap;

  /// No description provided for @noActiveSecrets.
  ///
  /// In en, this message translates to:
  /// **'No active Hushhh'**
  String get noActiveSecrets;

  /// No description provided for @anonymousUser.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get anonymousUser;

  /// No description provided for @followers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get followers;

  /// No description provided for @timeAgoSeconds.
  ///
  /// In en, this message translates to:
  /// **'{count}s ago'**
  String timeAgoSeconds(int count);

  /// No description provided for @timeAgoMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String timeAgoMinutes(int count);

  /// No description provided for @timeAgoHours.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String timeAgoHours(int count);

  /// No description provided for @timeAgoDays.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String timeAgoDays(int count);

  /// No description provided for @timeAgoWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count}w ago'**
  String timeAgoWeeks(int count);

  /// No description provided for @timeAgoMonths.
  ///
  /// In en, this message translates to:
  /// **'{count}mo ago'**
  String timeAgoMonths(int count);

  /// No description provided for @timeAgoYears.
  ///
  /// In en, this message translates to:
  /// **'{count}y ago'**
  String timeAgoYears(int count);

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Hushhh'**
  String get reportTitle;

  /// No description provided for @reportReason.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting this?'**
  String get reportReason;

  /// No description provided for @reportReasonHate.
  ///
  /// In en, this message translates to:
  /// **'Hate speech'**
  String get reportReasonHate;

  /// No description provided for @reportReasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get reportReasonSpam;

  /// No description provided for @reportReasonHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment'**
  String get reportReasonHarassment;

  /// No description provided for @reportReasonViolence.
  ///
  /// In en, this message translates to:
  /// **'Violence'**
  String get reportReasonViolence;

  /// No description provided for @reportReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reportReasonOther;

  /// No description provided for @reportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Report submitted. Thank you.'**
  String get reportSuccess;

  /// No description provided for @reportConfirm.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportConfirm;

  /// No description provided for @appealTitle.
  ///
  /// In en, this message translates to:
  /// **'Submit Appeal'**
  String get appealTitle;

  /// No description provided for @appealReason.
  ///
  /// In en, this message translates to:
  /// **'Explain why you are appealing:'**
  String get appealReason;

  /// No description provided for @appealSuccess.
  ///
  /// In en, this message translates to:
  /// **'Appeal submitted. We\'ll review your case.'**
  String get appealSuccess;

  /// No description provided for @appealSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit Appeal'**
  String get appealSubmit;

  /// No description provided for @deleteSecretTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Hushhh'**
  String get deleteSecretTitle;

  /// No description provided for @deleteSecretConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this Hushhh? This cannot be undone.'**
  String get deleteSecretConfirm;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @addComment.
  ///
  /// In en, this message translates to:
  /// **'Add a comment...'**
  String get addComment;

  /// No description provided for @noComments.
  ///
  /// In en, this message translates to:
  /// **'No comments yet. Be the first!'**
  String get noComments;

  /// No description provided for @deleteComment.
  ///
  /// In en, this message translates to:
  /// **'Delete Comment'**
  String get deleteComment;

  /// No description provided for @commentPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Write a comment...'**
  String get commentPlaceholder;

  /// No description provided for @directionToSecret.
  ///
  /// In en, this message translates to:
  /// **'Direction to Hushhh'**
  String get directionToSecret;

  /// No description provided for @groupUnlockProgress.
  ///
  /// In en, this message translates to:
  /// **'Wait! {count} more people are needed to reveal this Hushhh.'**
  String groupUnlockProgress(int count);

  /// No description provided for @groupUnlockSuccess.
  ///
  /// In en, this message translates to:
  /// **'The group has unified. Hushhh revealed!'**
  String get groupUnlockSuccess;

  /// No description provided for @maintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenanceTitle;

  /// No description provided for @testConfetti.
  ///
  /// In en, this message translates to:
  /// **'Test Confetti Animation'**
  String get testConfetti;

  /// No description provided for @testPushNotification.
  ///
  /// In en, this message translates to:
  /// **'Test Push Notification'**
  String get testPushNotification;

  /// No description provided for @testPushTitle.
  ///
  /// In en, this message translates to:
  /// **'Someone liked your Hushhh ❤️'**
  String get testPushTitle;

  /// No description provided for @testPushBody.
  ///
  /// In en, this message translates to:
  /// **'Your Hushhh is getting attention!'**
  String get testPushBody;

  /// No description provided for @testPushSuccess.
  ///
  /// In en, this message translates to:
  /// **'Test notification sent! Check your notification tray.'**
  String get testPushSuccess;

  /// No description provided for @migrateUsers.
  ///
  /// In en, this message translates to:
  /// **'Migrate Users (Batch)'**
  String get migrateUsers;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @migrationSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search Index Migration'**
  String get migrationSearchTitle;

  /// No description provided for @migrationSearchDesc.
  ///
  /// In en, this message translates to:
  /// **'This tool populates the \"searchName\" field for old users to make them searchable in the new system.'**
  String get migrationSearchDesc;

  /// No description provided for @migrationReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to migrate users.'**
  String get migrationReady;

  /// No description provided for @migrationFetching.
  ///
  /// In en, this message translates to:
  /// **'Fetching users lacking searchName...'**
  String get migrationFetching;

  /// No description provided for @migrationAllDone.
  ///
  /// In en, this message translates to:
  /// **'All users migrated!'**
  String get migrationAllDone;

  /// No description provided for @migrationBatchDone.
  ///
  /// In en, this message translates to:
  /// **'Batch of users migrated! Run again if needed.'**
  String get migrationBatchDone;

  /// No description provided for @migrationError.
  ///
  /// In en, this message translates to:
  /// **'Error during migration: {error}'**
  String migrationError(String error);

  /// No description provided for @tutorial_p1_title.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Hushhh'**
  String get tutorial_p1_title;

  /// No description provided for @tutorial_p1_content.
  ///
  /// In en, this message translates to:
  /// **'We are a geographic social network where physical space becomes your Hushhh board.\n• How does it work? Hushhh is like a secret - you \'plant a Hushhh\' (voice or text message) at the exact point where you are.\n• The world is your feed: The feed is dynamic and changes according to your location - it will always show what is happening around you right now.'**
  String get tutorial_p1_content;

  /// No description provided for @tutorial_p2_title.
  ///
  /// In en, this message translates to:
  /// **'The Reveal of the Hushhh'**
  String get tutorial_p2_title;

  /// No description provided for @tutorial_p2_content.
  ///
  /// In en, this message translates to:
  /// **'Hushhh in the feed appear in a \'blurred\' state as long as you are far away.\n• Hushhh becomes available for opening only when you are physically within 15 meters.\n• Once you reach the range, the blur will disappear and you can read the text or press Play and listen.\n• On the map, you can look for a pulsating frequency to see interesting activity within a 200m radius.'**
  String get tutorial_p2_content;

  /// No description provided for @tutorial_p3_title.
  ///
  /// In en, this message translates to:
  /// **'Regular or Group Hushhh?'**
  String get tutorial_p3_title;

  /// No description provided for @tutorial_p3_content.
  ///
  /// In en, this message translates to:
  /// **'Not every Hushhh is for one person. You set the rules:\n• Regular Hushhh is open to anyone who arrives at the point.\n• Group Hushhh = Group challenge! It can only be opened if a certain number of users (minimum 3) are at the point simultaneously in a defined time window.\n• Level Up: Success in activating group Hushhh increases your status - the halo color around the Hushhh changes, identifying you as an interesting creator.'**
  String get tutorial_p3_content;

  /// No description provided for @tutorial_p4_title.
  ///
  /// In en, this message translates to:
  /// **'Where is my content?'**
  String get tutorial_p4_title;

  /// No description provided for @tutorial_p4_content.
  ///
  /// In en, this message translates to:
  /// **'Content in Hushhh is temporary and live, creating urgency and authenticity:\n• Deletion mechanism: Hushhh that haven\'t been viewed or are older than 60 days are deleted to keep the map clean.\n• Save button: Found a Hushhh you must keep? You can save up to 50 Hushhh in your profile, and they will never be deleted.\n• Quality above all: Your profile displays distinguished Hushhh you\'ve published - those that survived the test of time.\nMissed something? Don\'t worry. You can always return to the full explanation through the settings menu.\nReady to plant your first Hushhh?'**
  String get tutorial_p4_content;

  /// No description provided for @action_understand.
  ///
  /// In en, this message translates to:
  /// **'I Got It'**
  String get action_understand;

  /// No description provided for @drawer_what_is_hush.
  ///
  /// In en, this message translates to:
  /// **'What is Hushhh?'**
  String get drawer_what_is_hush;
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
