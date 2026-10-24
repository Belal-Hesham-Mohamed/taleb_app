// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Taleb';

  @override
  String get welcomeTitle => 'A brighter learning journey starts here';

  @override
  String get welcomeBody =>
      'A learning space for students, teachers, and families.';

  @override
  String get signIn => 'Sign in';

  @override
  String get createAccount => 'Create an account';

  @override
  String get chooseRole => 'Choose the account type that suits you';

  @override
  String get studentRoleHint => 'For a student account';

  @override
  String get teacherRoleHint =>
      'Teacher accounts require administrator approval';

  @override
  String get guardianRoleHint =>
      'Student information requires an accepted active link';

  @override
  String get student => 'Student';

  @override
  String get teacher => 'Teacher';

  @override
  String get guardian => 'Guardian';

  @override
  String get email => 'Email address';

  @override
  String get password => 'Password';

  @override
  String get fullName => 'Full name';

  @override
  String get school => 'School (optional)';

  @override
  String get grade => 'Grade (optional)';

  @override
  String get signInTitle => 'Welcome back';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get sendReset => 'Send reset link';

  @override
  String get resetTitle => 'Reset your password';

  @override
  String get resetSent =>
      'If an account exists for this email, a reset link is on its way.';

  @override
  String registerTitle(String role) {
    return 'Create your $role account';
  }

  @override
  String get continueLabel => 'Continue';

  @override
  String get back => 'Back';

  @override
  String get submit => 'Create account';

  @override
  String get loading => 'Please wait…';

  @override
  String get genericError => 'Something went wrong. Please try again.';

  @override
  String get invalidCredentials => 'The email or password is incorrect.';

  @override
  String get emailExists => 'An account with this email already exists.';

  @override
  String get networkError =>
      'Unable to connect. Check your connection and try again.';

  @override
  String get profileError =>
      'We could not load your profile. Try again or sign out.';

  @override
  String get pendingTitle => 'Your teacher application is under review';

  @override
  String get pendingBody =>
      'We will let you know when your account has been reviewed.';

  @override
  String get homeTitle => 'Your learning space';

  @override
  String get signOut => 'Sign out';

  @override
  String get language => 'العربية';

  @override
  String get nameRequired => 'Enter your name.';

  @override
  String get emailInvalid => 'Enter a valid email address.';

  @override
  String get passwordShort => 'Use at least 8 characters.';

  @override
  String get optionalStep => 'You can add these details later.';

  @override
  String stepOf(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get resetEmailSent => 'Check your inbox for a password reset link.';

  @override
  String get languageChanged => 'Language updated';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get rejectedTitle => 'Your teacher application needs an update';

  @override
  String get rejectedBody =>
      'Review the reason below and contact support to resubmit your application.';

  @override
  String get invalidRecoveryLink =>
      'This password reset link is invalid or has expired. Request a new one.';

  @override
  String get confirmEmailSent =>
      'Check your inbox to confirm your email address.';

  @override
  String get studentSpaceTitle => 'Student space';

  @override
  String get studentSpaceBody =>
      'Your learning details will appear here when they are available.';

  @override
  String get teacherSpaceTitle => 'Teacher space';

  @override
  String get teacherSpaceBody =>
      'Teacher tools are not available in this release.';

  @override
  String get guardianSpaceTitle => 'Guardian space';

  @override
  String get guardianSpaceBody =>
      'Student information will appear only after an active relationship is accepted.';

  @override
  String get studentRegistrationTitle => 'Student registration';

  @override
  String get studentRegistrationSubtitle =>
      'Create your student account in a few steps';

  @override
  String get stepCredentials => 'Login data';

  @override
  String get stepPersonal => 'Personal data';

  @override
  String get stepEducation => 'Academic data';

  @override
  String get stepReview => 'Review data';

  @override
  String get stepSuccess => 'Account created';

  @override
  String get phone => 'Phone number';

  @override
  String get phoneRequired => 'Enter your phone number.';

  @override
  String get phoneInvalid => 'Enter a valid Egyptian mobile number.';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get passwordMismatch => 'The passwords do not match.';

  @override
  String get checkingPhone => 'Checking whether the number is available…';

  @override
  String get phoneTaken =>
      'This phone number is already registered. Use another number.';

  @override
  String get phoneCheckFailed => 'We could not check the number. Try again.';

  @override
  String get phoneAvailable => 'The number is available.';

  @override
  String get dateOfBirth => 'Date of birth';

  @override
  String get dateOfBirthRequired => 'Select your date of birth.';

  @override
  String get dateOfBirthInvalid => 'Enter a valid past date.';

  @override
  String get gender => 'Gender';

  @override
  String get genderRequired => 'Select your gender.';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get studentId => 'Student ID (optional)';

  @override
  String get studentIdHint => 'Enter the student ID';

  @override
  String get guardianPhone => 'Guardian phone number';

  @override
  String get guardianPhoneRequired => 'Enter the guardian phone number.';

  @override
  String get guardianPhoneInvalid => 'Enter a valid Egyptian mobile number.';

  @override
  String get guardianId => 'Guardian ID (optional)';

  @override
  String get governorate => 'Governorate';

  @override
  String get governorateRequired => 'Select your governorate.';

  @override
  String get area => 'Area / center';

  @override
  String get areaRequired => 'Select your area.';

  @override
  String get educationStage => 'Educational stage';

  @override
  String get educationType => 'Type of education';

  @override
  String get academicSystem => 'Academic system';

  @override
  String get academicTrack => 'Track / specialization';

  @override
  String get educationStageRequired => 'Select the educational stage.';

  @override
  String get educationTypeRequired => 'Select the type of education.';

  @override
  String get academicSystemRequired => 'Select the academic system.';

  @override
  String get trackRequired => 'Select the track.';

  @override
  String get trackInvalid => 'Select a track available for this grade.';

  @override
  String get trackNotAllowed => 'No track applies to this selection.';

  @override
  String get primary => 'Primary';

  @override
  String get preparatory => 'Preparatory';

  @override
  String get secondary => 'Secondary';

  @override
  String get general => 'General';

  @override
  String get azhari => 'Al-Azhar';

  @override
  String get technical => 'Technical';

  @override
  String get international => 'International';

  @override
  String get egyptianBaccalaureate => 'Egyptian Baccalaureate';

  @override
  String get generalSecondary => 'General Secondary';

  @override
  String get primary1 => 'Grade 1 primary';

  @override
  String get primary2 => 'Grade 2 primary';

  @override
  String get primary3 => 'Grade 3 primary';

  @override
  String get primary4 => 'Grade 4 primary';

  @override
  String get primary5 => 'Grade 5 primary';

  @override
  String get primary6 => 'Grade 6 primary';

  @override
  String get preparatory1 => 'Grade 1 preparatory';

  @override
  String get preparatory2 => 'Grade 2 preparatory';

  @override
  String get preparatory3 => 'Grade 3 preparatory';

  @override
  String get secondary1 => 'Grade 1 secondary';

  @override
  String get secondary2 => 'Grade 2 secondary';

  @override
  String get secondary3 => 'Grade 3 secondary';

  @override
  String get medicineAndLifeSciences => 'Medicine and life sciences';

  @override
  String get engineeringAndComputerScience =>
      'Engineering and computer science';

  @override
  String get businessStudies => 'Business studies';

  @override
  String get artsAndLiterature => 'Arts and literature';

  @override
  String get scientific => 'Scientific';

  @override
  String get literary => 'Literary';

  @override
  String get sciences => 'Sciences';

  @override
  String get mathematics => 'Mathematics';

  @override
  String get reviewTitle => 'Review your data';

  @override
  String get reviewSubtitle => 'Verify your data before creating the account';

  @override
  String get reviewCredentials => 'Login data';

  @override
  String get reviewPersonal => 'Personal data';

  @override
  String get reviewEducation => 'Academic data';

  @override
  String get reviewPhone => 'Phone number';

  @override
  String get reviewPassword => 'Password';

  @override
  String get passwordSet => 'A password has been set';

  @override
  String get edit => 'Edit';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get createAccountNow => 'Create account';

  @override
  String get reviewChangeStageNotice =>
      'Changing the stage clears the selections that no longer apply.';

  @override
  String get successTitle => 'Your account has been created';

  @override
  String get successBody =>
      'Welcome to Taleb. You can now start your learning journey.';

  @override
  String get goToHome => 'Go to the home screen';

  @override
  String get registrationFailed =>
      'We could not create the account. Try again.';

  @override
  String get registrationPhoneTaken =>
      'This phone number was just registered. Try another number.';

  @override
  String get registrationNetwork =>
      'Unable to connect. Check your connection and try again.';

  @override
  String get registrationTimeout => 'The request timed out. Try again.';

  @override
  String get registrationProfileFailed =>
      'Your account was created but your details could not be saved. Contact support.';

  @override
  String get registrationValidation =>
      'Some data is not valid. Review the highlighted fields.';

  @override
  String get selectDate => 'Select date';

  @override
  String get governorateCairo => 'Cairo';

  @override
  String get governorateGiza => 'Giza';

  @override
  String get governorateAlexandria => 'Alexandria';

  @override
  String get governorateDakahlia => 'Dakahlia';

  @override
  String get governorateSharqia => 'Sharqia';

  @override
  String get governorateQalyubia => 'Qalyubia';

  @override
  String get governorateBeheira => 'Beheira';

  @override
  String get governorateGharbia => 'Gharbia';

  @override
  String get areaNasrCity => 'Nasr City';

  @override
  String get areaHeliopolis => 'Heliopolis';

  @override
  String get areaMaadi => 'Maadi';

  @override
  String get areaZamalek => 'Zamalek';

  @override
  String get areaDowntown => 'Downtown';

  @override
  String get areaDokki => 'Dokki';

  @override
  String get areaAgouza => 'Agouza';

  @override
  String get educationProgram => 'Educational program';

  @override
  String get educationProgramRequired => 'Select the educational program.';

  @override
  String get gradeRequired => 'Select the grade.';

  @override
  String get retry => 'Retry';

  @override
  String get catalogLoadError =>
      'Failed to load education options. Tap to retry.';

  @override
  String get noOptionsAvailable => 'No options available';

  @override
  String get areaInvalid => 'Select an area belonging to this governorate.';

  @override
  String get catalogStillLoading => 'Wait until the options finish loading.';

  @override
  String get areaUnavailable =>
      'No areas are available for this governorate. Try again.';

  @override
  String get tracksLoadError => 'Failed to load tracks. Tap retry.';

  @override
  String get commonSubjects => 'Grade subjects';

  @override
  String get trackSubjects => 'Track subjects';

  @override
  String get requiredSubject => 'Required';

  @override
  String get optionalSubject => 'Optional';

  @override
  String get choiceSubject => 'Choice';

  @override
  String get advancedSubject => 'Advanced';

  @override
  String get noSubjectsAvailable => 'No subjects listed for this selection.';

  @override
  String get subjectsLoadError => 'Failed to load subjects. Tap retry.';
}
