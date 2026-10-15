# PROJECT_CONTEXT.md

> Project overview and living context for **Taleb (طالب)** — a Flutter + Supabase
> learning app for students, teachers, and guardians in Egypt.
>
> Rule 26 of the engineering rules: keep this file updated as the project evolves.
> Keep it simple but detailed enough to orient anyone (human or agent) quickly.

---

## 1. What this project is

- **Product:** Taleb — an Arabic-first (RTL) learning platform for the Egyptian
  education system.
- **Users:** Students (primary → secondary), Teachers, Guardians.
- **Stack:** Flutter (stable), Dart 3, Supabase (Auth + Postgres + RLS), `go_router`,
  `flutter_bloc` (Cubit), `get_it`, `dartz` (`Either`), `formz`.
- **Platforms:** Android primary (iOS/desktop folders exist but Android is the target).

---

## 2. Architecture at a glance

```text
lib/
├── main.dart                     # entry, Supabase.initialize, DI bootstrap
├── app/
│   ├── app.dart                  # TalebApp, MaterialApp.router, theme, routes
│   ├── router/
│   │   └── auth_redirect_policy.dart   # role-aware redirect rules (pure fn)
│   ├── pages/
│   │   ├── auth_pages.dart       # welcome, role select, sign-in, reset,
│   │   │                         # legacy email RegistrationPage (teacher/guardian)
│   │   └── student_registration_page.dart  # NEW 6-step student flow
│   └── locale_cubit.dart
├── core/
│   ├── config/app_config.dart    # env config + FAKE_REGISTRATION emulator flag
│   ├── di/injection.dart         # GetIt registrations
│   ├── errors/failure.dart       # FailureKind enum
│   ├── networking/               # DioConfig, ApiConfig, AuthInterceptor, ApiEndpoints
│   └── storage/                  # LocaleRepository, secure storage
├── features/auth/
│   ├── domain/
│   │   ├── entities/             # user_profile, account_role, education_path,
│   │   │                         # registration_draft, catalog  ← NEW
│   │   ├── repositories/         # auth_repository, registration_repository
│   │   │                         # (+ CatalogRepository)        ← NEW
│   │   └── validation/           # phone_number, registration_draft  ← NEW
│   ├── data/
│   │   ├── datasources/          # catalog_client, supabase_catalog_datasource ← NEW
│   │   ├── models/               # profile_model
│   │   └── repositories/         # supabase_auth_repository,
│   │                             # supabase_registration_repository,
│   │                             # fake_registration_repository (emulator only)
│   └── presentation/cubit/       # auth_cubit, registration_cubit
└── l10n/                         # app_en.arb, app_ar.arb + generated delegates

supabase/migrations/              # SQL migrations (see §6)
test/                             # unit + widget tests
assets/                           # student/teacher/parents background PNGs
```

**Layering rule:** presentation → domain → data. UI never calls Supabase directly;
Cubits call repositories; repositories call data sources. There is no `lib/config/`
folder in this project — theme lives in `lib/app/app.dart`.

---

## 3. The two registration flows

### 3.1 Student flow (new, phone-based) — `/register/student`
Six steps, driven by `RegistrationCubit` + `RegistrationDraft`:

1. **Credentials** — phone (Egyptian mobile, normalized to E.164 `+20XXXXXXXXXX`),
   password (≥8 chars), confirm password, optional email. Checks availability via
   the trusted `is_phone_available()` RPC **before** advancing. A failed check never
   advances. Password held in memory only — never persisted or logged.
2. **Personal data** — full name, date of birth, gender, optional student ID,
   guardian phone (required, validated), optional guardian ID, governorate + area
   (loaded from the database catalog).
3. **Academic data** — program → stage → grade → track (only when applicable) →
   optional school. Options come from Supabase; parents reset dependents.
4. **Review** — all data, password masked as "a password has been set", per-section
   edit actions.
5. **Create account** — Supabase Auth signup with metadata; profile rows are created
   by the `handle_new_auth_user()` trigger.
6. **Success** — confirmation + button to home.

### 3.2 Teacher / Guardian flow (legacy, email-based)
`RegistrationPage` in `auth_pages.dart` — email + password + optional school/grade.
**Unchanged on purpose.** A dedicated test asserts it still works.

---

## 4. Supabase schema essentials

Full verified reference: skill `taleb-supabase-schema`. Critical points:

