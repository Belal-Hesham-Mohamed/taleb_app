create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  full_name text not null,
  role text not null check (role in ('student', 'teacher', 'guardian')),
  teacher_status text check (teacher_status in ('pending', 'approved', 'rejected')),
  rejection_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint teacher_review_fields check (
    (role = 'teacher') or (teacher_status is null and rejection_reason is null)
  ),
  constraint teacher_reason_only_when_rejected check (
    teacher_status = 'rejected' or rejection_reason is null
  )
);

create table if not exists public.student_profiles (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  school text,
  grade text
);

create table if not exists public.teacher_profiles (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  school text,
  created_at timestamptz not null default now()
);

create table if not exists public.guardian_profiles (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now()
);

revoke all on public.profiles, public.student_profiles,
  public.teacher_profiles, public.guardian_profiles from anon, authenticated;
grant select on public.profiles, public.student_profiles,
  public.teacher_profiles, public.guardian_profiles to authenticated;

alter table public.profiles enable row level security;
alter table public.student_profiles enable row level security;
alter table public.teacher_profiles enable row level security;
alter table public.guardian_profiles enable row level security;

drop policy if exists "users read own profile" on public.profiles;
create policy "users read own profile" on public.profiles
  for select to authenticated using ((select auth.uid()) = id);

drop policy if exists "users read own student profile" on public.student_profiles;
create policy "users read own student profile" on public.student_profiles
  for select to authenticated using ((select auth.uid()) = user_id);

drop policy if exists "users read own teacher profile" on public.teacher_profiles;
create policy "users read own teacher profile" on public.teacher_profiles
  for select to authenticated using ((select auth.uid()) = user_id);

drop policy if exists "users read own guardian profile" on public.guardian_profiles;
create policy "users read own guardian profile" on public.guardian_profiles
  for select to authenticated using ((select auth.uid()) = user_id);

-- The only profile write path is the trusted Auth signup trigger. A client
-- cannot change a role, teacher review status, or create another user's row.
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  requested_role text := new.raw_user_meta_data ->> 'role';
  normalized_name text := nullif(trim(new.raw_user_meta_data ->> 'full_name'), '');
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
    insert into public.student_profiles (user_id, school, grade)
    values (
      new.id,
      nullif(trim(new.raw_user_meta_data ->> 'school'), ''),
      nullif(trim(new.raw_user_meta_data ->> 'grade'), '')
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

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_auth_user();

-- Only trusted Supabase Auth app_metadata admins may review teachers. A role
-- in user-editable user_metadata is deliberately not accepted here.
create or replace function public.review_teacher(
  target_user_id uuid,
  decision text,
  reason text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (auth.jwt() -> 'app_metadata' ->> 'role') is distinct from 'admin' then
    raise exception 'Administrator access required' using errcode = '42501';
  end if;
  if decision is null or decision not in ('approved', 'rejected') then
    raise exception 'Invalid teacher decision';
  end if;
  if decision = 'rejected' and nullif(trim(reason), '') is null then
    raise exception 'A rejection reason is required';
  end if;
  update public.profiles
     set teacher_status = decision,
         rejection_reason = case when decision = 'rejected' then trim(reason) else null end,
         updated_at = now()
   where id = target_user_id and role = 'teacher';
  if not found then raise exception 'Teacher profile not found'; end if;
end;
$$;

revoke all on function public.review_teacher(uuid, text, text) from public;
revoke all on function public.review_teacher(uuid, text, text) from anon, authenticated;
grant execute on function public.review_teacher(uuid, text, text) to authenticated;
