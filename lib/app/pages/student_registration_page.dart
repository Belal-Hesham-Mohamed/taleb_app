import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/catalog.dart';
import '../../features/auth/domain/entities/registration_draft.dart';
import '../../features/auth/domain/repositories/registration_repository.dart';
import '../../features/auth/presentation/cubit/registration_cubit.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/registration_l10n.dart';
import '../locale_cubit.dart';

/// The student registration journey.
///
/// Five steps plus a success screen, matching the reference flow: credentials
/// (phone, password, confirm, optional email), personal data, academic data,
/// review, and account creation. Business rules live in the Cubit and domain
/// layer; this widget only renders state and forwards user input.
///
/// The repository is injected so the page can be tested with a fake; the app
/// passes the GetIt-registered Supabase implementation.
class StudentRegistrationPage extends StatelessWidget {
  const StudentRegistrationPage({required this.repository, super.key});

  final RegistrationRepository repository;

  static const _steps = [
    RegistrationStep.credentials,
    RegistrationStep.personal,
    RegistrationStep.education,
    RegistrationStep.review,
  ];

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => RegistrationCubit(repository)..loadCatalog(),
    child: const _StudentRegistrationView(),
  );
}

class _StudentRegistrationView extends StatelessWidget {
  const _StudentRegistrationView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.studentRegistrationTitle),
        actions: [
          TextButton(
            onPressed: () {
              final current = Localizations.localeOf(context).languageCode;
              context.read<LocaleCubit>().setLanguage(
                current == 'ar' ? 'en' : 'ar',
              );
            },
            child: Text(l10n.language),
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: BlocBuilder<RegistrationCubit, RegistrationState>(
              builder: (context, state) => switch (state.step) {
                RegistrationStep.credentials => const _CredentialsStep(),
                RegistrationStep.personal => const _PersonalStep(),
                RegistrationStep.education => const _EducationStep(),
                RegistrationStep.review => const _ReviewStep(),
                RegistrationStep.success => const _SuccessStep(),
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared step scaffold: progress indicator, title, subtitle, content,
/// navigation buttons, and error surfacing.
class _StepScaffold extends StatelessWidget {
  const _StepScaffold({
    required this.stepIndex,
    required this.title,
    required this.subtitle,
    required this.children,
    required this.onNext,
    required this.nextLabel,
    this.onPrevious,
    this.busy = false,
  });

  final int stepIndex;
  final String title;
  final String subtitle;
  final List<Widget> children;
  final VoidCallback onNext;
  final String nextLabel;
  final VoidCallback? onPrevious;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 16, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (stepIndex + 1) / StudentRegistrationPage._steps.length,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
          const SizedBox(height: 24),
          if (onPrevious != null) ...[
            OutlinedButton(
              onPressed: busy ? null : onPrevious,
              child: Text(l10n.previous),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton(
            onPressed: busy ? null : onNext,
            child: busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(nextLabel),
          ),
        ],
      ),
    );
  }
}

/// Step 1 — Login credentials: phone, password, confirm password, optional
/// email. Validates locally, then checks availability before advancing.
class _CredentialsStep extends StatefulWidget {
  const _CredentialsStep();

  @override
  State<_CredentialsStep> createState() => _CredentialsStepState();
}

class _CredentialsStepState extends State<_CredentialsStep> {
  late final TextEditingController _phone;
  late final TextEditingController _password;
  late final TextEditingController _confirm;
  late final TextEditingController _email;
  var _obscure = true;

  RegistrationCubit get _cubit => context.read<RegistrationCubit>();

  @override
  void initState() {
    super.initState();
    // Restore the draft so navigating back keeps the entered values.
    final draft = _cubit.state.draft;
    _phone = TextEditingController(text: draft.phone);
    _password = TextEditingController(text: draft.password);
    _confirm = TextEditingController(text: draft.confirmPassword);
    _email = TextEditingController(text: draft.email);
  }

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<RegistrationCubit, RegistrationState>(
      builder: (context, state) {
        final issues = state.credentials;
        return _StepScaffold(
          stepIndex: 0,
          title: l10n.stepCredentials,
          subtitle: l10n.studentRegistrationSubtitle,
          busy: state.checkingPhone,
          nextLabel: l10n.next,
          onNext: _cubit.checkPhone,
          onPrevious: () => context.pop(),
          children: [
            if (state.checkingPhone) ...[
              Row(
                children: [
                  const SizedBox.square(
                    dimension: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l10n.checkingPhone)),
                ],
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l10n.phone,
                prefixText: '+20 ',
                prefixIcon: const Icon(Icons.phone_outlined),
                errorText: switch (issues.phone) {
                  'phoneRequired' => l10n.phoneRequired,
                  'phoneInvalid' => l10n.phoneInvalid,
                  _ => null,
                },
              ),
              onChanged: _cubit.updatePhone,
            ),
            if (state.phoneAvailabilityError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  state.phoneAvailabilityError == 'taken'
                      ? l10n.phoneTaken
                      : l10n.phoneCheckFailed,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (state.phoneAvailability.available &&
                state.phoneAvailabilityError == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(l10n.phoneAvailable),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: l10n.password,
                prefixIcon: const Icon(Icons.lock_outline),
                errorText: switch (issues.password) {
                  'passwordShort' => l10n.passwordShort,
                  _ => null,
                },
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  tooltip: _obscure ? l10n.showPassword : l10n.hidePassword,
                  icon: Icon(
                    _obscure ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
              onChanged: _cubit.updatePassword,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirm,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: l10n.confirmPassword,
                prefixIcon: const Icon(Icons.lock_outline),
                errorText: switch (issues.confirmPassword) {
                  'passwordMismatch' => l10n.passwordMismatch,
                  _ => null,
                },
              ),
              onChanged: _cubit.updateConfirmPassword,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: l10n.email,
                prefixIcon: const Icon(Icons.email_outlined),
                errorText: switch (issues.email) {
                  'emailInvalid' => l10n.emailInvalid,
                  _ => null,
                },
              ),
              onChanged: _cubit.updateEmail,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.optionalStep,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      },
    );
  }
}

/// Step 2 — Personal data: name, birth date, gender, optional identity
/// fields, guardian phone, governorate, and area.
class _PersonalStep extends StatefulWidget {
  const _PersonalStep();

  @override
  State<_PersonalStep> createState() => _PersonalStepState();
}

class _PersonalStepState extends State<_PersonalStep> {
  late final TextEditingController _name;
  late final TextEditingController _studentId;
  late final TextEditingController _guardianPhone;
  late final TextEditingController _guardianId;

  RegistrationCubit get _cubit => context.read<RegistrationCubit>();

  @override
  void initState() {
    super.initState();
    // Restore the draft so navigating back keeps the entered values.
    final draft = _cubit.state.draft;
    _name = TextEditingController(text: draft.fullName);
    _studentId = TextEditingController(text: draft.studentId);
    _guardianPhone = TextEditingController(text: draft.guardianPhone);
    _guardianId = TextEditingController(text: draft.guardianId);
  }

  @override
  void dispose() {
    _name.dispose();
    _studentId.dispose();
    _guardianPhone.dispose();
    _guardianId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<RegistrationCubit, RegistrationState>(
      builder: (context, state) {
        final issues = state.personal;
        final draft = state.draft;
        return _StepScaffold(
          stepIndex: 1,
          title: l10n.stepPersonal,
          subtitle: l10n.studentRegistrationSubtitle,
          nextLabel: l10n.next,
          onNext: _cubit.submitPersonal,
          onPrevious: _cubit.goBack,
          children: [
            TextFormField(
              controller: _name,
              decoration: InputDecoration(
                labelText: l10n.fullName,
                prefixIcon: const Icon(Icons.person_outline),
                errorText: switch (issues.fullName) {
                  'fullNameRequired' => l10n.nameRequired,
                  _ => null,
                },
              ),
              onChanged: _cubit.updateFullName,
            ),
            const SizedBox(height: 16),
            _DateOfBirthField(
              value: draft.dateOfBirth,
              error: switch (issues.dateOfBirth) {
                'dateOfBirthRequired' => l10n.dateOfBirthRequired,
                'dateOfBirthInvalid' => l10n.dateOfBirthInvalid,
                _ => null,
              },
              onSelected: _cubit.updateDateOfBirth,
            ),
            const SizedBox(height: 16),
            _GenderSelector(
              error: switch (issues.gender) {
                'genderRequired' => l10n.genderRequired,
                _ => null,
              },
              selected: draft.gender,
              onSelected: _cubit.updateGender,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _studentId,
              decoration: InputDecoration(
                labelText: l10n.studentId,
                prefixIcon: const Icon(Icons.badge_outlined),
              ),
              onChanged: _cubit.updateStudentId,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _guardianPhone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l10n.guardianPhone,
                prefixText: '+20 ',
                prefixIcon: const Icon(Icons.phone_outlined),
                errorText: switch (issues.guardianPhone) {
                  'guardianPhoneRequired' => l10n.guardianPhoneRequired,
                  'guardianPhoneInvalid' => l10n.guardianPhoneInvalid,
                  _ => null,
                },
              ),
              onChanged: _cubit.updateGuardianPhone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _guardianId,
              decoration: InputDecoration(
                labelText: l10n.guardianId,
                prefixIcon: const Icon(Icons.badge_outlined),
              ),
              onChanged: _cubit.updateGuardianId,
            ),
            const SizedBox(height: 16),
            if (state.catalogError) ...[
              _CatalogErrorBanner(
                message: l10n.catalogLoadError,
                onRetry: _cubit.loadCatalog,
              ),
              const SizedBox(height: 12),
            ],
            _GovernorateSelector(
              governorates: state.governorates,
              loading: state.catalogLoading && state.governorates.isEmpty,
              error: switch (issues.governorate) {
                'governorateRequired' => l10n.governorateRequired,
                _ => null,
              },
              selectedId: draft.governorateId,
              onSelected: (gov) {
                _cubit.selectGovernorate(gov.id);
                _cubit.updateGovernorate(gov.code ?? gov.nameEn);
                _cubit.loadAreas();
              },
            ),
            const SizedBox(height: 16),
            _AreaSelector(
              areas: state.areas,
              hasGovernorate: draft.governorateId != null,
              loading: state.catalogLoading &&
                  state.areas.isEmpty &&
                  draft.governorateId != null,
              error: switch (issues.area) {
                'areaRequired' => l10n.areaRequired,
                'areaInvalid' => l10n.areaInvalid,
                _ => null,
              },
              selectedId: draft.areaId,
              onSelected: (area) {
                _cubit.selectArea(area.id);
                _cubit.updateArea(area.code ?? area.nameEn);
              },
            ),
          ],
        );
      },
    );
  }
}

/// A date-of-birth field that opens a date picker and writes an ISO date.
class _DateOfBirthField extends StatelessWidget {
  const _DateOfBirthField({
    required this.value,
    required this.error,
    required this.onSelected,
  });

  final String value;
  final String? error;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final initial = value.isNotEmpty
            ? (DateTime.tryParse(value) ?? DateTime(now.year - 12))
            : DateTime(now.year - 12);
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(now.year - 60),
          lastDate: now,
          helpText: l10n.dateOfBirth,
        );
        if (picked != null) {
          onSelected(
            '${picked.year.toString().padLeft(4, '0')}-'
            '${picked.month.toString().padLeft(2, '0')}-'
            '${picked.day.toString().padLeft(2, '0')}',
          );
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: l10n.dateOfBirth,
          prefixIcon: const Icon(Icons.cake_outlined),
          errorText: error,
        ),
        child: Text(value.isEmpty ? l10n.selectDate : value),
      ),
    );
  }
}

