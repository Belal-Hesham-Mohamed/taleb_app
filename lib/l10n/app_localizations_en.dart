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
  String get chooseRole => 'Choose your account type';

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
}
