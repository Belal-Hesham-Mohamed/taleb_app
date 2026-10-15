/// Parses a PostgREST integer that may arrive as a number or a string.
///
/// `bigint` columns can be returned either way depending on the client, and a
/// silent string/int mix-up would break every foreign-key filter, so every id
/// read from the database goes through this.
int asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.parse(value);
  throw FormatException('Expected an integer, got: $value');
}

/// A catalog option loaded from the Supabase education or location catalog.
///
/// The database is the source of truth: options are never hardcoded in
/// widgets. [id] is the only value persisted; [label] returns the localized
/// display name stored on the catalog row itself.
class CatalogOption {
  const CatalogOption({
    required this.id,

    required this.code,

    required this.nameAr,

    required this.nameEn,
  });

  final int id;

  /// Stable internal code. Informational only: relationships use [id].
  final String? code;
  final String nameAr;
  final String nameEn;

  /// The localized display name for [languageCode] ('ar' or 'en').
  String label(String languageCode) => languageCode == 'ar' ? nameAr : nameEn;

  factory CatalogOption.fromMap(Map<String, dynamic> map) => CatalogOption(
    id: asInt(map['id']),
    code: map['code'] as String?,
    nameAr: map['name_ar'] as String,
    nameEn: map['name_en'] as String,
  );
}

/// A grade inside a program and stage.
///
/// `education_grades` has no `code` column, so [code] is always null here.
class GradeOption extends CatalogOption {
  const GradeOption({
    required super.id,
    required super.nameAr,
    required super.nameEn,
    required this.gradeNumber,
  }) : super(code: null);

  /// The numeric grade used for track applicability, never the display name.
  final int gradeNumber;

  factory GradeOption.fromMap(Map<String, dynamic> map) => GradeOption(
    id: asInt(map['id']),
    nameAr: map['name_ar'] as String,
    nameEn: map['name_en'] as String,
    gradeNumber: asInt(map['grade_number']),
  );
}

/// A specialization inside a program and stage.
///
/// A track applies to a grade when the grade number falls inside
/// [[minGradeNumber], [maxGradeNumber]]. Both boundaries are nullable in the
/// real schema, and a null boundary means "unbounded on that side".
class TrackOption extends CatalogOption {
  const TrackOption({
    required super.id,
    required super.code,
    required super.nameAr,
    required super.nameEn,
    required this.minGradeNumber,
    required this.maxGradeNumber,
  });

  final int? minGradeNumber;
  final int? maxGradeNumber;

  /// Whether this track is offered for [gradeNumber].
  bool appliesToGrade(int gradeNumber) =>
      (minGradeNumber == null || minGradeNumber! <= gradeNumber) &&
      (maxGradeNumber == null || maxGradeNumber! >= gradeNumber);

  factory TrackOption.fromMap(Map<String, dynamic> map) => TrackOption(
    id: asInt(map['id']),
    code: map['code'] as String?,
    nameAr: map['name_ar'] as String,
    nameEn: map['name_en'] as String,
    minGradeNumber: map['min_grade_number'] == null
        ? null
        : asInt(map['min_grade_number']),
    maxGradeNumber: map['max_grade_number'] == null
        ? null
        : asInt(map['max_grade_number']),
  );
}

/// An area inside a governorate.
class AreaOption extends CatalogOption {
  const AreaOption({
    required super.id,
    required super.code,
    required super.nameAr,
    required super.nameEn,
    required this.governorateId,
    required this.areaType,
  });

  final int governorateId;

  /// The area classification stored by the catalog, e.g. city or markaz.
  final String areaType;

  factory AreaOption.fromMap(Map<String, dynamic> map) => AreaOption(
    id: asInt(map['id']),
    code: map['code'] as String?,
    nameAr: map['name_ar'] as String,
    nameEn: map['name_en'] as String,
    governorateId: asInt(map['governorate_id']),
    areaType: map['area_type'] as String,
  );
}

/// A subject from the shared subject catalog.
class SubjectOption extends CatalogOption {
  const SubjectOption({
    required super.id,
    required super.code,
    required super.nameAr,
    required super.nameEn,
  });

  factory SubjectOption.fromMap(Map<String, dynamic> map) => SubjectOption(
    id: asInt(map['id']),
    code: map['code'] as String?,
    nameAr: map['name_ar'] as String,
    nameEn: map['name_en'] as String,
  );
}

/// A subject associated with a grade through `education_grade_subjects`.
class GradeSubjectOption {
  const GradeSubjectOption({
    required this.subject,
    required this.isRequired,
    required this.countsTowardTotal,
  });

  final SubjectOption subject;
  final bool isRequired;
  final bool countsTowardTotal;

  /// Parses one `education_grade_subjects` row with its embedded subject.
  ///
  /// Rows whose embedded subject is missing or inactive are dropped, because
  /// `education_grade_subjects` has no active flag of its own and RLS on
  /// `education_subjects` decides visibility.
  static GradeSubjectOption? fromMap(Map<String, dynamic> map) {
    final subject = _embeddedSubject(map);
    if (subject == null) return null;
    return GradeSubjectOption(
      subject: subject,
      isRequired: map['is_required'] as bool? ?? false,
      countsTowardTotal: map['counts_toward_total'] as bool? ?? false,
    );
  }
}

/// A subject associated with a track and grade through
/// `education_track_subjects`.
class TrackSubjectOption {
  const TrackSubjectOption({
    required this.subject,
    required this.subjectRole,
    required this.choiceGroup,
    required this.isAdvanced,
    required this.isRequired,
    required this.countsTowardTotal,
  });

  final SubjectOption subject;

  /// 'required' or 'choice', as stored by the catalog.
  final String subjectRole;

  /// Groups alternative choices where the curriculum offers a choice.
  final String? choiceGroup;

  final bool isAdvanced;
  final bool isRequired;
  final bool countsTowardTotal;

  /// Whether this subject is one of several alternatives.
  bool get isChoice => subjectRole == 'choice';

  /// Parses one `education_track_subjects` row with its embedded subject.
  static TrackSubjectOption? fromMap(Map<String, dynamic> map) {
    final subject = _embeddedSubject(map);
    if (subject == null) return null;
    return TrackSubjectOption(
      subject: subject,
      subjectRole: map['subject_role'] as String? ?? 'required',
      choiceGroup: map['choice_group'] as String?,
      isAdvanced: map['is_advanced'] as bool? ?? false,
      isRequired: map['is_required'] as bool? ?? false,
      countsTowardTotal: map['counts_toward_total'] as bool? ?? false,
    );
  }
}

/// Reads the embedded `education_subjects` row, honoring its active flag.
SubjectOption? _embeddedSubject(Map<String, dynamic> map) {
  final embedded = map['education_subjects'];
  if (embedded is! Map) return null;
  final row = embedded.cast<String, dynamic>();
  if (row['is_active'] == false) return null;
  return SubjectOption.fromMap(row);
}