- **Catalog tables:** `education_programs`, `education_stages`, `education_grades`,
  `education_tracks`, `education_subjects`, `education_grade_subjects`,
  `education_track_subjects`, `governorates`, `areas`.
- **`education_stages` has NO `is_active`** — never filter on it. Same for
  `education_grade_subjects` and `education_track_subjects`.
- **`student_profiles` is SELECT-only under RLS** — no client INSERT/UPDATE policy.
  All writes go through the `handle_new_auth_user()` SECURITY DEFINER trigger.
- `student_profiles` holds **both** relational FKs (`education_program_id`,
  `education_grade_id`, `education_track_id`, `area_id`) and legacy text columns
  (`governorate`, `area`, `education_stage`, …). Preserve both.
- **bigint ids may arrive as strings** — always parse with the `asInt` helper
  (`lib/features/auth/domain/entities/catalog.dart`).

---

## 5. Conventions (summary — full rules: skill `flutter-engineering-rules`)

- **Cubit + Dart 3 sealed classes** for state; no full Bloc.
- **`dartz` `Either<Failure, T>`** is the current Result type in `features/auth`
  (the rules' `ApiResult` pattern applies to *new* code; do not mass-migrate).
- **GetIt** DI, registered in `lib/core/di/injection.dart`.
- **Localization:** `lib/l10n/app_en.arb` + `app_ar.arb`, regenerate with
  `flutter gen-l10n`. Never hardcode user-visible strings.
- **Stable ids in the domain, localized labels in the UI** — never store display
  names where an id belongs.
- **Names:** `snake_case.dart` files, `PascalCase` types, `camelCase` members,
  `camelCase` constants (not SCREAMING_CAPS).
- **Imports:** dart → flutter → third-party → project, relative within a feature.

---

## 6. Migrations (in `supabase/migrations/`)

| File | What it does |
|---|---|
| `202610140001_auth_profiles.sql` | profiles / student_profiles / teacher_profiles / guardian_profiles, RLS, `handle_new_auth_user()` trigger, `review_teacher()` admin RPC |
| `20261014200608_prevent_teacher_self_approval.sql` | blocks an admin approving their own teacher profile |
| `202610150001_student_phone_registration.sql` | student profile columns, unique phone index, `normalize_egyptian_mobile()`, `is_phone_available()` RPC, trigger extended to write the education/location FK columns |

**Deploy note:** migration `202610150001` (updated version) must be re-applied to
the live Supabase project so the trigger writes `education_program_id`,
`education_grade_id`, `education_track_id`, `area_id`, `school_name`, `school_type`.

---

## 7. Running and verifying

```bash
flutter pub get
flutter gen-l10n                      # after editing .arb files
dart format <changed files>
flutter analyze
flutter test                          # currently 192 tests, all passing
flutter build apk --debug

# Run against your backend
flutter run --dart-define-from-file=.env.json

# Run on an emulator WITHOUT a backend (UI verification only)
flutter run --dart-define-from-file=.env.emulator.json
```

`.env.json` holds `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` (git-ignored).
`.env.emulator.json` additionally sets `FAKE_REGISTRATION=true`, which swaps in
`FakeRegistrationRepository` (in-memory catalog + simulated phone availability) and
skips Supabase initialization. **It is a debug aid only — never ship with it on.**

Tests use fake repositories and need no backend. Live Supabase behavior (real account
creation, RPC results, trigger writes) is **not covered by unit tests** and must be
verified manually against a test project.

---

## 8. Current status (2026-10-15)

**Done**
- Student registration flow: credentials → personal → academic → review → success,
  fully wired to the database catalog with parent-reset and stale-response guards.
- Phone normalization + availability check + backend-enforced uniqueness.
- Governorate → dependent area selection; education program → stage → grade →
  conditional track → subjects.
- All selections persist as relational ids; legacy text fields preserved.
- Localization for ar/en; RTL verified on device.
- Engineering rules recorded as a skill (`flutter-engineering-rules`).

**Known gaps / next steps**
- No client write path for **editing** a profile after signup (RLS is SELECT-only).
  Needs a scoped UPDATE policy or an RPC — decide, then implement.
- Teacher/guardian flows still use the legacy email registration page.
- Seed data quality unverified: possible duplicate subject codes
  (`arabic` vs `arabic_language` vs `arabic_primary`), incomplete subject mappings,
  unverified track grade ranges. UI degrades safely on empty results.
- Post-registration destination is the generic role home; richer student dashboard
  (attendance, homework, exams, schedule, bus tracking) is not built yet.
