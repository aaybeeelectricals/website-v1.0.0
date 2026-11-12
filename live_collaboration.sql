
-- AAY BEE LIVE COLLABORATION ADD-ON
-- Run this AFTER the original supabase_schema.sql in Supabase SQL Editor.
-- No sample rows are inserted. All new tables start empty.

-- Allow the User to mark tasks as in progress as well as pending/completed.
alter table public.tasks drop constraint if exists tasks_status_check;
alter table public.tasks
  add constraint tasks_status_check
  check (status in ('pending','in_progress','completed'));

-- Every User progress submission is retained so Admin can review changes.
create table if not exists public.task_updates (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.tasks(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  status text not null check (status in ('pending','in_progress','completed')),
  update_note text,
  created_at timestamptz not null default now()
);

-- One-to-one messages between the single Admin and each User.
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references auth.users(id) on delete cascade,
  recipient_id uuid not null references auth.users(id) on delete cascade,
  body text not null check (char_length(trim(body)) between 1 and 4000),
  created_at timestamptz not null default now()
);

create index if not exists task_updates_task_created_idx
  on public.task_updates(task_id, created_at desc);
create index if not exists messages_pair_created_idx
  on public.messages(sender_id, recipient_id, created_at);
create index if not exists messages_recipient_created_idx
  on public.messages(recipient_id, created_at desc);

alter table public.task_updates enable row level security;
alter table public.messages enable row level security;

drop policy if exists "admin and owner read task updates" on public.task_updates;
create policy "admin and owner read task updates"
on public.task_updates for select to authenticated
using (public.is_admin() or user_id = auth.uid());

drop policy if exists "messages visible to participants" on public.messages;
create policy "messages visible to participants"
on public.messages for select to authenticated
using (sender_id = auth.uid() or recipient_id = auth.uid());

drop policy if exists "admin and users send permitted messages" on public.messages;
create policy "admin and users send permitted messages"
on public.messages for insert to authenticated
with check (
  sender_id = auth.uid()
  and (
    (
      public.current_role() = 'admin'
      and exists (
        select 1 from public.profiles p
        where p.id = recipient_id and p.role = 'user' and p.active = true
      )
    )
    or
    (
      public.current_role() = 'user'
      and recipient_id = (
        select p.id from public.profiles p
        where p.role = 'admin' and p.active = true
        limit 1
      )
    )
  )
);

-- Users can find the one active company Admin without being able to list other profiles.
create or replace function public.get_company_admin()
returns table(admin_id uuid, admin_name text)
language sql
stable
security definer
set search_path = public
as $$
  select p.id, p.full_name
  from public.profiles p
  where p.role = 'admin' and p.active = true
  limit 1
$$;

grant execute on function public.get_company_admin() to authenticated;

-- Secure update endpoint. User can update only a task assigned to their own account.
-- Each submission is recorded for Admin review.
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
    raise exception 'Only active User accounts can submit task updates';
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
    raise exception 'Task not found or not assigned to your account';
  end if;

  insert into public.task_updates(task_id, user_id, status, update_note)
  values (p_task_id, auth.uid(), p_status, nullif(trim(p_note), ''));
end;
$$;

grant execute on function public.update_my_task(uuid,text,text) to authenticated;
