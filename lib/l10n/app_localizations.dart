import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Taleb'**
  String get appTitle;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'A brighter learning journey starts here'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'A learning space for students, teachers, and families.'**
  String get welcomeBody;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAccount;

  /// No description provided for @chooseRole.
  ///
  /// In en, this message translates to:
  /// **'Choose the account type that suits you'**
  String get chooseRole;

  /// No description provided for @studentRoleHint.
  ///
  /// In en, this message translates to:
  /// **'For a student account'**
  String get studentRoleHint;

  /// No description provided for @teacherRoleHint.
  ///
  /// In en, this message translates to:
  /// **'Teacher accounts require administrator approval'**
  String get teacherRoleHint;

  /// No description provided for @guardianRoleHint.
  ///
  /// In en, this message translates to:
  /// **'Student information requires an accepted active link'**
  String get guardianRoleHint;

  /// No description provided for @student.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get student;

  /// No description provided for @teacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get teacher;

  /// No description provided for @guardian.
  ///
  /// In en, this message translates to:
  /// **'Guardian'**
  String get guardian;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @school.
  ///
  /// In en, this message translates to:
  /// **'School (optional)'**
  String get school;

  /// No description provided for @grade.
  ///
  /// In en, this message translates to:
  /// **'Grade (optional)'**
  String get grade;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get signInTitle;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @sendReset.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendReset;

  /// No description provided for @resetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get resetTitle;

  /// No description provided for @resetSent.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for this email, a reset link is on its way.'**
  String get resetSent;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your {role} account'**
  String registerTitle(String role);

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get submit;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Please wait…'**
  String get loading;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get genericError;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'The email or password is incorrect.'**
  String get invalidCredentials;

  /// No description provided for @emailExists.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.'**
  String get emailExists;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect. Check your connection and try again.'**
  String get networkError;

  /// No description provided for @profileError.
  ///
  /// In en, this message translates to:
  /// **'We could not load your profile. Try again or sign out.'**
  String get profileError;

  /// No description provided for @pendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Your teacher application is under review'**
  String get pendingTitle;

  /// No description provided for @pendingBody.
  ///
  /// In en, this message translates to:
  /// **'We will let you know when your account has been reviewed.'**
  String get pendingBody;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your learning space'**
  String get homeTitle;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get language;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your name.'**
  String get nameRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get emailInvalid;

  /// No description provided for @passwordShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get passwordShort;

  /// No description provided for @optionalStep.
  ///
  /// In en, this message translates to:
  /// **'You can add these details later.'**
  String get optionalStep;

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String stepOf(int step, int total);

  /// No description provided for @resetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox for a password reset link.'**
  String get resetEmailSent;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language updated'**
  String get languageChanged;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @rejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your teacher application needs an update'**
  String get rejectedTitle;

  /// No description provided for @rejectedBody.
  ///
  /// In en, this message translates to:
  /// **'Review the reason below and contact support to resubmit your application.'**
  String get rejectedBody;

  /// No description provided for @invalidRecoveryLink.
  ///
  /// In en, this message translates to:
  /// **'This password reset link is invalid or has expired. Request a new one.'**
  String get invalidRecoveryLink;

  /// No description provided for @confirmEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox to confirm your email address.'**
  String get confirmEmailSent;

  /// No description provided for @studentSpaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Student space'**
  String get studentSpaceTitle;

  /// No description provided for @studentSpaceBody.
  ///
  /// In en, this message translates to:
  /// **'Your learning details will appear here when they are available.'**
  String get studentSpaceBody;

  /// No description provided for @teacherSpaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Teacher space'**
  String get teacherSpaceTitle;

  /// No description provided for @teacherSpaceBody.
  ///
  /// In en, this message translates to:
  /// **'Teacher tools are not available in this release.'**
  String get teacherSpaceBody;

  /// No description provided for @guardianSpaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Guardian space'**
  String get guardianSpaceTitle;

  /// No description provided for @guardianSpaceBody.
  ///
  /// In en, this message translates to:
  /// **'Student information will appear only after an active relationship is accepted.'**
  String get guardianSpaceBody;

  /// No description provided for @studentRegistrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Student registration'**
  String get studentRegistrationTitle;

  /// No description provided for @studentRegistrationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your student account in a few steps'**
  String get studentRegistrationSubtitle;

  /// No description provided for @stepCredentials.
  ///
  /// In en, this message translates to:
  /// **'Login data'**
  String get stepCredentials;

  /// No description provided for @stepPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal data'**
  String get stepPersonal;

  /// No description provided for @stepEducation.
  ///
  /// In en, this message translates to:
  /// **'Academic data'**
  String get stepEducation;

  /// No description provided for @stepReview.
  ///
  /// In en, this message translates to:
  /// **'Review data'**
  String get stepReview;

  /// No description provided for @stepSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account created'**
  String get stepSuccess;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phone;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number.'**
  String get phoneRequired;

  /// No description provided for @phoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Egyptian mobile number.'**
  String get phoneInvalid;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'The passwords do not match.'**
  String get passwordMismatch;

  /// No description provided for @checkingPhone.
  ///
  /// In en, this message translates to:
  /// **'Checking whether the number is available…'**
  String get checkingPhone;

  /// No description provided for @phoneTaken.
  ///
  /// In en, this message translates to:
  /// **'This phone number is already registered. Use another number.'**
  String get phoneTaken;

  /// No description provided for @phoneCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not check the number. Try again.'**
  String get phoneCheckFailed;

  /// No description provided for @phoneAvailable.
  ///
  /// In en, this message translates to:
  /// **'The number is available.'**
  String get phoneAvailable;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get dateOfBirth;

  /// No description provided for @dateOfBirthRequired.
  ///
  /// In en, this message translates to:
  /// **'Select your date of birth.'**
  String get dateOfBirthRequired;

  /// No description provided for @dateOfBirthInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid past date.'**
  String get dateOfBirthInvalid;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @genderRequired.
  ///
  /// In en, this message translates to:
  /// **'Select your gender.'**
  String get genderRequired;

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

  /// No description provided for @studentId.
  ///
  /// In en, this message translates to:
  /// **'Student ID (optional)'**
  String get studentId;

  /// No description provided for @studentIdHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the student ID'**
  String get studentIdHint;

  /// No description provided for @guardianPhone.
  ///
  /// In en, this message translates to:
  /// **'Guardian phone number'**
  String get guardianPhone;

  /// No description provided for @guardianPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the guardian phone number.'**
  String get guardianPhoneRequired;

  /// No description provided for @guardianPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Egyptian mobile number.'**
  String get guardianPhoneInvalid;

  /// No description provided for @guardianId.
  ///
  /// In en, this message translates to:
  /// **'Guardian ID (optional)'**
  String get guardianId;

  /// No description provided for @governorate.
  ///
  /// In en, this message translates to:
  /// **'Governorate'**
  String get governorate;

  /// No description provided for @governorateRequired.
  ///
  /// In en, this message translates to:
  /// **'Select your governorate.'**
  String get governorateRequired;

  /// No description provided for @area.
  ///
  /// In en, this message translates to:
  /// **'Area / center'**
  String get area;

  /// No description provided for @areaRequired.
  ///
  /// In en, this message translates to:
  /// **'Select your area.'**
  String get areaRequired;

  /// No description provided for @educationStage.
  ///
  /// In en, this message translates to:
  /// **'Educational stage'**
  String get educationStage;

  /// No description provided for @educationType.
  ///
  /// In en, this message translates to:
  /// **'Type of education'**
  String get educationType;

  /// No description provided for @academicSystem.
  ///
  /// In en, this message translates to:
  /// **'Academic system'**
  String get academicSystem;

  /// No description provided for @academicTrack.
  ///
  /// In en, this message translates to:
  /// **'Track / specialization'**
  String get academicTrack;

  /// No description provided for @educationStageRequired.
  ///
  /// In en, this message translates to:
  /// **'Select the educational stage.'**
  String get educationStageRequired;

  /// No description provided for @educationTypeRequired.
  ///
  /// In en, this message translates to:
  /// **'Select the type of education.'**
  String get educationTypeRequired;

  /// No description provided for @academicSystemRequired.
  ///
  /// In en, this message translates to:
  /// **'Select the academic system.'**
  String get academicSystemRequired;

  /// No description provided for @trackRequired.
  ///
  /// In en, this message translates to:
  /// **'Select the track.'**
  String get trackRequired;

  /// No description provided for @trackInvalid.
  ///
  /// In en, this message translates to:
  /// **'Select a track available for this grade.'**
  String get trackInvalid;

  /// No description provided for @trackNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'No track applies to this selection.'**
  String get trackNotAllowed;

  /// No description provided for @primary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get primary;

  /// No description provided for @preparatory.
  ///
  /// In en, this message translates to:
  /// **'Preparatory'**
  String get preparatory;

  /// No description provided for @secondary.
  ///
  /// In en, this message translates to:
  /// **'Secondary'**
  String get secondary;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @azhari.
  ///
  /// In en, this message translates to:
  /// **'Al-Azhar'**
  String get azhari;

  /// No description provided for @technical.
  ///
  /// In en, this message translates to:
  /// **'Technical'**
  String get technical;

  /// No description provided for @international.
  ///
  /// In en, this message translates to:
  /// **'International'**
  String get international;

  /// No description provided for @egyptianBaccalaureate.
  ///
  /// In en, this message translates to:
  /// **'Egyptian Baccalaureate'**
  String get egyptianBaccalaureate;

  /// No description provided for @generalSecondary.
  ///
  /// In en, this message translates to:
  /// **'General Secondary'**
  String get generalSecondary;

  /// No description provided for @primary1.
  ///
  /// In en, this message translates to:
  /// **'Grade 1 primary'**
  String get primary1;

  /// No description provided for @primary2.
  ///
  /// In en, this message translates to:
  /// **'Grade 2 primary'**
  String get primary2;

  /// No description provided for @primary3.
  ///
  /// In en, this message translates to:
  /// **'Grade 3 primary'**
  String get primary3;

  /// No description provided for @primary4.
  ///
  /// In en, this message translates to:
  /// **'Grade 4 primary'**
  String get primary4;

  /// No description provided for @primary5.
  ///
  /// In en, this message translates to:
  /// **'Grade 5 primary'**
  String get primary5;

  /// No description provided for @primary6.
  ///
  /// In en, this message translates to:
  /// **'Grade 6 primary'**
  String get primary6;

  /// No description provided for @preparatory1.
  ///
  /// In en, this message translates to:
  /// **'Grade 1 preparatory'**
  String get preparatory1;

  /// No description provided for @preparatory2.
  ///
  /// In en, this message translates to:
  /// **'Grade 2 preparatory'**
  String get preparatory2;

  /// No description provided for @preparatory3.
  ///
  /// In en, this message translates to:
  /// **'Grade 3 preparatory'**
  String get preparatory3;

  /// No description provided for @secondary1.
  ///
  /// In en, this message translates to:
  /// **'Grade 1 secondary'**
  String get secondary1;

  /// No description provided for @secondary2.
  ///
  /// In en, this message translates to:
  /// **'Grade 2 secondary'**
  String get secondary2;

  /// No description provided for @secondary3.
  ///
  /// In en, this message translates to:
  /// **'Grade 3 secondary'**
  String get secondary3;

  /// No description provided for @medicineAndLifeSciences.
  ///
  /// In en, this message translates to:
  /// **'Medicine and life sciences'**
  String get medicineAndLifeSciences;

  /// No description provided for @engineeringAndComputerScience.
  ///
  /// In en, this message translates to:
  /// **'Engineering and computer science'**
  String get engineeringAndComputerScience;

  /// No description provided for @businessStudies.
  ///
  /// In en, this message translates to:
  /// **'Business studies'**
  String get businessStudies;

  /// No description provided for @artsAndLiterature.
  ///
  /// In en, this message translates to:
  /// **'Arts and literature'**
  String get artsAndLiterature;

  /// No description provided for @scientific.
  ///
  /// In en, this message translates to:
  /// **'Scientific'**
  String get scientific;

  /// No description provided for @literary.
  ///
  /// In en, this message translates to:
  /// **'Literary'**
  String get literary;

  /// No description provided for @sciences.
  ///
  /// In en, this message translates to:
  /// **'Sciences'**
  String get sciences;

  /// No description provided for @mathematics.
  ///
  /// In en, this message translates to:
  /// **'Mathematics'**
  String get mathematics;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review your data'**
  String get reviewTitle;

  /// No description provided for @reviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your data before creating the account'**
  String get reviewSubtitle;

  /// No description provided for @reviewCredentials.
  ///
  /// In en, this message translates to:
  /// **'Login data'**
  String get reviewCredentials;

  /// No description provided for @reviewPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal data'**
  String get reviewPersonal;

  /// No description provided for @reviewEducation.
  ///
  /// In en, this message translates to:
  /// **'Academic data'**
  String get reviewEducation;

  /// No description provided for @reviewPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get reviewPhone;

  /// No description provided for @reviewPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get reviewPassword;

  /// No description provided for @passwordSet.
  ///
  /// In en, this message translates to:
  /// **'A password has been set'**
  String get passwordSet;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @createAccountNow.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccountNow;

  /// No description provided for @reviewChangeStageNotice.
  ///
  /// In en, this message translates to:
  /// **'Changing the stage clears the selections that no longer apply.'**
  String get reviewChangeStageNotice;

  /// No description provided for @successTitle.
  ///
  /// In en, this message translates to:
  /// **'Your account has been created'**
  String get successTitle;

  /// No description provided for @successBody.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Taleb. You can now start your learning journey.'**
  String get successBody;

  /// No description provided for @goToHome.
  ///
  /// In en, this message translates to:
  /// **'Go to the home screen'**
  String get goToHome;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not create the account. Try again.'**
  String get registrationFailed;

  /// No description provided for @registrationPhoneTaken.
  ///
  /// In en, this message translates to:
  /// **'This phone number was just registered. Try another number.'**
  String get registrationPhoneTaken;

  /// No description provided for @registrationNetwork.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect. Check your connection and try again.'**
  String get registrationNetwork;

  /// No description provided for @registrationTimeout.
  ///
  /// In en, this message translates to:
  /// **'The request timed out. Try again.'**
  String get registrationTimeout;

  /// No description provided for @registrationProfileFailed.
  ///
  /// In en, this message translates to:
  /// **'Your account was created but your details could not be saved. Contact support.'**
  String get registrationProfileFailed;

  /// No description provided for @registrationValidation.
  ///
  /// In en, this message translates to:
  /// **'Some data is not valid. Review the highlighted fields.'**
  String get registrationValidation;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @governorateCairo.
  ///
  /// In en, this message translates to:
  /// **'Cairo'**
  String get governorateCairo;

  /// No description provided for @governorateGiza.
  ///
  /// In en, this message translates to:
  /// **'Giza'**
  String get governorateGiza;

  /// No description provided for @governorateAlexandria.
  ///
  /// In en, this message translates to:
  /// **'Alexandria'**
  String get governorateAlexandria;

  /// No description provided for @governorateDakahlia.
  ///
  /// In en, this message translates to:
  /// **'Dakahlia'**
  String get governorateDakahlia;

  /// No description provided for @governorateSharqia.
  ///
  /// In en, this message translates to:
  /// **'Sharqia'**
  String get governorateSharqia;

  /// No description provided for @governorateQalyubia.
  ///
  /// In en, this message translates to:
  /// **'Qalyubia'**
  String get governorateQalyubia;

  /// No description provided for @governorateBeheira.
  ///
  /// In en, this message translates to:
  /// **'Beheira'**
  String get governorateBeheira;

  /// No description provided for @governorateGharbia.
  ///
  /// In en, this message translates to:
  /// **'Gharbia'**
  String get governorateGharbia;

  /// No description provided for @areaNasrCity.
  ///
  /// In en, this message translates to:
  /// **'Nasr City'**
  String get areaNasrCity;

  /// No description provided for @areaHeliopolis.
  ///
  /// In en, this message translates to:
  /// **'Heliopolis'**
  String get areaHeliopolis;

  /// No description provided for @areaMaadi.
  ///
  /// In en, this message translates to:
  /// **'Maadi'**
  String get areaMaadi;

  /// No description provided for @areaZamalek.
  ///
  /// In en, this message translates to:
  /// **'Zamalek'**
  String get areaZamalek;

  /// No description provided for @areaDowntown.
  ///
  /// In en, this message translates to:
  /// **'Downtown'**
  String get areaDowntown;

  /// No description provided for @areaDokki.
  ///
  /// In en, this message translates to:
  /// **'Dokki'**
  String get areaDokki;

  /// No description provided for @areaAgouza.
  ///
  /// In en, this message translates to:
  /// **'Agouza'**
  String get areaAgouza;

  /// No description provided for @educationProgram.
  ///
  /// In en, this message translates to:
  /// **'Educational program'**
  String get educationProgram;

  /// No description provided for @educationProgramRequired.
  ///
  /// In en, this message translates to:
  /// **'Select the educational program.'**
  String get educationProgramRequired;

  /// No description provided for @gradeRequired.
  ///
  /// In en, this message translates to:
  /// **'Select the grade.'**
  String get gradeRequired;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @catalogLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load education options. Tap to retry.'**
  String get catalogLoadError;

  /// No description provided for @noOptionsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No options available'**
  String get noOptionsAvailable;

  /// No description provided for @areaInvalid.
  ///
  /// In en, this message translates to:
  /// **'Select an area belonging to this governorate.'**
  String get areaInvalid;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
