import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/catalog.dart';
import '../../domain/entities/account_role.dart';
import '../../domain/repositories/registration_repository.dart';
import '../datasources/catalog_client.dart';
import '../datasources/supabase_catalog_datasource.dart';

/// Supabase implementation of the student registration contract.
///
/// The trusted `is_phone_available(text)` function answers whether a phone
/// number is registered. It never returns anything else about an existing
/// account. Uniqueness is enforced again by the unique index and the signup
/// trigger on the backend, so a duplicate cannot be created even if two
/// clients pass the availability check at the same time.
///
/// This class implements [RegistrationRepository] and [CatalogRepository]
/// and is only wired for the student flow. Teacher and guardian flows keep
/// using the email-based [AuthRepository] and are untouched by this file.
class SupabaseRegistrationRepository
    implements RegistrationRepository, CatalogRepository {
  SupabaseRegistrationRepository(this._client)
    : _catalog = SupabaseCatalogDatasource(SupabaseCatalogClient(_client));

  final SupabaseClient _client;
  final SupabaseCatalogDatasource _catalog;

  // ---- Catalog ----

  @override
  Future<List<CatalogOption>> loadPrograms() => _catalog.loadPrograms();

  @override
  Future<List<CatalogOption>> loadStages() => _catalog.loadStages();

  @override
  Future<List<GradeOption>> loadGrades({
    required int programId,
    required int stageId,
  }) => _catalog.loadGrades(programId: programId, stageId: stageId);

  @override
  Future<List<TrackOption>> loadTracks({
    required int programId,
    required int stageId,
    required int gradeNumber,
  }) => _catalog.loadTracks(
    programId: programId,
    stageId: stageId,
    gradeNumber: gradeNumber,
  );

  @override
  Future<List<GradeSubjectOption>> loadGradeSubjects({required int gradeId}) =>
      _catalog.loadGradeSubjects(gradeId: gradeId);

  @override
  Future<List<TrackSubjectOption>> loadTrackSubjects({
    required int trackId,
    required int gradeId,
  }) => _catalog.loadTrackSubjects(trackId: trackId, gradeId: gradeId);

  @override
  Future<List<CatalogOption>> loadGovernorates() => _catalog.loadGovernorates();

  @override
  Future<List<AreaOption>> loadAreas({required int governorateId}) =>
      _catalog.loadAreas(governorateId: governorateId);

  // ---- Registration ----

  @override
  Future<PhoneAvailability> checkPhoneAvailability(String phone) async {
    try {
      final result = await _client.rpc<bool>(
        'is_phone_available',
        params: {'phone_input': phone},
      );
      return PhoneAvailability(
        status: result
            ? PhoneAvailabilityStatus.available
            : PhoneAvailabilityStatus.taken,
        phone: phone,
      );
    } catch (error) {
      // A failed check is never availability: the caller must not advance.
      throw RegistrationFailure(_mapAvailabilityError(error), cause: error);
    }
  }

  @override
  Future<void> registerStudent(StudentRegistrationRequest request) async {
    try {
      final response = await _client.auth.signUp(
        // Supabase Auth requires an email identity. The registration phone
        // number is the real account identity and is persisted, normalized
        // and unique in student_profiles by the signup trigger. A synthetic
        // alias keeps the email identity unique per registration without
        // exposing it to the user; email is not used to sign in.
        email: _aliasEmailFor(request.phone),
        password: request.password,
        data: _signupMetadata(request),
      );
      if (response.session == null && response.user == null) {
        throw const RegistrationFailure(RegistrationFailureKind.authentication);
      }
    } on RegistrationFailure {
      rethrow;
    } catch (error) {
      throw RegistrationFailure(_mapSignUpError(error), cause: error);
    }
  }

  /// Builds the signup metadata consumed by the `handle_new_auth_user`
  /// trigger. The password is never included.
  ///
  /// The profile payload keys match the verified `student_profiles` columns,
  /// so the trigger persists the relational catalog ids directly.
  Map<String, dynamic> _signupMetadata(StudentRegistrationRequest request) {
    return {
      'role': AccountRole.student.value,
      'full_name': request.fullName,
      'phone': request.phone,
      ...request.draft.toProfilePayload(),
    };
  }

  /// A deterministic alias address for the required Auth email identity.
  /// It is never shown to the user and never used for sign-in.
  String _aliasEmailFor(String phone) =>
      '${phone.replaceAll('+', '')}@phone.taleb.local';

  RegistrationFailureKind _mapAvailabilityError(Object error) {
    if (error is SocketException) return RegistrationFailureKind.network;
    if (error is AuthException || error is PostgrestException) {
      return RegistrationFailureKind.unexpected;
    }
    if (error.toString().contains('TimeoutException')) {
      return RegistrationFailureKind.timeout;
    }
    return RegistrationFailureKind.unexpected;
  }

  RegistrationFailureKind _mapSignUpError(Object error) {
    if (error is SocketException) return RegistrationFailureKind.network;
    if (error is AuthException) {
      final message = error.message.toLowerCase();
      if (message.contains('already registered') ||
          message.contains('already been registered') ||
          message.contains('duplicate') ||
          message.contains('unique')) {
        return RegistrationFailureKind.phoneAlreadyRegistered;
      }
      if (message.contains('phone')) {
        return RegistrationFailureKind.phoneAlreadyRegistered;
      }
      return RegistrationFailureKind.authentication;
    }
    if (error is PostgrestException) {
      if (error.code == '23505') {
        return RegistrationFailureKind.phoneAlreadyRegistered;
      }
      return RegistrationFailureKind.profileCreation;
    }
    if (error.toString().contains('TimeoutException')) {
      return RegistrationFailureKind.timeout;
    }
    return RegistrationFailureKind.unexpected;
  }
}
