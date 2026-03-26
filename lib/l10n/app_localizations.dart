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
  /// **'Type your secret... (max 140 chars)'**
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

  /// No description provided for @regularSecret.
  ///
  /// In en, this message translates to:
  /// **'Regular Secret'**
  String get regularSecret;

  /// No description provided for @groupSecret.
  ///
  /// In en, this message translates to:
  /// **'Group Secret'**
  String get groupSecret;

  /// No description provided for @selectTier.
  ///
  /// In en, this message translates to:
  /// **'Select Minimum Tier'**
  String get selectTier;

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
  /// **'Tap to reveal when close enough'**
  String get tapToReveal;
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
