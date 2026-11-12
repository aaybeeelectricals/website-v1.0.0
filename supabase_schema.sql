-- AAY BEE ELECTRICALS & CONSTRUCTION
-- Run this entire script in Supabase Dashboard > SQL Editor.
-- Create accounts first in Authentication > Users, then assign roles in public.profiles.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  role text not null check (role in ('admin','user')),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

-- Enforce a maximum of one Admin profile.
create unique index if not exists one_admin_only
on public.profiles ((role))
where role = 'admin';

create table if not exists public.sites (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz not null default now()
);

create table if not exists public.designations (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz not null default now()
);

create table if not exists public.employees (
  id uuid primary key default gen_random_uuid(),
  employee_code text not null unique,
  full_name text not null,
  designation text,
  site text,
  phone text,
  gender text,
  date_of_birth date,
  joining_date date,
  employee_type text,
  address text,
  notes text,
  status text not null default 'active' check (status in ('active','terminated')),
  termination_reason text,
  terminated_at timestamptz,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.employee_requests (
  id uuid primary key default gen_random_uuid(),
  employee_code text not null,
  full_name text not null,
  designation text,
  site text,
  phone text,
  gender text,
  date_of_birth date,
  joining_date date,
  employee_type text,
  address text,
  notes text,
  submitted_by uuid not null references auth.users(id),
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  reviewed_by uuid references auth.users(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  details text,
  assigned_to uuid not null references auth.users(id),
  due_date date,
  status text not null default 'pending' check (status in ('pending','completed')),
  completed_at timestamptz,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists public.attendance (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id),
  attendance_date date not null,
  punched_at timestamptz not null default now(),
  status text not null default 'present' check (status in ('present','half_day','absent')),
  admin_note text,
  created_at timestamptz not null default now(),
  unique(user_id, attendance_date)
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid references auth.users(id),
  title text not null,
  message text not null,
  kind text not null default 'general',
  related_id uuid,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create or replace function public.current_role()
returns text
language sql stable security definer
set search_path = public
as $$
  select role from public.profiles
  where id = auth.uid() and active = true
$$;

create or replace function public.is_admin()
returns boolean
language sql stable security definer
set search_path = public
as $$
  select coalesce(public.current_role() = 'admin', false)
$$;

alter table public.profiles enable row level security;
alter table public.sites enable row level security;
alter table public.designations enable row level security;
alter table public.employees enable row level security;
alter table public.employee_requests enable row level security;
alter table public.tasks enable row level security;
alter table public.attendance enable row level security;
alter table public.notifications enable row level security;

-- Profiles: a person can read their own profile; Admin can manage all profiles.
drop policy if exists "profiles read self or admin" on public.profiles;
create policy "profiles read self or admin" on public.profiles
for select to authenticated using (id = auth.uid() or public.is_admin());
drop policy if exists "admin manage profiles" on public.profiles;
create policy "admin manage profiles" on public.profiles
for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Sites/designations are visible to signed-in staff; only Admin manages them.
drop policy if exists "staff read sites" on public.sites;
create policy "staff read sites" on public.sites for select to authenticated using (true);
drop policy if exists "admin manage sites" on public.sites;
create policy "admin manage sites" on public.sites for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "staff read designations" on public.designations;
create policy "staff read designations" on public.designations for select to authenticated using (true);
drop policy if exists "admin manage designations" on public.designations;
create policy "admin manage designations" on public.designations for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Employee directory: all signed-in staff can only view. Admin alone can add/edit/delete.
drop policy if exists "staff read employee directory" on public.employees;
create policy "staff read employee directory" on public.employees for select to authenticated using (true);
drop policy if exists "admin manage employees" on public.employees;
create policy "admin manage employees" on public.employees for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Users can submit requests; only Admin can review/manage requests.
drop policy if exists "user submit employee request" on public.employee_requests;
create policy "user submit employee request" on public.employee_requests
for insert to authenticated with check (submitted_by = auth.uid() and public.current_role() = 'user');
drop policy if exists "user read own requests or admin" on public.employee_requests;
create policy "user read own requests or admin" on public.employee_requests
for select to authenticated using (submitted_by = auth.uid() or public.is_admin());
drop policy if exists "admin review employee requests" on public.employee_requests;
create policy "admin review employee requests" on public.employee_requests
for update to authenticated using (public.is_admin()) with check (public.is_admin());
drop policy if exists "admin delete employee requests" on public.employee_requests;
create policy "admin delete employee requests" on public.employee_requests
for delete to authenticated using (public.is_admin());

-- Admin creates/updates/deletes tasks. User can see own tasks and mark own task completed only.
drop policy if exists "read own tasks or admin" on public.tasks;
create policy "read own tasks or admin" on public.tasks for select to authenticated
using (assigned_to = auth.uid() or public.is_admin());
drop policy if exists "admin create tasks" on public.tasks;
create policy "admin create tasks" on public.tasks for insert to authenticated
with check (public.is_admin() and created_by = auth.uid());
drop policy if exists "admin update tasks" on public.tasks;
create policy "admin update tasks" on public.tasks for update to authenticated
using (public.is_admin()) with check (public.is_admin());
-- Users must not be able to edit task title, details, assignee or due date.
-- They complete a task through the complete_task() function below.
drop policy if exists "user complete own task" on public.tasks;
drop policy if exists "admin delete tasks" on public.tasks;
create policy "admin delete tasks" on public.tasks for delete to authenticated using (public.is_admin());

-- Attendance: User can insert their own punch once and read their own history.
-- Admin can read and update all attendance records.
drop policy if exists "read own attendance or admin" on public.attendance;
create policy "read own attendance or admin" on public.attendance for select to authenticated
using (user_id = auth.uid() or public.is_admin());
drop policy if exists "user punch own attendance" on public.attendance;
create policy "user punch own attendance" on public.attendance for insert to authenticated
with check (user_id = auth.uid() and public.current_role() = 'user' and status = 'present');
drop policy if exists "admin update attendance" on public.attendance;
create policy "admin update attendance" on public.attendance for update to authenticated
using (public.is_admin()) with check (public.is_admin());
drop policy if exists "admin delete attendance" on public.attendance;
create policy "admin delete attendance" on public.attendance for delete to authenticated using (public.is_admin());

-- Notifications: recipient sees own notifications; Admin can create/manage all.
drop policy if exists "read own notifications or admin" on public.notifications;
create policy "read own notifications or admin" on public.notifications for select to authenticated
using (recipient_id = auth.uid() or public.is_admin());
drop policy if exists "admin create notifications" on public.notifications;
create policy "admin create notifications" on public.notifications for insert to authenticated
with check (public.is_admin());
drop policy if exists "user notify admin on own task completion" on public.notifications;
create policy "user notify admin on own task completion" on public.notifications for insert to authenticated
with check (
  recipient_id is null
  and public.current_role() = 'user'
  and kind = 'task_completed'
);
drop policy if exists "update own notification read status" on public.notifications;
create policy "update own notification read status" on public.notifications for update to authenticated
using (recipient_id = auth.uid() or public.is_admin())
with check (recipient_id = auth.uid() or public.is_admin());
drop policy if exists "admin delete notifications" on public.notifications;
create policy "admin delete notifications" on public.notifications for delete to authenticated using (public.is_admin());

-- Important: never put the Supabase service_role key in any HTML/JavaScript file.


-- Secure task completion endpoint. Users can complete only their own assigned task.
-- The Admin is notified in the same database transaction.
create or replace function public.complete_task(p_task_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_task public.tasks%rowtype;
begin
  if public.current_role() <> 'user' then
    raise exception 'Only User accounts can complete tasks from the User workspace';
  end if;

  update public.tasks
     set status = 'completed',
         completed_at = now()
   where id = p_task_id
     and assigned_to = auth.uid()
     and status <> 'completed'
   returning * into v_task;

  if not found then
    raise exception 'Task not found, not assigned to this user, or already completed';
  end if;

  insert into public.notifications(recipient_id, title, message, kind, related_id)
  values (
    null,
    'Task completed',
    (select full_name from public.profiles where id = auth.uid()) ||
      ' completed task: ' || v_task.title,
    'task_completed',
    v_task.id
  );
end;
$$;

grant execute on function public.complete_task(uuid) to authenticated;
