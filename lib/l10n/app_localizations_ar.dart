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
  String get chooseRole => 'اختر نوع الحساب المناسب لك';

  @override
  String get studentRoleHint => 'حساب مخصص للطالب';

  @override
  String get teacherRoleHint => 'تتطلب حسابات المعلمين موافقة الإدارة';

  @override
  String get guardianRoleHint => 'تتطلب معلومات الطالب رابطاً نشطاً ومقبولاً';

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

  @override
  String get studentSpaceTitle => 'مساحة الطالب';

  @override
  String get studentSpaceBody => 'ستظهر تفاصيل رحلتك التعليمية هنا عند توفرها.';

  @override
  String get teacherSpaceTitle => 'مساحة المعلم';

  @override
  String get teacherSpaceBody => 'أدوات المعلم غير متاحة في هذا الإصدار.';

  @override
  String get guardianSpaceTitle => 'مساحة ولي الأمر';

  @override
  String get guardianSpaceBody =>
      'لن تظهر معلومات الطالب إلا بعد قبول علاقة نشطة.';

  @override
  String get studentRegistrationTitle => 'تسجيل طالب';

  @override
  String get studentRegistrationSubtitle => 'أنشئ حسابك كطالب في خطوات بسيطة';

  @override
  String get stepCredentials => 'بيانات الدخول';

  @override
  String get stepPersonal => 'البيانات الشخصية';

  @override
  String get stepEducation => 'البيانات الدراسية';

  @override
  String get stepReview => 'مراجعة البيانات';

  @override
  String get stepSuccess => 'تم إنشاء الحساب';

  @override
  String get phone => 'رقم الهاتف';

  @override
  String get phoneRequired => 'أدخل رقم هاتفك.';

  @override
  String get phoneInvalid => 'أدخل رقم موبايل مصري صحيح.';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get passwordMismatch => 'كلمتا المرور غير متطابقتين.';

  @override
  String get checkingPhone => 'جاري التحقق من توفر الرقم…';

  @override
  String get phoneTaken => 'رقم الهاتف مسجل بالفعل. استخدم رقماً آخر.';

  @override
  String get phoneCheckFailed => 'تعذر التحقق من الرقم. حاول مرة أخرى.';

  @override
  String get phoneAvailable => 'الرقم متاح.';

  @override
  String get dateOfBirth => 'تاريخ الميلاد';

  @override
  String get dateOfBirthRequired => 'اختر تاريخ الميلاد.';

  @override
  String get dateOfBirthInvalid => 'أدخل تاريخاً صحيحاً في الماضي.';

  @override
  String get gender => 'النوع';

  @override
  String get genderRequired => 'اختر النوع.';

  @override
  String get male => 'ذكر';

  @override
  String get female => 'أنثى';

  @override
  String get studentId => 'رقم هوية الطالب (اختياري)';

  @override
  String get studentIdHint => 'أدخل رقم هوية الطالب';

  @override
  String get guardianPhone => 'رقم هاتف ولي الأمر';

  @override
  String get guardianPhoneRequired => 'أدخل رقم هاتف ولي الأمر.';

  @override
  String get guardianPhoneInvalid => 'أدخل رقم موبايل مصري صحيح.';

  @override
  String get guardianId => 'رقم هوية ولي الأمر (اختياري)';

  @override
  String get governorate => 'المحافظة';

  @override
  String get governorateRequired => 'اختر المحافظة.';

  @override
  String get area => 'المنطقة / المركز';

  @override
  String get areaRequired => 'اختر المنطقة.';

  @override
  String get educationStage => 'المرحلة التعليمية';

  @override
  String get educationType => 'نوع التعليم';

  @override
  String get academicSystem => 'النظام الدراسي';

  @override
  String get academicTrack => 'المسار / التخصص';

  @override
  String get educationStageRequired => 'اختر المرحلة التعليمية.';

  @override
  String get educationTypeRequired => 'اختر نوع التعليم.';

  @override
  String get academicSystemRequired => 'اختر النظام الدراسي.';

  @override
  String get trackRequired => 'اختر المسار.';

  @override
  String get trackInvalid => 'اختر مساراً متاحاً لهذا الصف.';

  @override
  String get trackNotAllowed => 'لا يوجد مسار لهذا الاختيار.';

  @override
  String get primary => 'ابتدائي';

  @override
  String get preparatory => 'إعدادي';

  @override
  String get secondary => 'ثانوي';

  @override
  String get general => 'عام';

  @override
  String get azhari => 'أزهري';

  @override
  String get technical => 'فني';

  @override
  String get international => 'دولي';

  @override
  String get egyptianBaccalaureate => 'البكالوريا المصرية';

  @override
  String get generalSecondary => 'الثانوية العامة';

  @override
  String get primary1 => 'الصف الأول الابتدائي';

  @override
  String get primary2 => 'الصف الثاني الابتدائي';

  @override
  String get primary3 => 'الصف الثالث الابتدائي';

  @override
  String get primary4 => 'الصف الرابع الابتدائي';

  @override
  String get primary5 => 'الصف الخامس الابتدائي';

  @override
  String get primary6 => 'الصف السادس الابتدائي';

  @override
  String get preparatory1 => 'الصف الأول الإعدادي';

  @override
  String get preparatory2 => 'الصف الثاني الإعدادي';

  @override
  String get preparatory3 => 'الصف الثالث الإعدادي';

  @override
  String get secondary1 => 'الصف الأول الثانوي';

  @override
  String get secondary2 => 'الصف الثاني الثانوي';

  @override
  String get secondary3 => 'الصف الثالث الثانوي';

  @override
  String get medicineAndLifeSciences => 'الطب وعلوم الحياة';

  @override
  String get engineeringAndComputerScience => 'الهندسة وعلوم الحاسب';

  @override
  String get businessStudies => 'الأعمال';

  @override
  String get artsAndLiterature => 'الآداب والفنون';

  @override
  String get scientific => 'علمي';

  @override
  String get literary => 'أدبي';

  @override
  String get sciences => 'علوم';

  @override
  String get mathematics => 'رياضيات';

  @override
  String get reviewTitle => 'مراجعة البيانات';

  @override
  String get reviewSubtitle => 'تأكد من صحة بياناتك قبل إنشاء الحساب';

  @override
  String get reviewCredentials => 'بيانات الدخول';

  @override
  String get reviewPersonal => 'البيانات الشخصية';

  @override
  String get reviewEducation => 'البيانات الدراسية';

  @override
  String get reviewPhone => 'رقم الهاتف';

  @override
  String get reviewPassword => 'كلمة المرور';

  @override
  String get passwordSet => 'تم تعيين كلمة مرور';

  @override
  String get edit => 'تعديل';

  @override
  String get next => 'التالي';

  @override
  String get previous => 'السابق';

  @override
  String get createAccountNow => 'إنشاء الحساب';

  @override
  String get reviewChangeStageNotice =>
      'تغيير المرحلة يلغي الاختيارات التي لم تعد مناسبة.';

  @override
  String get successTitle => 'تم إنشاء حسابك بنجاح';

  @override
  String get successBody =>
      'مرحباً بك في طالب. يمكنك الآن البدء في رحلتك التعليمية.';

  @override
  String get goToHome => 'الذهاب إلى الشاشة الرئيسية';

  @override
  String get registrationFailed => 'لم نتمكن من إنشاء الحساب. حاول مرة أخرى.';

  @override
  String get registrationPhoneTaken =>
      'تم تسجيل رقم الهاتف للتو. جرّب رقماً آخر.';

  @override
  String get registrationNetwork =>
      'تعذر الاتصال. تحقق من اتصالك وحاول مجدداً.';

  @override
  String get registrationTimeout => 'انتهت مدة الطلب. حاول مرة أخرى.';

  @override
  String get registrationProfileFailed =>
      'تم إنشاء الحساب لكن تعذر حفظ بياناتك. تواصل مع الدعم.';

  @override
  String get registrationValidation =>
      'بعض البيانات غير صحيحة. راجع الحقول المميزة.';

  @override
  String get selectDate => 'اختر التاريخ';

  @override
  String get governorateCairo => 'القاهرة';

  @override
  String get governorateGiza => 'الجيزة';

  @override
  String get governorateAlexandria => 'الإسكندرية';

  @override
  String get governorateDakahlia => 'الدقهلية';

  @override
  String get governorateSharqia => 'الشرقية';

  @override
  String get governorateQalyubia => 'القليوبية';

  @override
  String get governorateBeheira => 'البحيرة';

  @override
  String get governorateGharbia => 'الغربية';

  @override
  String get areaNasrCity => 'مدينة نصر';

  @override
  String get areaHeliopolis => 'مصر الجديدة';

  @override
  String get areaMaadi => 'المعادي';

  @override
  String get areaZamalek => 'الزمالك';

  @override
  String get areaDowntown => 'وسط البلد';

  @override
  String get areaDokki => 'الدقي';

  @override
  String get areaAgouza => 'العجوزة';
}
