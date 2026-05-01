import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_pt.dart';

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
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ja'),
    Locale('pt')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Rhockai'**
  String get appTitle;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Intelligence Hub'**
  String get dashboardTitle;

  /// No description provided for @startWorkout.
  ///
  /// In en, this message translates to:
  /// **'Start AI Protocol'**
  String get startWorkout;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'System Config'**
  String get settings;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'Activity Logs'**
  String get history;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Neural Growth'**
  String get progress;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @voiceSettings.
  ///
  /// In en, this message translates to:
  /// **'Voice Synthesis'**
  String get voiceSettings;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @voiceEnabled.
  ///
  /// In en, this message translates to:
  /// **'Neural Feedback'**
  String get voiceEnabled;

  /// No description provided for @volume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volume;

  /// No description provided for @repCount.
  ///
  /// In en, this message translates to:
  /// **'Rep Detection'**
  String get repCount;

  /// No description provided for @formCorrection.
  ///
  /// In en, this message translates to:
  /// **'Kinematic Correction'**
  String get formCorrection;

  /// No description provided for @encouragement.
  ///
  /// In en, this message translates to:
  /// **'Motivation Engine'**
  String get encouragement;

  /// No description provided for @workoutComplete.
  ///
  /// In en, this message translates to:
  /// **'Session Synchronized'**
  String get workoutComplete;

  /// No description provided for @accuracy.
  ///
  /// In en, this message translates to:
  /// **'Precision'**
  String get accuracy;

  /// No description provided for @totalReps.
  ///
  /// In en, this message translates to:
  /// **'Total Cycles'**
  String get totalReps;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Uptime'**
  String get duration;

  /// No description provided for @calories.
  ///
  /// In en, this message translates to:
  /// **'Energy Flux'**
  String get calories;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Access System'**
  String get login;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Initialize Profile'**
  String get signup;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Access Key'**
  String get password;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'No profile detected?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Profile already exists?'**
  String get alreadyHaveAccount;

  /// No description provided for @workoutsToday.
  ///
  /// In en, this message translates to:
  /// **'Protocols Today'**
  String get workoutsToday;

  /// No description provided for @caloriesBurned.
  ///
  /// In en, this message translates to:
  /// **'Energy Expended'**
  String get caloriesBurned;

  /// No description provided for @postureAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Alignment Precision'**
  String get postureAccuracy;

  /// No description provided for @sessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessions;

  /// No description provided for @kcal.
  ///
  /// In en, this message translates to:
  /// **'Kcal'**
  String get kcal;

  /// No description provided for @goodPosture.
  ///
  /// In en, this message translates to:
  /// **'% Alignment'**
  String get goodPosture;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @exercises.
  ///
  /// In en, this message translates to:
  /// **'Modalities'**
  String get exercises;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Terminate Session'**
  String get logout;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'System Ready'**
  String get welcome;

  /// No description provided for @premiumPlan.
  ///
  /// In en, this message translates to:
  /// **'Rhockai Elite'**
  String get premiumPlan;

  /// No description provided for @basicPlan.
  ///
  /// In en, this message translates to:
  /// **'Rhockai Core'**
  String get basicPlan;

  /// No description provided for @workoutStats.
  ///
  /// In en, this message translates to:
  /// **'Performance Analytics'**
  String get workoutStats;

  /// No description provided for @latestActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Syncs'**
  String get latestActivity;

  /// No description provided for @goalsAndTips.
  ///
  /// In en, this message translates to:
  /// **'Directives & Insights'**
  String get goalsAndTips;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Initialize Profile'**
  String get createAccount;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Bio-Signature'**
  String get gender;

  /// No description provided for @genderOptional.
  ///
  /// In en, this message translates to:
  /// **'Bio-Signature (Optional)'**
  String get genderOptional;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Access keys do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Verify Access Key'**
  String get confirmPassword;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your identity'**
  String get enterName;

  /// No description provided for @nameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Identity must be at least 2 characters'**
  String get nameTooShort;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your network ID'**
  String get enterEmail;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid network ID'**
  String get invalidEmail;

  /// No description provided for @enterAge.
  ///
  /// In en, this message translates to:
  /// **'Please enter your age'**
  String get enterAge;

  /// No description provided for @invalidAge.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid age (13-120)'**
  String get invalidAge;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter an access key'**
  String get enterPassword;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Access key must be at least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Synchronize to continue your journey'**
  String get signInToContinue;

  /// No description provided for @forgotPasswordQuestion.
  ///
  /// In en, this message translates to:
  /// **'Access key lost?'**
  String get forgotPasswordQuestion;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @aboutThisWorkout.
  ///
  /// In en, this message translates to:
  /// **'Protocol Specifications'**
  String get aboutThisWorkout;

  /// No description provided for @aiCoachInsight.
  ///
  /// In en, this message translates to:
  /// **'Rhockai Intelligence'**
  String get aiCoachInsight;

  /// No description provided for @target.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get target;

  /// No description provided for @focus.
  ///
  /// In en, this message translates to:
  /// **'Focus Zone'**
  String get focus;

  /// No description provided for @repsLabel.
  ///
  /// In en, this message translates to:
  /// **'Cycles'**
  String get repsLabel;

  /// No description provided for @pushUps.
  ///
  /// In en, this message translates to:
  /// **'Push-Ups'**
  String get pushUps;

  /// No description provided for @squats.
  ///
  /// In en, this message translates to:
  /// **'Squats'**
  String get squats;

  /// No description provided for @planks.
  ///
  /// In en, this message translates to:
  /// **'Planks'**
  String get planks;

  /// No description provided for @pushUpsTraining.
  ///
  /// In en, this message translates to:
  /// **'Push-Ups Optimization'**
  String get pushUpsTraining;

  /// No description provided for @pushUpsDescription.
  ///
  /// In en, this message translates to:
  /// **'Deep neural form analysis and automated rep counting for Push-Ups.'**
  String get pushUpsDescription;

  /// No description provided for @squatsTraining.
  ///
  /// In en, this message translates to:
  /// **'Squats Optimization'**
  String get squatsTraining;

  /// No description provided for @squatsDescription.
  ///
  /// In en, this message translates to:
  /// **'Deep neural form analysis and automated rep counting for Squats.'**
  String get squatsDescription;

  /// No description provided for @planksTraining.
  ///
  /// In en, this message translates to:
  /// **'Planks Optimization'**
  String get planksTraining;

  /// No description provided for @planksDescription.
  ///
  /// In en, this message translates to:
  /// **'Deep neural form analysis and temporal tracking for Planks.'**
  String get planksDescription;

  /// No description provided for @tempo.
  ///
  /// In en, this message translates to:
  /// **'Pulse'**
  String get tempo;

  /// No description provided for @getReady.
  ///
  /// In en, this message translates to:
  /// **'Calibrating...'**
  String get getReady;

  /// No description provided for @analyzingEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Scanning environment...'**
  String get analyzingEnvironment;

  /// No description provided for @standInFrame.
  ///
  /// In en, this message translates to:
  /// **'Center in Visual Field'**
  String get standInFrame;

  /// No description provided for @comeCloser.
  ///
  /// In en, this message translates to:
  /// **'Optimize Distance'**
  String get comeCloser;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Suspend'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Conclude'**
  String get finish;

  /// No description provided for @excellent.
  ///
  /// In en, this message translates to:
  /// **'Peak Performance!'**
  String get excellent;

  /// No description provided for @keepGoing.
  ///
  /// In en, this message translates to:
  /// **'Continue Protocol!'**
  String get keepGoing;

  /// No description provided for @upgradeToPremium.
  ///
  /// In en, this message translates to:
  /// **'Ascend to Elite'**
  String get upgradeToPremium;

  /// No description provided for @unlockFullPotential.
  ///
  /// In en, this message translates to:
  /// **'Unlock Neural Potential'**
  String get unlockFullPotential;

  /// No description provided for @premiumDescription.
  ///
  /// In en, this message translates to:
  /// **'Access advanced Rhockai pose analytics, infinite protocols, and priority neural support.'**
  String get premiumDescription;

  /// No description provided for @monthlyPlanPrice.
  ///
  /// In en, this message translates to:
  /// **'Monthly Node - \$9.99/mo'**
  String get monthlyPlanPrice;

  /// No description provided for @yearlyPlanPrice.
  ///
  /// In en, this message translates to:
  /// **'Annual Sync - \$79.99/yr'**
  String get yearlyPlanPrice;

  /// No description provided for @lifetimePlanPrice.
  ///
  /// In en, this message translates to:
  /// **'Permanent Integration - \$149.99'**
  String get lifetimePlanPrice;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'de',
        'en',
        'es',
        'fr',
        'ja',
        'pt'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ja':
      return AppLocalizationsJa();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
