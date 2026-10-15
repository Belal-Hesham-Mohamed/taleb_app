/// The educational stage a student studies in.
enum EducationalStage {
  primary,
  preparatory,
  secondary;

  static EducationalStage? parse(String? value) {
    for (final stage in EducationalStage.values) {
      if (stage.name == value) return stage;
    }
    return null;
  }
}

/// The type of education offered at the secondary stage.
enum EducationType {
  general,
  azhari,
  technical,
  international;

  static EducationType? parse(String? value) {
    for (final type in EducationType.values) {
      if (type.name == value) return type;
    }
    return null;
  }
}

/// A configured academic system. Only the general secondary type exposes
/// systems; other secondary types record their type directly.
enum AcademicSystem {
  egyptianBaccalaureate,
  generalSecondary;

  static AcademicSystem? parse(String? value) {
    for (final system in AcademicSystem.values) {
      if (system.name == value) return system;
    }
    return null;
  }
}

/// A grade inside a stage.
enum StudyGrade {
  primary1,
  primary2,
  primary3,
  primary4,
  primary5,
  primary6,
  preparatory1,
  preparatory2,
  preparatory3,
  secondary1,
  secondary2,
  secondary3;

  EducationalStage get stage {
    if (index <= StudyGrade.primary6.index) {
      return EducationalStage.primary;
    }
    if (index <= StudyGrade.preparatory3.index) {
      return EducationalStage.preparatory;
    }
    return EducationalStage.secondary;
  }

  static StudyGrade? parse(String? value) {
    for (final grade in StudyGrade.values) {
      if (grade.name == value) return grade;
    }
    return null;
  }
}

/// A specialization or academic branch inside a secondary path.
enum AcademicTrack {
  medicineAndLifeSciences,
  engineeringAndComputerScience,
  businessStudies,
  artsAndLiterature,
  scientific,
  literary,
  sciences,
  mathematics;

  static AcademicTrack? parse(String? value) {
    for (final track in AcademicTrack.values) {
      if (track.name == value) return track;
    }
    return null;
  }
}

/// Grades offered by a stage, in ascending order.
List<StudyGrade> gradesForStage(EducationalStage stage) =>
    StudyGrade.values.where((grade) => grade.stage == stage).toList();

/// Education types offered by a stage. Only the secondary stage has types.
List<EducationType> educationTypesForStage(EducationalStage stage) =>
    stage == EducationalStage.secondary ? EducationType.values : const [];

/// Academic systems configured for an education type. Only the general
/// secondary type exposes systems in the current configuration.
List<AcademicSystem> academicSystemsForType(EducationType type) =>
    type == EducationType.general
    ? const [
        AcademicSystem.egyptianBaccalaureate,
        AcademicSystem.generalSecondary,
      ]
    : const [];

/// The academic tracks configured for a secondary grade, or `null` when the
/// selected path does not require a specialization.
///
/// These rules are configuration: the mapping is the single place to update
/// for a new academic year. Any grade outside the secondary stage returns
/// `null` because primary and preparatory have no specializations.
List<AcademicTrack>? academicTracksFor(
  AcademicSystem system,
  StudyGrade grade,
) {
  if (grade.stage != EducationalStage.secondary) return null;
  return switch (system) {
    AcademicSystem.egyptianBaccalaureate => switch (grade) {
      StudyGrade.secondary1 => null,
      StudyGrade.secondary2 || StudyGrade.secondary3 => const [
        AcademicTrack.medicineAndLifeSciences,
        AcademicTrack.engineeringAndComputerScience,
        AcademicTrack.businessStudies,
        AcademicTrack.artsAndLiterature,
      ],
      _ => null,
    },
    AcademicSystem.generalSecondary => switch (grade) {
      StudyGrade.secondary1 => null,
      StudyGrade.secondary2 => const [
        AcademicTrack.scientific,
        AcademicTrack.literary,
      ],
      StudyGrade.secondary3 => const [
        AcademicTrack.sciences,
        AcademicTrack.mathematics,
        AcademicTrack.literary,
      ],
      _ => null,
    },
  };
}

/// Whether the selected secondary grade requires a specialization.
bool requiresAcademicTrack(AcademicSystem system, StudyGrade grade) =>
    academicTracksFor(system, grade) != null;

/// Whether [track] is one of the tracks configured for the selected path.
bool isValidAcademicTrack(
  AcademicTrack track,
  AcademicSystem system,
  StudyGrade grade,
) => academicTracksFor(system, grade)?.contains(track) ?? false;
