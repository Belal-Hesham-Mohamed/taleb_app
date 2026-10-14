-- Keep teacher approval limited to trusted administrators, and prevent an
-- administrator who also has a teacher profile from approving that profile.
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
  if decision = 'approved' and target_user_id = auth.uid() then
    raise exception 'Administrators cannot approve their own teacher profile'
      using errcode = '42501';
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