/// A male/female selector rendered as two choice chips.
class _GenderSelector extends StatelessWidget {
  const _GenderSelector({
    required this.error,
    required this.selected,
    required this.onSelected,
  });

  final String? error;
  final Gender? selected;
  final ValueChanged<Gender?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.gender, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: [
            ChoiceChip(
              label: Text(l10n.male),
              selected: selected == Gender.male,
              onSelected: (_) => onSelected(Gender.male),
            ),
            ChoiceChip(
              label: Text(l10n.female),
              selected: selected == Gender.female,
              onSelected: (_) => onSelected(Gender.female),
            ),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

class _GovernorateSelector extends StatelessWidget {
  const _GovernorateSelector({
    required this.governorates,
    required this.loading,
    required this.error,
    required this.selectedId,
    required this.onSelected,
  });

  final List<CatalogOption> governorates;
  final bool loading;
  final String? error;
  final int? selectedId;
  final ValueChanged<CatalogOption> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final validSelection = governorates.any((g) => g.id == selectedId);
    return DropdownButtonFormField<int>(
      initialValue: validSelection ? selectedId : null,
      decoration: InputDecoration(
        labelText: l10n.governorate,
        prefixIcon: const Icon(Icons.location_on_outlined),
        errorText: error,
        suffixIcon: loading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
      ),
      items: [
        for (final gov in governorates)
          DropdownMenuItem(
            value: gov.id,
            child: Text(gov.label(lang)),
          ),
      ],
      onChanged: governorates.isEmpty
          ? null
          : (value) {
              if (value != null) {
                final match = governorates.firstWhere((g) => g.id == value);
                onSelected(match);
              }
            },
    );
  }
}

class _AreaSelector extends StatelessWidget {
  const _AreaSelector({
    required this.areas,
    required this.hasGovernorate,
    required this.loading,
    required this.error,
    required this.selectedId,
    required this.onSelected,
  });

