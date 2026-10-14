# Taleb authentication foundation

This Flutter application starts with an Arabic-first email/password account flow for students, teachers, and guardians. Authentication identity and sessions are managed by Supabase Auth. The app reads a separate `profiles` record for role and account status before routing a signed-in user.

## Architecture

- `features/auth/domain` owns role/profile entities and the repository contract.
- `features/auth/data` implements the contract with Supabase Auth/Postgres.
- `features/auth/presentation` contains the Cubit and registration/sign-in UI.
- `app` composes localized Flutter UI and role-aware `go_router` routes.
- `core/di` registers app dependencies with GetIt. Passwords only pass through memory to Supabase Auth.
- `lib/l10n/*.arb` provides Arabic and English strings; Arabic is the fallback language.
- `supabase/migrations` creates profile tables, signup initialization, RLS policies, and a restricted teacher-review function.

Registration requires a name and email/password. Student grade and school, and teacher school, are optional; guardians need no extra details in this initial scope. Passwords and session credentials are never placed in local registration drafts. Draft persistence is omitted because the current short form does not need recoverable multi-session drafts.

## Supabase setup

1. Create a Supabase project and apply `supabase/migrations/202610140001_auth_profiles.sql` using the Supabase CLI (`supabase db push`) or SQL editor. The migration has not been applied to a remote project by this repository.
2. In Authentication → Providers → Email, enable email/password. For a fast experimental signup flow, disable **Confirm email**; if it remains enabled, the app shows an email-confirmation next step and profile creation still happens in the database signup trigger.
3. Set Site URL and allowed redirect URLs for your deployed app. Configure the email recovery template to use Supabase's recovery link flow. Configure platform deep links and the Supabase redirect URL before enabling password-recovery callbacks in production.
4. For teacher approval, set trusted `app_metadata.role = "admin"` through a server-side/admin mechanism. Never use user-editable `user_metadata` to grant admin status. Admin clients must not run in the Flutter app.

The migration creates profile rows from Auth signup metadata using a database trigger. Row-level security allows each authenticated user to read only their own profile. The client has no profile insert/update policy, so it cannot change account roles or approve a teacher. Teacher approval/rejection is only exposed by `review_teacher`, which checks trusted JWT `app_metadata`; rejection requires a reason. No admin dashboard is included.

## Run locally

Copy `.env.example` to `.env.json` and fill in the project URL and publishable key. Do not put a service-role key in this app or commit real credentials.

```powershell
flutter pub get
flutter run --dart-define-from-file=.env.json
```

If configuration is missing, the app displays a development diagnostic instead of failing during Supabase initialization. Flutter localization code is generated from ARB files during Flutter builds. After changing translations, run `flutter gen-l10n`.

## Verify

```powershell
dart format lib test
flutter analyze
flutter test
```

Tests use fake repositories and do not need a Supabase project. Live auth and database behavior still requires applying the migration to a dedicated test project and configuring platform deep links for recovery links.
