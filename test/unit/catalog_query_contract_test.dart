import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:taleb/features/auth/data/datasources/catalog_client.dart';

class _RecordedQuery implements Future<List<CatalogRow>> {
  _RecordedQuery(this.table);

  final String table;
  String? columns;
  final List<String> eqFilters = [];
  final List<String> orFilters = [];
  String? orderColumn;
  bool? orderAscending;
  List<CatalogRow> resultToReturn = [];

  _RecordedQuery select([String? cols]) {
    columns = cols;
    return this;
  }

  _RecordedQuery eq(String col, Object val) {
    eqFilters.add('$col=$val');
    return this;
  }

  _RecordedQuery or(String expression) {
    orFilters.add(expression);
    return this;
  }

  _RecordedQuery order(String column, {bool ascending = true}) {
    orderColumn = column;
    orderAscending = ascending;
    return this;
  }

  @override
  Stream<List<CatalogRow>> asStream() => Stream.value(resultToReturn);

  @override
  Future<List<CatalogRow>> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) => Future.value(resultToReturn).catchError(onError, test: test);

  @override
  Future<R> then<R>(
    FutureOr<R> Function(List<CatalogRow> value) onValue, {
    Function? onError,
  }) => Future.value(resultToReturn).then(onValue, onError: onError);

  @override
  Future<List<CatalogRow>> timeout(
    Duration timeLimit, {
    FutureOr<List<CatalogRow>> Function()? onTimeout,
  }) => Future.value(resultToReturn).timeout(timeLimit, onTimeout: onTimeout);

  @override
  Future<List<CatalogRow>> whenComplete(FutureOr<void> Function() action) =>
      Future.value(resultToReturn).whenComplete(action);
}

class _RecordingClient {
  final List<_RecordedQuery> queries = [];
  List<CatalogRow> nextResult = [];

  _RecordedQuery from(String table) {
    final query = _RecordedQuery(table)..resultToReturn = nextResult;
    queries.add(query);
    return query;
  }
}

void main() {
  late _RecordingClient client;
  late SupabaseCatalogClient catalogClient;

  setUp(() {
    client = _RecordingClient();
    catalogClient = SupabaseCatalogClient(client);
  });

  group('SupabaseCatalogClient query contract', () {
    test('select uses default columns and applies filters and ordering', () async {
      client.nextResult = [
        {'id': 1, 'code': 'general', 'name_ar': 'عام', 'name_en': 'General'},
      ];

      final result = await catalogClient.select(
        table: 'education_programs',
        filters: const [CatalogFilter('is_active', true)],
        orderColumn: 'sort_order',
        ascending: true,
      );

      expect(result.length, 1);
      expect(result.first['code'], 'general');
      expect(client.queries.length, 1);
      final q = client.queries.first;
      expect(q.table, 'education_programs');
      expect(q.columns, '*');
      expect(q.eqFilters, ['is_active=true']);
      expect(q.orderColumn, 'sort_order');
      expect(q.orderAscending, isTrue);
    });

    test('select accepts custom columns for PostgREST resource embedding', () async {
      client.nextResult = [
        {
          'id': 10,
          'grade_id': 2,
          'education_subjects': {
            'id': 5,
            'code': 'math',
            'name_ar': 'رياضيات',
            'name_en': 'Math',
            'is_active': true,
          },
        },
      ];

      final result = await catalogClient.select(
        table: 'education_grade_subjects',
        columns: '*,education_subjects!inner(*)',
        filters: const [
          CatalogFilter('grade_id', 2),
          CatalogFilter('education_subjects.is_active', true),
        ],
      );

      expect(result.length, 1);
      expect(client.queries.length, 1);
      final q = client.queries.first;
      expect(q.table, 'education_grade_subjects');
      expect(q.columns, '*,education_subjects!inner(*)');
      expect(q.eqFilters, [
        'grade_id=2',
        'education_subjects.is_active=true',
      ]);
    });

    test('selectTracks generates open-boundary or-filters and sort order', () async {
      client.nextResult = [
        {
          'id': 100,
          'code': 'science',
          'min_grade_number': 2,
          'max_grade_number': 3,
        },
      ];

      final result = await catalogClient.selectTracks(
        table: 'education_tracks',
        filters: const [
          CatalogFilter('program_id', 1),
          CatalogFilter('stage_id', 3),
          CatalogFilter('is_active', true),
        ],
        gradeNumber: 2,
      );

      expect(result.length, 1);
      expect(client.queries.length, 1);
      final q = client.queries.first;
      expect(q.table, 'education_tracks');
      expect(q.eqFilters, [
        'program_id=1',
        'stage_id=3',
        'is_active=true',
      ]);
      expect(q.orFilters, [
        'min_grade_number.is.null,min_grade_number.lte.2',
        'max_grade_number.is.null,max_grade_number.gte.2',
      ]);
      expect(q.orderColumn, 'sort_order');
      expect(q.orderAscending, isTrue);
    });
  });
}
