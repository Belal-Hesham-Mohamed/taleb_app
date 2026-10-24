# NEXT_AGENT_HANDOFF.md

> Continuation record for Taleb Flutter + Supabase. Update after every milestone.

## 1. Current git state (session start)

- **Branch:** `darabaseNew-flowedite` (tracks `origin/darabaseNew-flowedite`)
- **HEAD:** `63705315e383cbd63a47f3c0273b330b24e3ad42`
- **Status:** clean working tree at session start; this file created as the audit record.
- **Vs main:** two commits (`08cbe29` catalog entities/data sources, `6370531` program/grade localization).

## 2. Original starting state (verified)

The branch already contains catalog entities, `CatalogClient` / `SupabaseCatalogDatasource`, Cubit catalog integration, student registration UI, relational IDs on `RegistrationDraft`, localization, and tests. HEAD matches the previous reviewer SHA.

**Verified gaps at audit (read from files, not assumed):**

- Subject load methods exist on repository/datasource/Cubit (`loadGradeSubjects` / `loadTrackSubjects`) but Cubit does not store them in state and `student_registration_page.dart` never renders them.
- `RegistrationDraft.withGovernorate()` clears `areaId` only; legacy `area` text is kept. `personalIssues` treats non-empty legacy `area` as satisfying the area requirement. UI also calls `updateGovernorate` / `updateArea` with codes after selection.
- Single shared `catalogLoading` / `catalogError` plus one `_generation` counter across programs, grades, tracks, and areas. Stale responses `return` without clearing loading. `submitEducation` uses `tracksLoaded: state.tracks.isNotEmpty || state.draft.gradeId != null`, so a pending/failed tracks request can be treated as “no track applies”.
- Query-contract tests exist for nested subject select and nullable track ranges against a fake PostgREST-shaped client; live PostgREST is untested here.
- Signup metadata spreads `draft.toProfilePayload()` including relational IDs. Trigger in `supabase/migrations/202610150001_student_phone_registration.sql` writes those columns from `raw_user_meta_data`.
- `PROJECT_CONTEXT.md` still says `student_profiles` is SELECT-only; live UPDATE policy was reported by the previous reviewer and is **not yet re-verified** this session.
- Local migration files: `202610140001`, `20261014200608`, `202610150001` only. Reported live extra versions `student_profile_relational_write_path` and `secure_normalizer_and_index_relations` are **unverified** until CLI/MCP inspection.

## 3. What this session is doing

Implement remaining functional issues (subjects UI, governorate/area ID validation, per-catalog load states, tests, docs). Do not reset the branch.

## 4. Files created or modified

- `NEXT_AGENT_HANDOFF.md` — this audit (session start). Further files listed as work lands.

## 5. Tests / build actually run

None yet at audit time.

## 6. Database

No database changes this session so far. Live vs local migration drift: pending inspection.

## 7. Known bugs / decisions / blocked

See §2. Optional subjects: **informational display only** (no new persistence table) unless schema later requires selection.

## 8. Next actions (priority)

1. Per-catalog load statuses + independent request tokens in `RegistrationCubit`.
2. Governorate change must clear area ID **and** legacy area text; catalog flow validates IDs only.
3. Render grade/track subjects with required vs choice, loading/error/empty/retry, review summary.
4. Tighten education validation so pending/error ≠ empty tracks.
5. Query-contract tests + optional live read-only catalog check.
6. Reconcile/document live Supabase (policies, trigger, migration history) without rewriting applied history.
7. `dart format`, `flutter analyze`, `flutter test`, `flutter build apk --debug`; commit/push `darabaseNew-flowedite`.

## 9. Ready-to-paste prompt for the next agent

See the bottom of this file; refresh it after each milestone.

## 10. Verified vs assumed vs untested

| Item | Status |
|---|---|
| HEAD SHA `6370531…` | Verified |
| Subjects not in UI | Verified |
| Stale area text bypass | Verified in `personalIssues` + `withGovernorate` |
| Shared catalog loading / tracksLoaded proxy | Verified in Cubit |
| Live UPDATE policy / extra migrations | Untested this session |
| Live PostgREST nested subject query | Untested |
| Trigger writes FKs from metadata | Verified in local SQL file only |

---

## Ready-to-paste continuation prompt

```
Continue Taleb student registration on branch darabaseNew-flowedite.
Repo: Belal-Hesham-Mohamed/taleb_app. Do not restart. Read PROJECT_CONTEXT.md and NEXT_AGENT_HANDOFF.md.
At session start HEAD was 63705315e383cbd63a47f3c0273b330b24e3ad42; treat actual HEAD as authoritative.
Finish: subject UI, governorate/area ID validation, per-catalog loading/error/empty/stale semantics, payload/trigger docs, migration reconciliation, tests and debug APK.
Preserve existing catalog work. No fake live data. No secrets in docs. Commit/push darabaseNew-flowedite only.
```
