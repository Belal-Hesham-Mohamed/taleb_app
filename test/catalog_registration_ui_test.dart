import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taleb/app/locale_cubit.dart';
import 'package:taleb/app/pages/student_registration_page.dart';
import 'package:taleb/core/storage/locale_repository.dart';
import 'package:taleb/features/auth/domain/entities/catalog.dart';
import 'package:taleb/features/auth/domain/repositories/registration_repository.dart';
import 'package:taleb/l10n/app_localizations.dart';

class _InMemoryLocaleRepository implements LocaleRepository {
  String? _code;
  @override
  Future<String?> read() async => _code;
  @override
  Future<void> write(String code) async => _code = code;
}

class _TestCatalogRepository
    implements RegistrationRepository, CatalogRepository {
  bool failCatalog = false;
  int catalogLoadCalls = 0;
  StudentRegistrationRequest? capturedRequest;

  @override
  Future<PhoneAvailability> checkPhoneAvailability(String phone) async {
    return const PhoneAvailability(
      status: PhoneAvailabilityStatus.available,
      phone: '+201555555555',
    );
  }

  @override
  Future<void> registerStudent(StudentRegistrationRequest request) async {
    capturedRequest = request;
  }

  @override
  Future<List<CatalogOption>> loadPrograms() async {
    catalogLoadCalls++;
    if (failCatalog) throw Exception('Network error');
    return const [
      CatalogOption(id: 1, code: 'general', nameAr: 'عام', nameEn: 'General'),
    ];
  }

  @override
  Future<List<CatalogOption>> loadStages() async {
    if (failCatalog) throw Exception('Network error');
    return const [
      CatalogOption(
        id: 1,
        code: 'primary',
        nameAr: 'ابتدائي',
        nameEn: 'Primary',
      ),
      CatalogOption(
        id: 3,
        code: 'secondary',
        nameAr: 'ثانوي',
        nameEn: 'Secondary',
      ),
    ];
  }

  @override
  Future<List<CatalogOption>> loadGovernorates() async {
    if (failCatalog) throw Exception('Network error');
    return const [
      CatalogOption(id: 1, code: 'cairo', nameAr: 'القاهرة', nameEn: 'Cairo'),
      CatalogOption(id: 2, code: 'giza', nameAr: 'الجيزة', nameEn: 'Giza'),
    ];
  }

  @override
  Future<List<AreaOption>> loadAreas({required int governorateId}) async {
    if (governorateId == 1) {
      return const [
        AreaOption(
          id: 10,
          governorateId: 1,
          code: 'nasr_city',
          nameAr: 'مدينة نصر',
          nameEn: 'Nasr City',
          areaType: 'city',
        ),
      ];
    } else {
      return const [
        AreaOption(
          id: 20,
          governorateId: 2,
          code: 'dokki',
          nameAr: 'الدقي',
          nameEn: 'Dokki',
          areaType: 'city',
        ),
      ];
    }
  }

  @override
  Future<List<GradeOption>> loadGrades({
    required int programId,
    required int stageId,
  }) async {
    if (stageId == 3) {
      return const [
        GradeOption(
          id: 301,
          nameAr: 'الصف الأول الثانوي',
          nameEn: 'Grade 1 Secondary',
          gradeNumber: 1,
        ),
        GradeOption(
          id: 302,
          nameAr: 'الصف الثاني الثانوي',
          nameEn: 'Grade 2 Secondary',
          gradeNumber: 2,
        ),
      ];
    }
    return const [
      GradeOption(
        id: 101,
        nameAr: 'الصف الأول الابتدائي',
        nameEn: 'Grade 1 Primary',
        gradeNumber: 1,
      ),
    ];
  }

  @override
  Future<List<TrackOption>> loadTracks({
    required int programId,
    required int stageId,
    required int gradeNumber,
  }) async {
    if (stageId == 3 && gradeNumber == 2) {
      return const [
        TrackOption(
          id: 50,
          code: 'scientific',
          nameAr: 'علمي',
          nameEn: 'Scientific',
          minGradeNumber: 2,
          maxGradeNumber: 3,
        ),
        TrackOption(
          id: 51,
          code: 'literary',
          nameAr: 'أدبي',
          nameEn: 'Literary',
          minGradeNumber: 2,
          maxGradeNumber: 3,
        ),
      ];
    }
    return const [];
  }

  @override
  Future<List<GradeSubjectOption>> loadGradeSubjects({
    required int gradeId,
  }) async => const [];

  @override
  Future<List<TrackSubjectOption>> loadTrackSubjects({
    required int trackId,
    required int gradeId,
  }) async => const [];
}

