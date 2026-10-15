/// A row returned by a catalog query.
typedef CatalogRow = Map<String, dynamic>;

/// The narrow Supabase surface the catalog data source needs.
///
/// Production passes a Supabase-backed implementation; tests pass a fake.
/// Keeping the seam this small means catalog queries are testable without a
/// live backend, and the data source never reaches past it.
abstract interface class CatalogClient {
  /// Runs a query against [table] and returns raw rows.
  ///
  /// [filters] is applied in order as equality filters; [orderColumn] orders
  /// the result. The implementation is responsible for translating this into
  /// the actual Supabase query.
  Future<List<CatalogRow>> select({
    required String table,
    String columns = '*',
    List<CatalogFilter> filters = const [],
    String? orderColumn,
    bool ascending = true,
  });

  /// Runs a query that also applies the grade-number range to tracks.
  Future<List<CatalogRow>> selectTracks({
    required String table,
    required List<CatalogFilter> filters,
    required int gradeNumber,
  });
}

/// A single equality or range filter on a catalog query.
class CatalogFilter {
  const CatalogFilter(this.column, this.value);

  final String column;
  final Object value;
}

/// Supabase-backed [CatalogClient].
///
/// Every table, column, and filter here matches the verified schema:
/// - `education_stages` has **no** `is_active` column and is never filtered.
/// - `education_grade_subjects` / `education_track_subjects` have **no**
///   `is_active`; subject visibility is decided by the embedded
///   `education_subjects` row.
/// - `min_grade_number` / `max_grade_number` are nullable, and a track is
///   applicable when the grade falls inside the inclusive range.
class SupabaseCatalogClient implements CatalogClient {
  SupabaseCatalogClient(this._client);

  final dynamic _client;

  @override
  Future<List<CatalogRow>> select({
    required String table,
    String columns = '*',
    List<CatalogFilter> filters = const [],
    String? orderColumn,
    bool ascending = true,
  }) async {
    var query = _client.from(table).select(columns);
    for (final filter in filters) {
      query = query.eq(filter.column, filter.value);
    }
    if (orderColumn != null) {
      query = query.order(orderColumn, ascending: ascending);
    }
    final response = await query;
    return (response as List).cast<CatalogRow>();
  }

  @override
  Future<List<CatalogRow>> selectTracks({
    required String table,
    required List<CatalogFilter> filters,
    required int gradeNumber,
  }) async {
    var query = _client.from(table).select();
    for (final filter in filters) {
      query = query.eq(filter.column, filter.value);
    }
    query = query
        .or('min_grade_number.is.null,min_grade_number.lte.$gradeNumber')
        .or('max_grade_number.is.null,max_grade_number.gte.$gradeNumber');
    final response = await query.order('sort_order', ascending: true);
    return (response as List).cast<CatalogRow>();
  }
}
