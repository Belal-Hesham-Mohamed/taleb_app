-- Extends the student profile with the registration fields and adds the
-- trusted phone-availability check.
--
-- The phone number is stored once, normalized to E.164 (+20XXXXXXXXXX), and
-- is unique. Uniqueness is enforced by this constraint on the trusted
-- backend, not by the client: the availability check is a convenience that
-- cannot prevent two racing requests, but the constraint and the
-- registration trigger reject a duplicate account creation.

-- 1. Student profile fields collected by the registration flow.
alter table public.student_profiles
  add column if not exists phone text,
  add column if not exists date_of_birth date,
  add column if not exists gender text check (gender in ('male', 'female')),
  add column if not exists student_id text,
  add column if not exists guardian_phone text,
  add column if not exists guardian_id text,
  add column if not exists governorate text,
  add column if not exists area text,
  add column if not exists education_stage text,
  add column if not exists education_type text,
  add column if not exists academic_system text,
  add column if not exists grade text,
  add column if not exists academic_track text;

-- 2. Enforce uniqueness of the normalized phone number.
--    A partial unique index ignores rows without a phone number.
create unique index if not exists student_profiles_phone_unique
  on public.student_profiles (phone)
  where phone is not null;

-- 3. Normalizes Egyptian mobile input to E.164, or returns null when the
--    input is not a valid ten digit mobile number. Mirrors the client rule.
create or replace function public.normalize_egyptian_mobile(input text)
returns text
language plpgsql
immutable
as $$
declare
  digits text;
begin
  if input is null then
    return null;
  end if;
  digits := regexp_replace(input, '[^0-9]', '', 'g');
  if digits like '0020%' then
    digits := substr(digits, 5);
  elsif digits like '20%' and length(digits) = 12 then
    digits := substr(digits, 3);
  elsif digits like '0%' then
    digits := substr(digits, 2);
  end if;
  if length(digits) <> 10 or digits not like '1%' then
    return null;
  end if;
  return '+20' || digits;
end;
$$;

-- 4. The trusted phone-availability check.
--
--    Answers only whether the number is registered. It never returns any
--    other information about an existing account, and it is callable by the
--    anon role because registration happens before authentication.
create or replace function public.is_phone_available(phone_input text)
returns boolean
language sql
security definer
set search_path = ''
as $$
  select not exists (
    select 1
      from public.student_profiles
     where phone = public.normalize_egyptian_mobile(phone_input)
       and phone is not null
  );
$$;

revoke all on function public.is_phone_available(text) from public;
revoke all on function public.is_phone_available(text) from anon, authenticated;
grant execute on function public.is_phone_available(text) to anon, authenticated;

-- 5. The signup trigger now persists the student registration payload.
--    The phone number is normalized and stored once here; a duplicate phone
--    violates the unique index and aborts account creation, which is the
--    trusted enforcement point for the race the client check cannot prevent.
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  requested_role text := new.raw_user_meta_data ->> 'role';
  normalized_name text := nullif(trim(new.raw_user_meta_data ->> 'full_name'), '');
  normalized_phone text := public.normalize_egyptian_mobile(
    new.raw_user_meta_data ->> 'phone'
  );
begin
  if requested_role is null or requested_role not in ('student', 'teacher', 'guardian') then
    raise exception 'Invalid account role';
  end if;
  if normalized_name is null then
    raise exception 'Full name is required';
  end if;

  insert into public.profiles (id, email, full_name, role, teacher_status)
  values (
    new.id,
    coalesce(new.email, ''),
    normalized_name,
    requested_role,
    case when requested_role = 'teacher' then 'pending' else null end
  );

  if requested_role = 'student' then
    if normalized_phone is null then
      raise exception 'A valid student phone number is required';
    end if;
    -- The education and location catalog references are written here, in the
    -- trusted signup trigger, because student_profiles has no client INSERT
    -- or UPDATE policy: RLS grants authenticated users SELECT only. The
    -- legacy text columns are written alongside them so existing rows and
    -- older clients keep working.
    insert into public.student_profiles (
      user_id,
      school,
      grade,
      phone,
      date_of_birth,
      gender,
      student_id,
      guardian_phone,
      guardian_id,
      governorate,
      area,
      education_stage,
      education_type,
      academic_system,
      academic_track,
      education_program_id,
      education_grade_id,
      education_track_id,
      area_id,
      school_name,
      school_type
    )
    values (
      new.id,
      nullif(trim(new.raw_user_meta_data ->> 'school'), ''),
      nullif(trim(new.raw_user_meta_data ->> 'grade'), ''),
      normalized_phone,
      nullif(new.raw_user_meta_data ->> 'date_of_birth', '')::date,
      nullif(new.raw_user_meta_data ->> 'gender', ''),
      nullif(trim(new.raw_user_meta_data ->> 'student_id'), ''),
      public.normalize_egyptian_mobile(new.raw_user_meta_data ->> 'guardian_phone'),
      nullif(trim(new.raw_user_meta_data ->> 'guardian_id'), ''),
      nullif(trim(new.raw_user_meta_data ->> 'governorate'), ''),
      nullif(trim(new.raw_user_meta_data ->> 'area'), ''),
      nullif(new.raw_user_meta_data ->> 'education_stage', ''),
      nullif(new.raw_user_meta_data ->> 'education_type', ''),
      nullif(new.raw_user_meta_data ->> 'academic_system', ''),
      nullif(new.raw_user_meta_data ->> 'academic_track', ''),
      nullif(new.raw_user_meta_data ->> 'education_program_id', '')::bigint,
      nullif(new.raw_user_meta_data ->> 'education_grade_id', '')::bigint,
      nullif(new.raw_user_meta_data ->> 'education_track_id', '')::bigint,
      nullif(new.raw_user_meta_data ->> 'area_id', '')::bigint,
      nullif(trim(new.raw_user_meta_data ->> 'school_name'), ''),
      nullif(trim(new.raw_user_meta_data ->> 'school_type'), '')
    );
  elsif requested_role = 'teacher' then
    insert into public.teacher_profiles (user_id, school)
    values (new.id, nullif(trim(new.raw_user_meta_data ->> 'school'), ''));
  elsif requested_role = 'guardian' then
    insert into public.guardian_profiles (user_id) values (new.id);
  end if;
  return new;
end;
$$;

revoke all on function public.handle_new_auth_user() from public, anon, authenticated;
