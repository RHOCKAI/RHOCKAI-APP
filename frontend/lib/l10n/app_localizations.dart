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
  /// **'Home'**
  String get dashboardTitle;

  /// No description provided for @startWorkout.
  ///
  /// In en, this message translates to:
  /// **'Start Workout'**
  String get startWorkout;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'Workout History'**
  String get history;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'My Progress'**
  String get progress;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @voiceSettings.
  ///
  /// In en, this message translates to:
  /// **'Voice Feedback'**
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
  /// **'Voice Guidance'**
  String get voiceEnabled;

  /// No description provided for @volume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volume;

  /// No description provided for @repCount.
  ///
  /// In en, this message translates to:
  /// **'Rep Counting'**
  String get repCount;

  /// No description provided for @formCorrection.
  ///
  /// In en, this message translates to:
  /// **'Form Advice'**
  String get formCorrection;

  /// No description provided for @encouragement.
  ///
  /// In en, this message translates to:
  /// **'Encouragement'**
  String get encouragement;

  /// No description provided for @workoutComplete.
  ///
  /// In en, this message translates to:
  /// **'Workout Complete!'**
  String get workoutComplete;

  /// No description provided for @accuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get accuracy;

  /// No description provided for @totalReps.
  ///
  /// In en, this message translates to:
  /// **'Total Reps'**
  String get totalReps;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @calories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get calories;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get login;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signup;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'New to Rhockai?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @workoutsToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Workouts'**
  String get workoutsToday;

  /// No description provided for @caloriesBurned.
  ///
  /// In en, this message translates to:
  /// **'Calories Burned'**
  String get caloriesBurned;

  /// No description provided for @postureAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Posture Accuracy'**
  String get postureAccuracy;

  /// No description provided for @sessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessions;

  /// No description provided for @kcal.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get kcal;

  /// No description provided for @goodPosture.
  ///
  /// In en, this message translates to:
  /// **'% Good'**
  String get goodPosture;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @exercises.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get exercises;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @premiumPlan.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premiumPlan;

  /// No description provided for @basicPlan.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get basicPlan;

  /// No description provided for @workoutStats.
  ///
  /// In en, this message translates to:
  /// **'Your Stats'**
  String get workoutStats;

  /// No description provided for @latestActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get latestActivity;

  /// No description provided for @goalsAndTips.
  ///
  /// In en, this message translates to:
  /// **'Goals & Tips'**
  String get goalsAndTips;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
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
  /// **'Gender'**
  String get gender;

  /// No description provided for @genderOptional.
  ///
  /// In en, this message translates to:
  /// **'Gender (Optional)'**
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
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get enterName;

  /// No description provided for @nameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get nameTooShort;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get enterEmail;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
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
  /// **'Please enter a password'**
  String get enterPassword;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInToContinue;

  /// No description provided for @forgotPasswordQuestion.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPasswordQuestion;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @aboutThisWorkout.
  ///
  /// In en, this message translates to:
  /// **'About this Workout'**
  String get aboutThisWorkout;

  /// No description provided for @aiCoachInsight.
  ///
  /// In en, this message translates to:
  /// **'Rhockai Coach'**
  String get aiCoachInsight;

  /// No description provided for @target.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get target;

  /// No description provided for @focus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get focus;

  /// No description provided for @repsLabel.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
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
  /// **'Push-Ups'**
  String get pushUpsTraining;

  /// No description provided for @pushUpsDescription.
  ///
  /// In en, this message translates to:
  /// **'Real-time form analysis and rep counting for push-ups.'**
  String get pushUpsDescription;

  /// No description provided for @squatsTraining.
  ///
  /// In en, this message translates to:
  /// **'Squats'**
  String get squatsTraining;

  /// No description provided for @squatsDescription.
  ///
  /// In en, this message translates to:
  /// **'Real-time form analysis and rep counting for squats.'**
  String get squatsDescription;

  /// No description provided for @planksTraining.
  ///
  /// In en, this message translates to:
  /// **'Planks'**
  String get planksTraining;

  /// No description provided for @planksDescription.
  ///
  /// In en, this message translates to:
  /// **'Real-time form analysis and time tracking for planks.'**
  String get planksDescription;

  /// No description provided for @tempo.
  ///
  /// In en, this message translates to:
  /// **'Tempo'**
  String get tempo;

  /// No description provided for @getReady.
  ///
  /// In en, this message translates to:
  /// **'Get Ready!'**
  String get getReady;

  /// No description provided for @analyzingEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Setting up...'**
  String get analyzingEnvironment;

  /// No description provided for @standInFrame.
  ///
  /// In en, this message translates to:
  /// **'Center yourself in the frame'**
  String get standInFrame;

  /// No description provided for @comeCloser.
  ///
  /// In en, this message translates to:
  /// **'Move closer to the camera'**
  String get comeCloser;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @excellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent!'**
  String get excellent;

  /// No description provided for @keepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep it up!'**
  String get keepGoing;

  /// No description provided for @upgradeToPremium.
  ///
  /// In en, this message translates to:
  /// **'Go Premium'**
  String get upgradeToPremium;

  /// No description provided for @unlockFullPotential.
  ///
  /// In en, this message translates to:
  /// **'Unlock All Features'**
  String get unlockFullPotential;

  /// No description provided for @premiumDescription.
  ///
  /// In en, this message translates to:
  /// **'Get advanced form analysis, unlimited workouts, and priority support.'**
  String get premiumDescription;

  /// No description provided for @monthlyPlanPrice.
  ///
  /// In en, this message translates to:
  /// **'\$9.99 / Month'**
  String get monthlyPlanPrice;

  /// No description provided for @yearlyPlanPrice.
  ///
  /// In en, this message translates to:
  /// **'\$79.99 / Year'**
  String get yearlyPlanPrice;

  /// No description provided for @lifetimePlanPrice.
  ///
  /// In en, this message translates to:
  /// **'\$149.99 Once'**
  String get lifetimePlanPrice;

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
  String get manageSubscription;

  /// No description provided for @subscriptionStatus.
  ///
  /// In en, this message translates to:
  /// **'Subscription Status'**
  String get subscriptionStatus;

  /// No description provided for @premiumMemberStatus.
  ///
  /// In en, this message translates to:
  /// **'You are a Premium Member! 🚀'**
  String get premiumMemberStatus;

  /// No description provided for @premiumMemberDescription.
  ///
  /// In en, this message translates to:
  /// **'Thank you for supporting Rhockai. You have full access to all AI features.'**
  String get premiumMemberDescription;

  /// No description provided for @goPremiumTitle.
  ///
  /// In en, this message translates to:
  /// **'Go Premium'**
  String get goPremiumTitle;

  /// No description provided for @goPremiumSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Train smarter. See results faster.'**
  String get goPremiumSubtitle;

  /// No description provided for @featureHistory.
  ///
  /// In en, this message translates to:
  /// **'Full workout history & trends'**
  String get featureHistory;

  /// No description provided for @featureAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Rep-by-rep accuracy breakdown'**
  String get featureAccuracy;

  /// No description provided for @featureHeatmap.
  ///
  /// In en, this message translates to:
  /// **'Calendar heatmap & streak tracking'**
  String get featureHeatmap;

  /// No description provided for @featureAchievements.
  ///
  /// In en, this message translates to:
  /// **'Complete achievement system'**
  String get featureAchievements;

  /// No description provided for @featureVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice coaching in 7 languages'**
  String get featureVoice;

  /// No description provided for @featureSupport.
  ///
  /// In en, this message translates to:
  /// **'Priority support'**
  String get featureSupport;

  /// No description provided for @weeklyPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weeklyPlanTitle;

  /// No description provided for @weeklyPlanPriceText.
  ///
  /// In en, this message translates to:
  /// **'\$2.99/week'**
  String get weeklyPlanPriceText;

  /// No description provided for @weeklyPlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Most flexible'**
  String get weeklyPlanLabel;

  /// No description provided for @monthlyPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthlyPlanTitle;

  /// No description provided for @monthlyPlanPriceText.
  ///
  /// In en, this message translates to:
  /// **'\$4.99/month'**
  String get monthlyPlanPriceText;

  /// No description provided for @yearlyPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearlyPlanTitle;

  /// No description provided for @yearlyPlanPriceText.
  ///
  /// In en, this message translates to:
  /// **'\$29.99/year'**
  String get yearlyPlanPriceText;

  /// No description provided for @yearlyPlanBadge.
  ///
  /// In en, this message translates to:
  /// **'Best Value · Save 50%'**
  String get yearlyPlanBadge;

  /// No description provided for @lifetimePlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Lifetime'**
  String get lifetimePlanTitle;

  /// No description provided for @lifetimePlanPriceText.
  ///
  /// In en, this message translates to:
  /// **'\$79.99 once'**
  String get lifetimePlanPriceText;

  /// No description provided for @lifetimePlanLabel.
  ///
  /// In en, this message translates to:
  /// **'🔒 Founding member price — limited'**
  String get lifetimePlanLabel;

  /// No description provided for @startFreeTrial.
  ///
  /// In en, this message translates to:
  /// **'Start Free Trial'**
  String get startFreeTrial;

  /// No description provided for @freeTrialBadge.
  ///
  /// In en, this message translates to:
  /// **'3 DAYS FREE'**
  String get freeTrialBadge;

  /// No description provided for @cancelAnytime.
  ///
  /// In en, this message translates to:
  /// **'Cancel anytime · No commitment'**
  String get cancelAnytime;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchases;

  /// No description provided for @maybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get maybeLater;

  /// No description provided for @shareWorkout.
  ///
  /// In en, this message translates to:
  /// **'Share Workout'**
  String get shareWorkout;

  /// No description provided for @sharePerformance.
  ///
  /// In en, this message translates to:
  /// **'Share Performance Scorecard'**
  String get sharePerformance;

  /// No description provided for @shareVideo.
  ///
  /// In en, this message translates to:
  /// **'Share Video Instead'**
  String get shareVideo;

  /// No description provided for @greatSession.
  ///
  /// In en, this message translates to:
  /// **'Great session, {name} 💪'**
  String greatSession(Object name);

  /// No description provided for @eliteForm.
  ///
  /// In en, this message translates to:
  /// **'Elite form 🏆'**
  String get eliteForm;

  /// No description provided for @solidSession.
  ///
  /// In en, this message translates to:
  /// **'Solid session 💪'**
  String get solidSession;

  /// No description provided for @keepPushing.
  ///
  /// In en, this message translates to:
  /// **'Keep pushing 🔥'**
  String get keepPushing;

  /// No description provided for @formInProgress.
  ///
  /// In en, this message translates to:
  /// **'Form in progress 📈'**
  String get formInProgress;

  /// No description provided for @showRhockaiBadge.
  ///
  /// In en, this message translates to:
  /// **'Show Rhockai badge'**
  String get showRhockaiBadge;

  /// No description provided for @helpOthersDiscover.
  ///
  /// In en, this message translates to:
  /// **'Help others discover AI training'**
  String get helpOthersDiscover;

  /// No description provided for @saveToCameraRoll.
  ///
  /// In en, this message translates to:
  /// **'Save to Camera Roll'**
  String get saveToCameraRoll;

  /// No description provided for @savedToHistory.
  ///
  /// In en, this message translates to:
  /// **'Saved to your Rhockai history automatically'**
  String get savedToHistory;

  /// No description provided for @dayStreak.
  ///
  /// In en, this message translates to:
  /// **'{days} day streak'**
  String dayStreak(Object days);

  /// No description provided for @fitnessLevel.
  ///
  /// In en, this message translates to:
  /// **'Fitness Level'**
  String get fitnessLevel;

  /// No description provided for @beginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get beginner;

  /// No description provided for @intermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get intermediate;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;
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
