import '../../domain/entities/catalog.dart';
import 'catalog_client.dart';

/// Reads the education and location catalog from Supabase.
///
/// Every table, column, and filter here matches the verified schema:
/// - `education_stages` has **no** `is_active` column, so it is never filtered.
/// - `education_grade_subjects` and `education_track_subjects` have **no**
///   `is_active`; subject visibility is decided by the embedded
///   `education_subjects` row, which RLS and the parser enforce.
/// - `min_grade_number` and `max_grade_number` are nullable, so track
///   applicability is an inclusive range with open ends.
/// - Only IDs are ever persisted; localized names come from the catalog rows.
///
/// Queries are executed in the database, not filtered in Dart, so a student
/// can never receive a grade, track, or area from another program, stage,
/// grade, or governorate.
class SupabaseCatalogDatasource {
  SupabaseCatalogDatasource(this._client);

  final CatalogClient _client;

  Future<List<CatalogOption>> loadPrograms() async {
    final rows = await _client.select(
      table: 'education_programs',
      filters: const [CatalogFilter('is_active', true)],
      orderColumn: 'sort_order',
    );
    return rows.map(CatalogOption.fromMap).toList();
  }

  /// Stages are not filtered by active status: the column does not exist.
  Future<List<CatalogOption>> loadStages() async {
    final rows = await _client.select(
      table: 'education_stages',
      orderColumn: 'sort_order',
    );
    return rows.map(CatalogOption.fromMap).toList();
  }

  /// Grades for one program and one stage, ordered by grade number.
  Future<List<GradeOption>> loadGrades({
    required int programId,
    required int stageId,
  }) async {
    final rows = await _client.select(
      table: 'education_grades',
      filters: [
        CatalogFilter('program_id', programId),
        CatalogFilter('stage_id', stageId),
        const CatalogFilter('is_active', true),
      ],
      orderColumn: 'grade_number',
    );
    return rows.map(GradeOption.fromMap).toList();
  }

  /// Tracks for one program, stage, and grade.
  ///
  /// The grade-number range is applied in the database, so a track that
  /// belongs to the program but not to this grade is never returned.
  Future<List<TrackOption>> loadTracks({
    required int programId,
    required int stageId,
    required int gradeNumber,
  }) async {
    final rows = await _client.selectTracks(
      table: 'education_tracks',
      filters: [
        CatalogFilter('program_id', programId),
        CatalogFilter('stage_id', stageId),
        const CatalogFilter('is_active', true),
      ],
      gradeNumber: gradeNumber,
    );
    return rows.map(TrackOption.fromMap).toList();
  }

  /// Subjects common to a grade, through `education_grade_subjects`.
  Future<List<GradeSubjectOption>> loadGradeSubjects({
    required int gradeId,
  }) async {
    final rows = await _client.select(
      table: 'education_grade_subjects',
      filters: [CatalogFilter('grade_id', gradeId)],
      orderColumn: 'sort_order',
    );
    return rows
        .map(GradeSubjectOption.fromMap)
        .whereType<GradeSubjectOption>()
        .toList();
  }

  /// Subjects for one track and one grade, through
  /// `education_track_subjects`.
  Future<List<TrackSubjectOption>> loadTrackSubjects({
    required int trackId,
    required int gradeId,
  }) async {
    final rows = await _client.select(
      table: 'education_track_subjects',
      filters: [
        CatalogFilter('track_id', trackId),
        CatalogFilter('grade_id', gradeId),
      ],
      orderColumn: 'sort_order',
    );
    return rows
        .map(TrackSubjectOption.fromMap)
        .whereType<TrackSubjectOption>()
        .toList();
  }

  Future<List<CatalogOption>> loadGovernorates() async {
    final rows = await _client.select(
      table: 'governorates',
      filters: const [CatalogFilter('is_active', true)],
      orderColumn: 'name_ar',
    );
    return rows.map(CatalogOption.fromMap).toList();
  }

  /// Areas for one governorate. An area from another governorate can never be
  /// returned because the filter runs in the database.
  Future<List<AreaOption>> loadAreas({required int governorateId}) async {
    final rows = await _client.select(
      table: 'areas',
      filters: [
        CatalogFilter('governorate_id', governorateId),
        const CatalogFilter('is_active', true),
      ],
      orderColumn: 'name_ar',
    );
    return rows.map(AreaOption.fromMap).toList();
  }
}