  final List<AreaOption> areas;
  final bool hasGovernorate;
  final bool loading;
  final String? error;
  final int? selectedId;
  final ValueChanged<AreaOption> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final validSelection = areas.any((a) => a.id == selectedId);
    return DropdownButtonFormField<int>(
      initialValue: validSelection ? selectedId : null,
      decoration: InputDecoration(
        labelText: l10n.area,
        prefixIcon: const Icon(Icons.place_outlined),
        errorText: error,
        hintText: !hasGovernorate
            ? null
            : (areas.isEmpty && !loading ? l10n.noOptionsAvailable : null),
        suffixIcon: loading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
      ),
      items: [
        for (final area in areas)
          DropdownMenuItem(
            value: area.id,
            child: Text(area.label(lang)),
          ),
      ],
      onChanged: areas.isEmpty
          ? null
          : (value) {
              if (value != null) {
                final match = areas.firstWhere((a) => a.id == value);
                onSelected(match);
              }
            },
    );
  }
}

class _CatalogErrorBanner extends StatelessWidget {
  const _CatalogErrorBanner({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}

/// Step 3 — Academic data: program, stage, grade, track, optional school.
class _EducationStep extends StatefulWidget {
  const _EducationStep();

  @override
  State<_EducationStep> createState() => _EducationStepState();
}

class _EducationStepState extends State<_EducationStep> {
  late final TextEditingController _school;

  RegistrationCubit get _cubit => context.read<RegistrationCubit>();

  @override
  void initState() {
    super.initState();
    final draft = _cubit.state.draft;
    _school = TextEditingController(
      text: draft.schoolName.isNotEmpty ? draft.schoolName : draft.school,
    );
  }

  @override
  void dispose() {
    _school.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return BlocBuilder<RegistrationCubit, RegistrationState>(
      builder: (context, state) {
        final draft = state.draft;
        final issues = state.education;

        final hasGrades = state.grades.isNotEmpty;
        final hasTracks = state.tracks.isNotEmpty;

        return _StepScaffold(
          stepIndex: 2,
          title: l10n.stepEducation,
          subtitle: l10n.studentRegistrationSubtitle,
          nextLabel: l10n.next,
          onNext: _cubit.submitEducation,
          onPrevious: _cubit.goBack,
          children: [
            if (state.catalogError) ...[
              _CatalogErrorBanner(
                message: l10n.catalogLoadError,
                onRetry: () {
                  if (state.programs.isEmpty || state.stages.isEmpty) {
                    _cubit.loadCatalog();
                  } else if (draft.programId != null &&
                      draft.stageId != null &&
                      state.grades.isEmpty) {
                    _cubit.loadGrades();
                  } else if (draft.gradeId != null && state.tracks.isEmpty) {
                    _cubit.loadTracks();
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
            DropdownButtonFormField<int>(
              initialValue: state.programs.any((p) => p.id == draft.programId)
                  ? draft.programId
                  : null,
              decoration: InputDecoration(
                labelText: l10n.educationProgram,
                prefixIcon: const Icon(Icons.school_outlined),
                errorText: switch (issues.program) {
                  'educationProgramRequired' => l10n.educationProgramRequired,
                  _ => null,
                },
              ),
              items: [
                for (final item in state.programs)
                  DropdownMenuItem(
                    value: item.id,
                    child: Text(item.label(lang)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  _cubit.selectProgram(value);
                  if (draft.stageId != null) {
                    _cubit.loadGrades();
                  }
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: state.stages.any((s) => s.id == draft.stageId)
                  ? draft.stageId
                  : null,
              decoration: InputDecoration(
                labelText: l10n.educationStage,
                prefixIcon: const Icon(Icons.category_outlined),
                errorText: switch (issues.stage) {
                  'educationStageRequired' => l10n.educationStageRequired,
                  _ => null,
                },
              ),
              items: [
                for (final item in state.stages)
                  DropdownMenuItem(
                    value: item.id,
                    child: Text(item.label(lang)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  _cubit.selectStage(value);
                  if (draft.programId != null) {
                    _cubit.loadGrades();
                  }
                }
              },
            ),
            const SizedBox(height: 16),
            if (draft.programId != null && draft.stageId != null) ...[
              DropdownButtonFormField<int>(
                initialValue: state.grades.any((g) => g.id == draft.gradeId)
                    ? draft.gradeId
                    : null,
                decoration: InputDecoration(
                  labelText: l10n.grade,
                  prefixIcon: const Icon(Icons.grade_outlined),
                  errorText: switch (issues.grade) {
                    'gradeRequired' || 'gradeInvalid' => l10n.gradeRequired,
                    _ => null,
                  },
                  hintText: !hasGrades && !state.catalogLoading
                      ? l10n.noOptionsAvailable
                      : null,
                  suffixIcon: state.catalogLoading && !hasGrades
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
                items: [
                  for (final item in state.grades)
                    DropdownMenuItem(
                      value: item.id,
                      child: Text(item.label(lang)),
                    ),
                ],
                onChanged: hasGrades
                    ? (value) {
                        if (value != null) {
                          final grade =
                              state.grades.firstWhere((g) => g.id == value);
                          _cubit.selectGrade(
                            grade.id,
                            gradeNumber: grade.gradeNumber,
                          );
                          _cubit.loadTracks();
                        }
                      }
                    : null,
              ),
              const SizedBox(height: 16),
            ],
            if (hasTracks) ...[
              DropdownButtonFormField<int>(
                initialValue: state.tracks.any((t) => t.id == draft.trackId)
                    ? draft.trackId
                    : null,
                decoration: InputDecoration(
                  labelText: l10n.academicTrack,
                  prefixIcon: const Icon(Icons.tune_outlined),
                  errorText: switch (issues.track) {
                    'trackRequired' => l10n.trackRequired,
                    'trackInvalid' => l10n.trackInvalid,
                    'trackNotAllowed' => l10n.trackNotAllowed,
                    _ => null,
                  },
                ),
                items: [
                  for (final item in state.tracks)
                    DropdownMenuItem(
                      value: item.id,
                      child: Text(item.label(lang)),
                    ),
                ],
                onChanged: (value) => _cubit.selectTrack(value),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _school,
              decoration: InputDecoration(
                labelText: l10n.school,
                prefixIcon: const Icon(Icons.business_outlined),
              ),
              onChanged: (val) {
                _cubit.updateSchoolName(val);
                _cubit.updateSchool(val);
              },
            ),
          ],
        );
      },
    );
  }
}

/// Step 4 — Review: sections for credentials, personal data, and academic
/// data, each with an edit action. The password is shown masked only.
class _ReviewStep extends StatelessWidget {
  const _ReviewStep();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final cubit = context.read<RegistrationCubit>();
    return BlocBuilder<RegistrationCubit, RegistrationState>(
      builder: (context, state) {
        final draft = state.draft;
        return _StepScaffold(
          stepIndex: 3,
          title: l10n.reviewTitle,
          subtitle: l10n.reviewSubtitle,
          busy: state.submitting,
          nextLabel: l10n.createAccountNow,
          onNext: cubit.createAccount,
          onPrevious: cubit.goBack,
          children: [
            if (state.failure != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  l10n.registrationMessage(state.failure!),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            _ReviewSection(
              title: l10n.reviewCredentials,
              onEdit: () => cubit.editStep(RegistrationStep.credentials),
              rows: [
                (l10n.reviewPhone, draft.normalizedPhone ?? draft.phone),
                (l10n.reviewPassword, l10n.passwordSet),
                if (draft.email.trim().isNotEmpty)
                  (l10n.email, draft.email.trim()),
              ],
            ),
            const SizedBox(height: 12),
            _ReviewSection(
              title: l10n.reviewPersonal,
              onEdit: () => cubit.editStep(RegistrationStep.personal),
              rows: [
                (l10n.fullName, draft.fullName),
                (l10n.dateOfBirth, draft.dateOfBirth),
                (
                  l10n.gender,
                  draft.gender == null ? '' : l10n.lookup(draft.gender!.name),
                ),
                if (draft.studentId.trim().isNotEmpty)
                  (l10n.studentId, draft.studentId),
                (l10n.guardianPhone, draft.guardianPhone),
                if (draft.guardianId.trim().isNotEmpty)
                  (l10n.guardianId, draft.guardianId),
                (
                  l10n.governorate,
                  state.governorates
                          .where((g) => g.id == draft.governorateId)
                          .firstOrNull
                          ?.label(lang) ??
                      (draft.governorate.isNotEmpty
                          ? l10n.lookup(draft.governorate)
                          : ''),
                ),
                (
                  l10n.area,
                  state.areas
                          .where((a) => a.id == draft.areaId)
                          .firstOrNull
                          ?.label(lang) ??
                      (draft.area.isNotEmpty
                          ? l10n.lookup(draft.area)
                          : ''),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ReviewSection(
              title: l10n.reviewEducation,
              onEdit: () => cubit.editStep(RegistrationStep.education),
              rows: [
                if (draft.programId != null)
                  (
                    l10n.educationProgram,
                    state.programs
                            .where((p) => p.id == draft.programId)
                            .firstOrNull
                            ?.label(lang) ??
                        '',
                  ),
                (
                  l10n.educationStage,
                  state.stages
                          .where((s) => s.id == draft.stageId)
                          .firstOrNull
                          ?.label(lang) ??
                      (draft.stage != null
                          ? l10n.lookup(draft.stage!.name)
                          : ''),
                ),
                (
                  l10n.grade,
                  state.grades
                          .where((g) => g.id == draft.gradeId)
                          .firstOrNull
                          ?.label(lang) ??
                      (draft.grade != null
                          ? l10n.lookup(draft.grade!.name)
                          : ''),
                ),
                if (draft.trackId != null)
                  (
                    l10n.academicTrack,
                    state.tracks
                            .where((t) => t.id == draft.trackId)
                            .firstOrNull
                            ?.label(lang) ??
                        (draft.track != null
                            ? l10n.lookup(draft.track!.name)
                            : ''),
                  ),
                if (draft.schoolName.trim().isNotEmpty)
                  (l10n.school, draft.schoolName.trim())
                else if (draft.school.trim().isNotEmpty)
                  (l10n.school, draft.school.trim()),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.title,
    required this.rows,
    required this.onEdit,
  });

  final String title;
  final List<(String, String)> rows;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton(onPressed: onEdit, child: Text(l10n.edit)),
              ],
            ),
            const SizedBox(height: 8),
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(flex: 3, child: Text(value)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Step 5 — Success confirmation with a button to the student home.
class _SuccessStep extends StatelessWidget {
  const _SuccessStep();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 96,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.successTitle,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(l10n.successBody, textAlign: TextAlign.center),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => context.go('/'),
              child: Text(l10n.goToHome),
            ),
          ],
        ),
      ),
    );
  }
}
