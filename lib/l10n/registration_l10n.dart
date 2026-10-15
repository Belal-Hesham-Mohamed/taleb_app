import '../../features/auth/domain/entities/education_path.dart';
import '../../features/auth/domain/repositories/registration_repository.dart';
import 'app_localizations.dart';

/// Presentation helpers that map stable domain identifiers to localized
/// labels. Keeping the mapping here keeps display text out of business
/// logic, as the project requires.
extension StudentRegistrationL10n on AppLocalizations {
  /// Returns the localized label for a stable identifier such as a stage or
  /// grade name. Unknown identifiers are returned unchanged so a missing
  /// translation is visible rather than silently blank.
  String lookup(String identifier) => switch (identifier) {
    'primary' => primary,
    'preparatory' => preparatory,
    'secondary' => secondary,
    'general' => general,
    'azhari' => azhari,
    'technical' => technical,
    'international' => international,
    'egyptianBaccalaureate' => egyptianBaccalaureate,
    'generalSecondary' => generalSecondary,
    'primary1' => primary1,
    'primary2' => primary2,
    'primary3' => primary3,
    'primary4' => primary4,
    'primary5' => primary5,
    'primary6' => primary6,
    'preparatory1' => preparatory1,
    'preparatory2' => preparatory2,
    'preparatory3' => preparatory3,
    'secondary1' => secondary1,
    'secondary2' => secondary2,
    'secondary3' => secondary3,
    'medicineAndLifeSciences' => medicineAndLifeSciences,
    'engineeringAndComputerScience' => engineeringAndComputerScience,
    'businessStudies' => businessStudies,
    'artsAndLiterature' => artsAndLiterature,
    'scientific' => scientific,
    'literary' => literary,
    'sciences' => sciences,
    'mathematics' => mathematics,
    'male' => male,
    'female' => female,
    'governorateCairo' => governorateCairo,
    'governorateGiza' => governorateGiza,
    'governorateAlexandria' => governorateAlexandria,
    'governorateDakahlia' => governorateDakahlia,
    'governorateSharqia' => governorateSharqia,
    'governorateQalyubia' => governorateQalyubia,
    'governorateBeheira' => governorateBeheira,
    'governorateGharbia' => governorateGharbia,
    'areaNasrCity' => areaNasrCity,
    'areaHeliopolis' => areaHeliopolis,
    'areaMaadi' => areaMaadi,
    'areaZamalek' => areaZamalek,
    'areaDowntown' => areaDowntown,
    'areaDokki' => areaDokki,
    'areaAgouza' => areaAgouza,
    _ => identifier,
  };

  /// The localized message for a registration failure.
  String registrationMessage(RegistrationFailureKind kind) => switch (kind) {
    RegistrationFailureKind.phoneAlreadyRegistered => registrationPhoneTaken,
    RegistrationFailureKind.network => registrationNetwork,
    RegistrationFailureKind.timeout => registrationTimeout,
    RegistrationFailureKind.profileCreation => registrationProfileFailed,
    RegistrationFailureKind.validation => registrationValidation,
    RegistrationFailureKind.authentication => registrationFailed,
    RegistrationFailureKind.unexpected => registrationFailed,
  };

  /// The localized label for an [EducationalStage].
  String stageLabel(EducationalStage stage) => lookup(stage.name);

  /// The localized label for an [EducationType].
  String educationTypeLabel(EducationType type) => lookup(type.name);

  /// The localized label for an [AcademicSystem].
  String academicSystemLabel(AcademicSystem system) => lookup(system.name);

  /// The localized label for a [StudyGrade].
  String gradeLabel(StudyGrade grade) => lookup(grade.name);

  /// The localized label for an [AcademicTrack].
  String academicTrackLabel(AcademicTrack track) => lookup(track.name);
}
