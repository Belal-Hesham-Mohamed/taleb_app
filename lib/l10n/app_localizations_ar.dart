// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'طالب';

  @override
  String get welcomeTitle => 'رحلتك التعليمية تبدأ من هنا';

  @override
  String get welcomeBody => 'مساحة تعليمية للطلاب والمعلمين وأولياء الأمور.';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get chooseRole => 'اختر نوع الحساب';

  @override
  String get student => 'طالب';

  @override
  String get teacher => 'معلم';

  @override
  String get guardian => 'ولي أمر';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get school => 'المدرسة (اختياري)';

  @override
  String get grade => 'الصف الدراسي (اختياري)';

  @override
  String get signInTitle => 'مرحباً بعودتك';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get sendReset => 'إرسال رابط الاستعادة';

  @override
  String get resetTitle => 'استعادة كلمة المرور';

  @override
  String get resetSent => 'إذا كان البريد مسجلاً، سيصلك رابط الاستعادة قريباً.';

  @override
  String registerTitle(String role) {
    return 'إنشاء حساب $role';
  }

  @override
  String get continueLabel => 'متابعة';

  @override
  String get back => 'رجوع';

  @override
  String get submit => 'إنشاء الحساب';

  @override
  String get loading => 'يرجى الانتظار…';

  @override
  String get genericError => 'حدث خطأ. حاول مرة أخرى.';

  @override
  String get invalidCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  @override
  String get emailExists => 'يوجد حساب مسجل بهذا البريد الإلكتروني.';

  @override
  String get networkError => 'تعذر الاتصال. تحقق من اتصالك وحاول مجدداً.';

  @override
  String get profileError =>
      'تعذر تحميل ملفك الشخصي. حاول مجدداً أو سجل الخروج.';

  @override
  String get pendingTitle => 'طلب المعلم قيد المراجعة';

  @override
  String get pendingBody => 'سنبلغك بعد مراجعة حسابك.';

  @override
  String get homeTitle => 'مساحتك التعليمية';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get language => 'English';

  @override
  String get nameRequired => 'أدخل اسمك.';

  @override
  String get emailInvalid => 'أدخل بريداً إلكترونياً صحيحاً.';

  @override
  String get passwordShort => 'يجب ألا تقل كلمة المرور عن 8 أحرف.';

  @override
  String get optionalStep => 'يمكنك إضافة هذه البيانات لاحقاً.';

  @override
  String stepOf(int step, int total) {
    return 'الخطوة $step من $total';
  }

  @override
  String get resetEmailSent => 'تحقق من بريدك الإلكتروني لاستعادة كلمة المرور.';

  @override
  String get languageChanged => 'تم تغيير اللغة';

  @override
  String get showPassword => 'إظهار كلمة المرور';

  @override
  String get hidePassword => 'إخفاء كلمة المرور';

  @override
  String get rejectedTitle => 'طلب المعلم يحتاج إلى تعديل';

  @override
  String get rejectedBody =>
      'راجع السبب أدناه وتواصل مع الدعم لإعادة تقديم طلبك.';

  @override
  String get invalidRecoveryLink =>
      'رابط استعادة كلمة المرور غير صالح أو انتهت صلاحيته. اطلب رابطاً جديداً.';

  @override
  String get confirmEmailSent => 'تحقق من بريدك الإلكتروني لتأكيد عنوانك.';
}
