-- AAY BEE: FOUNDER + MANAGER SHARED WORKSPACE
-- Run after the original schema and the earlier live_collaboration.sql.
-- This migration inserts NO sample records and does not create separate databases.

begin;

-- 1. Employee attendance belongs to an employee record.
alter table public.attendance add column if not exists employee_id uuid;
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'attendance_employee_id_fkey'
      and conrelid = 'public.attendance'::regclass
  ) then
    alter table public.attendance
      add constraint attendance_employee_id_fkey
      foreign key (employee_id) references public.employees(id) on delete cascade;
  end if;
end $$;

-- Old attendance uniqueness was per manager account/day. Replace it with
-- one attendance entry per employee/day.
alter table public.attendance drop constraint if exists attendance_user_id_attendance_date_key;
alter table public.attendance drop constraint if exists attendance_employee_id_attendance_date_key;
create unique index if not exists attendance_one_per_employee_per_day
  on public.attendance(employee_id, attendance_date)
  where employee_id is not null;

-- user_id means "manager who recorded the attendance" for the attendance UI.
-- Permit this attribution to become NULL if that manager's Auth account is deleted.
alter table public.attendance alter column user_id drop not null;

-- 2. Generic Manager-to-Founder approval submissions.
create table if not exists public.approvals (
  id uuid primary key default gen_random_uuid(),
  submitted_by uuid not null references auth.users(id) on delete cascade,
  request_type text not null default 'other',
  title text not null,
  details text not null,
  status text not null default 'pending'
    check (status in ('pending','approved','rejected')),
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists approvals_status_created_idx
  on public.approvals(status, created_at desc);
create index if not exists approvals_submitter_created_idx
  on public.approvals(submitted_by, created_at desc);

-- 3. User management: when a Manager Auth account is removed, dependent work
-- assigned to that Manager is removed safely; creator/recorder references do not
-- block account deletion.
alter table public.tasks alter column created_by drop not null;
alter table public.employees alter column created_by drop not null;

alter table public.tasks drop constraint if exists tasks_assigned_to_fkey;
alter table public.tasks add constraint tasks_assigned_to_fkey
  foreign key (assigned_to) references auth.users(id) on delete cascade;

alter table public.tasks drop constraint if exists tasks_created_by_fkey;
alter table public.tasks add constraint tasks_created_by_fkey
  foreign key (created_by) references auth.users(id) on delete set null;

alter table public.employees drop constraint if exists employees_created_by_fkey;
alter table public.employees add constraint employees_created_by_fkey
  foreign key (created_by) references auth.users(id) on delete set null;

alter table public.attendance drop constraint if exists attendance_user_id_fkey;
alter table public.attendance add constraint attendance_user_id_fkey
  foreign key (user_id) references auth.users(id) on delete set null;


-- 3a. Automatically create a Manager profile whenever an Auth user is added.
-- New Supabase Auth users become Managers by default. The Founder profile is
-- assigned explicitly once by setting role='admin' for the Founder UUID.
create or replace function public.handle_new_aaybee_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles(id, full_name, role, active)
  values (
    new.id,
    coalesce(
      nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''),
      nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
      'Manager'
    ),
    'user',
    true
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_aaybee_auth_user_created on auth.users;
create trigger on_aaybee_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_aaybee_auth_user();

-- 4. Employee data is shared. Founder and Managers may add/edit employee records.
alter table public.employees enable row level security;
drop policy if exists "managers insert employee records" on public.employees;
create policy "managers insert employee records"
on public.employees for insert to authenticated
with check (public.current_role() in ('admin','user') and created_by = auth.uid());

drop policy if exists "managers update employee records" on public.employees;
create policy "managers update employee records"
on public.employees for update to authenticated
using (public.current_role() in ('admin','user'))
with check (public.current_role() in ('admin','user'));

-- Existing Admin-all policy remains in force. Existing signed-in read policy remains.

-- 5. Employee attendance is entered by a Manager for a selected employee.
alter table public.attendance enable row level security;
drop policy if exists "managers record employee attendance" on public.attendance;
create policy "managers record employee attendance"
on public.attendance for insert to authenticated
with check (
  public.current_role() in ('admin','user')
  and user_id = auth.uid()
  and employee_id is not null
  and exists (select 1 from public.employees e where e.id = employee_id)
);

drop policy if exists "staff read shared employee attendance" on public.attendance;
create policy "staff read shared employee attendance"
on public.attendance for select to authenticated
using (public.current_role() in ('admin','user'));

-- 6. Founder assigns tasks; each Manager can read only their assigned tasks.
alter table public.tasks enable row level security;
drop policy if exists "read own tasks or admin" on public.tasks;
create policy "read own tasks or admin"
on public.tasks for select to authenticated
using (assigned_to = auth.uid() or public.is_admin());

-- The existing admin create/update/delete policies are retained.
-- The Manager must use update_my_task() to change their own task status.

-- 7. Task progress history: only the assigned Manager submits, Founder reads all.
alter table public.task_updates enable row level security;
drop policy if exists "admin and owner read task updates" on public.task_updates;
create policy "admin and owner read task updates"
on public.task_updates for select to authenticated
using (public.is_admin() or user_id = auth.uid());

-- 8. Approval permissions: Managers submit and read their own; Founder reads/reviews all.
alter table public.approvals enable row level security;
drop policy if exists "manager submit own approvals" on public.approvals;
create policy "manager submit own approvals"
on public.approvals for insert to authenticated
with check (
  submitted_by = auth.uid()
  and public.current_role() = 'user'
  and status = 'pending'
);

drop policy if exists "founder and submitter read approvals" on public.approvals;
create policy "founder and submitter read approvals"
on public.approvals for select to authenticated
using (public.is_admin() or submitted_by = auth.uid());

drop policy if exists "founder review approvals" on public.approvals;
create policy "founder review approvals"
on public.approvals for update to authenticated
using (public.is_admin())
with check (public.is_admin());

-- 9. Single Founder lookup. Returns only the active Founder account.
create or replace function public.get_company_admin()
returns table(admin_id uuid, admin_name text)
language sql stable security definer
set search_path = public
as $$
  select p.id, p.full_name
  from public.profiles p
  where p.role = 'admin' and p.active = true
  limit 1
$$;
grant execute on function public.get_company_admin() to authenticated;

-- 10. Manager task update. Only the Manager assigned to the task can update it.
create or replace function public.update_my_task(
  p_task_id uuid,
  p_status text,
  p_note text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if public.current_role() is distinct from 'user' then
    raise exception 'Only an active Manager account can submit task updates';
  end if;

  if p_status not in ('pending','in_progress','completed') then
    raise exception 'Invalid task status';
  end if;

  update public.tasks
     set status = p_status,
         completed_at = case when p_status = 'completed' then now() else null end
   where id = p_task_id
     and assigned_to = auth.uid();

  if not found then
    raise exception 'Task not found or not assigned to your Manager account';
  end if;

  insert into public.task_updates(task_id, user_id, status, update_note)
  values (p_task_id, auth.uid(), p_status, nullif(trim(p_note), ''));
end;
$$;
grant execute on function public.update_my_task(uuid,text,text) to authenticated;

commit;