Future<void> _pumpApp(
  WidgetTester tester,
  _TestCatalogRepository repository,
) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: BlocProvider.value(
        value: LocaleCubit(_InMemoryLocaleRepository()),
        child: StudentRegistrationPage(repository: repository),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, Finder finder, String text) async {
  await tester.ensureVisible(finder);
  await tester.enterText(finder, text);
}

Future<void> _pickDropdown(
  WidgetTester tester,
  int index,
  String option,
) async {
  final dropdown = find.byWidgetPredicate(
    (widget) => widget is DropdownButtonFormField,
  );
  final target = dropdown.at(index);
  await tester.ensureVisible(target);
  final arrow = find.descendant(
    of: target,
    matching: find.byIcon(Icons.arrow_drop_down),
  );
  await tester.tap(arrow, warnIfMissed: false);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  final item = find.text(option).last;
  await tester.ensureVisible(item);
  await tester.tap(item, warnIfMissed: false);
  await tester.pumpAndSettle();
}

Future<void> _tapNext(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Next'));
  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('displays catalog error banner on failure and retries successfully', (
    tester,
  ) async {
    final repo = _TestCatalogRepository()..failCatalog = true;
    await _pumpApp(tester, repo);

    // Shows warning banner with retry button
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    // When retry is tapped, if catalog succeeds now, banner disappears
    repo.failCatalog = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
  });

  testWidgets('full catalog-backed student registration journey persists IDs', (
    tester,
  ) async {
    final repo = _TestCatalogRepository();
    await _pumpApp(tester, repo);

    // Step 1: Credentials
    await _enter(tester, find.byType(TextFormField).at(0), '01555555555');
    await _enter(tester, find.byType(TextFormField).at(1), 'password123');
    await _enter(tester, find.byType(TextFormField).at(2), 'password123');
    await _tapNext(tester);

    // Step 2: Personal data with catalog governorate and area
    expect(find.text('Personal data'), findsOneWidget);
    await _enter(tester, find.byType(TextFormField).at(0), 'Youssef Ali');
    await tester.tap(find.text('Select date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Male'));
    await tester.pumpAndSettle();

    // Select Governorate: Cairo -> Area dropdown becomes available with Nasr City
    await _pickDropdown(tester, 0, 'Cairo');
    await _pickDropdown(tester, 1, 'Nasr City');
    await _tapNext(tester);

    // Step 3: Academic data with Program, Stage, Grade, Track
    expect(find.text('Academic data'), findsOneWidget);
    await _pickDropdown(tester, 0, 'General');
    await _pickDropdown(tester, 1, 'Secondary');
    await _pickDropdown(tester, 2, 'Grade 2 Secondary');
    // Track is required for Grade 2 Secondary
    await _pickDropdown(tester, 3, 'Scientific');

    await _enter(tester, find.byType(TextFormField).at(0), 'Al-Amal School');
    await _enter(tester, find.byType(TextFormField).at(1), 'Experimental Language');
    await _tapNext(tester);

    // Step 4: Review Step displays resolved labels
    expect(find.text('Review your data'), findsOneWidget);
    expect(find.text('Cairo'), findsOneWidget);
    expect(find.text('Nasr City'), findsOneWidget);
    expect(find.text('General'), findsOneWidget);
    expect(find.text('Secondary'), findsOneWidget);
    expect(find.text('Grade 2 Secondary'), findsOneWidget);
    expect(find.text('Scientific'), findsOneWidget);
    expect(find.text('Al-Amal School'), findsOneWidget);

    // Create Account
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Your account has been created'), findsOneWidget);
    expect(repo.capturedRequest, isNotNull);
    final req = repo.capturedRequest!;
    expect(req.phone, '+201555555555');
    expect(req.draft.programId, 1);
    expect(req.draft.stageId, 3);
    expect(req.draft.gradeId, 302);
    expect(req.draft.trackId, 50);
    expect(req.draft.governorateId, 1);
    expect(req.draft.areaId, 10);
    expect(req.draft.schoolName, 'Al-Amal School');
    expect(req.draft.schoolType, 'Experimental Language');

    final meta = req.draft.toProfilePayload();
    expect(meta['education_program_id'], 1);
    expect(meta['education_grade_id'], 302);
    expect(meta['education_track_id'], 50);
    expect(meta['area_id'], 10);
    expect(meta['school_name'], 'Al-Amal School');
    expect(meta['school_type'], 'Experimental Language');
  });
}
